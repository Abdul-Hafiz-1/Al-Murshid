import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/services/quran_page_api.dart';
import 'package:tarteel/services/reading_progress_service.dart';
import 'package:tarteel/theme/app_theme.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, this.initialPage});

  final int? initialPage;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final _api = QuranPageApi();
  final _progressService = ReadingProgressService();
  late PageController _pageController;

  int _currentPage = 1; // 1-604
  bool _isTranslationMode = false;
  bool _isControlsVisible = true;
  
  // We now track bookmarked AYAHS, not just pages.
  // Format: "page_surah_ayah" -> "4_2_255"
  Set<String> _bookmarkedAyahs = {};

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final savedMode = await _progressService.loadReadingMode();
    int pageToLoad = widget.initialPage ?? 1;

    if (widget.initialPage == null) {
      final savedPage = await _progressService.loadLastReadPage();
      if (savedPage != null) pageToLoad = savedPage;
    }

    // Load bookmarks
    final prefs = await SharedPreferences.getInstance();
    final savedBookmarks = prefs.getStringList('bookmarked_ayahs_list') ?? [];
    // Convert JSON list to Set of IDs for quick lookup
    final bookmarkIds = savedBookmarks.map((e) {
      final map = jsonDecode(e);
      return "${map['page']}_${map['surah']}_${map['ayah']}";
    }).toSet();

    setState(() {
      _isTranslationMode = savedMode;
      _currentPage = pageToLoad;
      _bookmarkedAyahs = bookmarkIds;
      _pageController = PageController(initialPage: pageToLoad - 1);
    });
  }

  void _onPageChanged(int index) {
    final newPage = index + 1;
    setState(() {
      _currentPage = newPage;
    });
    _progressService.saveLastReadPage(newPage);
  }

  Future<void> _toggleAyahBookmark(int page, String surah, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkId = "${page}_${surah}_$ayahNumber";
    
    // Get current list of objects
    List<String> savedStrings = prefs.getStringList('bookmarked_ayahs_list') ?? [];
    
    setState(() {
      if (_bookmarkedAyahs.contains(bookmarkId)) {
        // Remove
        _bookmarkedAyahs.remove(bookmarkId);
        savedStrings.removeWhere((e) {
           final map = jsonDecode(e);
           return "${map['page']}_${map['surah']}_${map['ayah']}" == bookmarkId;
        });
      } else {
        // Add
        _bookmarkedAyahs.add(bookmarkId);
        final newBookmark = jsonEncode({
          'page': page,
          'surah': surah,
          'ayah': ayahNumber,
          'timestamp': DateTime.now().toIso8601String(),
        });
        savedStrings.add(newBookmark);
      }
    });

    await prefs.setStringList('bookmarked_ayahs_list', savedStrings);
  }

  void _showAyahMenu(BuildContext context, String surah, int ayahNumber, String text) {
    final isBookmarked = _bookmarkedAyahs.contains("${_currentPage}_${surah}_$ayahNumber");
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(
              "$surah - Ayah $ayahNumber",
              style: const TextStyle(
                fontFamily: 'UthmanicHafs', 
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                isBookmarked ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded,
                color: AppColors.gold,
              ),
              title: Text(isBookmarked ? 'Remove Bookmark' : 'Bookmark Ayah'),
              onTap: () {
                _toggleAyahBookmark(_currentPage, surah, ayahNumber);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: AppColors.primaryText),
              title: const Text('Copy Text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ayah copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNavigationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _NavigationSheet(
        onPageSelected: (page) {
          Navigator.pop(context);
          _pageController.jumpToPage(page - 1);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: GestureDetector(
          onTap: () => setState(() => _isControlsVisible = !_isControlsVisible),
          child: Stack(
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 604,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return FutureBuilder<QuranPageResponse>(
                      future: _api.getPage(index + 1),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.gold),
                          );
                        }
                        return _MushafPage(
                          pageData: snapshot.data!.data,
                          isTranslationMode: _isTranslationMode,
                          bookmarkedAyahs: _bookmarkedAyahs,
                          onAyahLongPress: (surah, ayah, text) => 
                              _showAyahMenu(context, surah, ayah, text),
                        );
                      },
                    );
                  },
                ),
              ),

              if (_isControlsVisible)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _FloatingCircleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          _FloatingCircleButton(
                            icon: Icons.grid_view_rounded,
                            onTap: _showNavigationDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MushafPage extends StatelessWidget {
  const _MushafPage({
    required this.pageData,
    required this.isTranslationMode,
    required this.onAyahLongPress,
    required this.bookmarkedAyahs,
  });

  final QuranPageData pageData;
  final bool isTranslationMode;
  final Function(String surah, int ayah, String text) onAyahLongPress;
  final Set<String> bookmarkedAyahs;

  @override
  Widget build(BuildContext context) {
    final firstSurah = pageData.surahs.first;
    // Check if this page starts a new Surah (Ayah 1 is present)
    final isNewSurah = pageData.ayahs.any((a) => a.numberInSurah == 1);
    final surahName = firstSurah.name; // Simplified for page view

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.0,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isNewSurah) ...[
                      _SurahHeader(surahName: surahName),
                      const SizedBox(height: 10),
                      if (firstSurah.number != 9)
                        const Text(
                          'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'UthmanicHafs',
                            fontSize: 22,
                            color: AppColors.primaryText,
                            locale: Locale('ar', 'SA'), // FIXED: Correct shaping
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],

                    RichText(
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'UthmanicHafs',
                          fontSize: 22,
                          height: 1.9, // Relaxed height for diacritics
                          color: Colors.black,
                          locale: Locale('ar', 'SA'), // FIXED: Correct shaping
                        ),
                        children: pageData.ayahs.map((ayah) {
                          final isBookmarked = bookmarkedAyahs.contains(
                              "${pageData.number}_${surahName}_${ayah.numberInSurah}");
                          
                          return TextSpan(
                            children: [
                              TextSpan(
                                text: ayah.text + " ",
                                style: isBookmarked 
                                  ? const TextStyle(backgroundColor: Color(0xFFE8F5E9)) // Light green highlight
                                  : null,
                                recognizer: LongPressGestureRecognizer()
                                  ..onLongPress = () => onAyahLongPress(
                                        surahName, 
                                        ayah.numberInSurah, 
                                        ayah.text
                                      ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: _AyahEndSymbol(number: ayah.numberInSurah),
                              ),
                              const TextSpan(text: "  "),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      '${pageData.number}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'UthmanicHafs',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AyahEndSymbol extends StatelessWidget {
  final int number;
  const _AyahEndSymbol({required this.number});

  String _toArabic(int num) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38, // Slightly wider to fit circle
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            '\u06DD',
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 34,
              color: AppColors.gold,
              height: 1.1, // Fixed height prevents clipping
              locale: Locale('ar', 'SA'),
            ),
          ),
          Padding(
             // Fine-tune this padding to move number up/down
            padding: const EdgeInsets.only(top: 2), 
            child: Text(
              _toArabic(number),
              style: const TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final String surahName;
  const _SurahHeader({required this.surahName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E0C6),
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
      child: Text(
        surahName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

class _FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
          ],
        ),
        child: Icon(icon, color: AppColors.primaryText, size: 24),
      ),
    );
  }
}

class _NavigationSheet extends StatelessWidget {
  final Function(int) onPageSelected;
  const _NavigationSheet({required this.onPageSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Jump to Juz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 30,
              itemBuilder: (context, index) {
                final juz = index + 1;
                // Approximate calculation: Juz 1=Pg2, Juz 2=Pg22, etc.
                final startPage = ((juz - 1) * 20) + 2; 
                return InkWell(
                  onTap: () => onPageSelected(startPage > 604 ? 604 : startPage),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text("$juz"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}