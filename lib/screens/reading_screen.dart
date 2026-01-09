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
  bool _isBookmarked = false;
  
  // Cache for surah list (for navigation)
  List<dynamic>? _surahList;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _fetchSurahList();
  }

  Future<void> _loadInitialState() async {
    // 1. Load Mode
    final savedMode = await _progressService.loadReadingMode();
    
    // 2. Load Page
    int pageToLoad = widget.initialPage ?? 1;
    if (widget.initialPage == null) {
      final savedPage = await _progressService.loadLastReadPage();
      if (savedPage != null) pageToLoad = savedPage;
    }

    // 3. Check Bookmark
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedPages = prefs.getStringList('bookmarked_pages') ?? [];
    final isBookmarked = bookmarkedPages.contains(pageToLoad.toString());

    setState(() {
      _isTranslationMode = savedMode;
      _currentPage = pageToLoad;
      _isBookmarked = isBookmarked;
      // Initialize controller. Note: PageView is RTL, so index 0 is visually first?
      // Actually with `reverse: true` or `Directionality(rtl)`, standard index logic applies.
      // We will use standard index = page - 1
      _pageController = PageController(initialPage: pageToLoad - 1);
    });
  }

  Future<void> _fetchSurahList() async {
    // Ideally fetch this from API, for now we can rely on page data or a simple list
    // This is a placeholder for the Navigation Dialog
  }

  void _onPageChanged(int index) async {
    final newPage = index + 1;
    
    // Check bookmark status for new page
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedPages = prefs.getStringList('bookmarked_pages') ?? [];
    
    setState(() {
      _currentPage = newPage;
      _isBookmarked = bookmarkedPages.contains(newPage.toString());
    });

    _progressService.saveLastReadPage(newPage);
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookmarks = prefs.getStringList('bookmarked_pages') ?? [];
    final pageStr = _currentPage.toString();

    setState(() {
      if (bookmarks.contains(pageStr)) {
        bookmarks.remove(pageStr);
        _isBookmarked = false;
      } else {
        bookmarks.add(pageStr);
        _isBookmarked = true;
      }
    });

    await prefs.setStringList('bookmarked_pages', bookmarks);
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
              // 1. The Quran Pager
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
                          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                        }
                        return _MushafPage(
                          pageData: snapshot.data!.data,
                          isTranslationMode: _isTranslationMode,
                        );
                      },
                    );
                  },
                ),
              ),

              // 2. Top Controls (Back, Nav, Bookmark)
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
                          Row(
                            children: [
                              _FloatingCircleButton(
                                icon: Icons.grid_view_rounded, // Navigation Icon
                                onTap: _showNavigationDialog,
                              ),
                              const SizedBox(width: 12),
                              _FloatingCircleButton(
                                icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: _isBookmarked ? AppColors.gold : AppColors.primaryText,
                                onTap: _toggleBookmark,
                              ),
                            ],
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
  const _MushafPage({required this.pageData, required this.isTranslationMode});
  final QuranPageData pageData;
  final bool isTranslationMode;

  @override
  Widget build(BuildContext context) {
    // Logic to identify new Surahs
    final firstSurah = pageData.surahs.first;
    // Simple check: does this page START a surah?
    final isNewSurah = pageData.ayahs.first.numberInSurah == 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // InteractiveViewer allows zooming if text is too small, but starts fitted
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.0,
          child: Center(
            // FittedBox ensures NO SCROLLING, everything fits 
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Container(
                width: MediaQuery.of(context).size.width, // Constrain width
                // We use a Column to layout Surah Headers + Text Block
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isNewSurah) ...[
                      _SurahHeader(surahName: firstSurah.name),
                      const SizedBox(height: 10),
                      if (firstSurah.number != 9) // No Bismillah for Tawbah
                        const Text(
                          'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'UthmanicHafs',
                            fontSize: 22,
                            color: AppColors.primaryText,
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],

                    // The Main Text Block
                    RichText(
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'UthmanicHafs',
                          fontSize: 22, // Base size, FittedBox will scale this down
                          height: 1.8,
                          color: Colors.black,
                        ),
                        children: pageData.ayahs.map((ayah) {
                          return TextSpan(
                            children: [
                              TextSpan(text: ayah.text + " "),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: _AyahEndSymbol(number: ayah.numberInSurah),
                              ),
                              const TextSpan(text: "  "), // Space after ayah
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    // Page Number Footer
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

  // Convert English numbers to Arabic
  String _toArabic(int num) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34, 
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Symbol
          const Text(
            '\u06DD', // U+06DD
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 32, 
              color: AppColors.gold,
              height: 1.0, // Critical to prevent clipping
            ),
          ),
          // The Number
          Padding(
            padding: const EdgeInsets.only(top: 2), // Slight adjustment
            child: Text(
              _toArabic(number),
              style: const TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 12, // Small enough to fit
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
        color: const Color(0xFFE6E0C6), // Decorative header color
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
  final Color color;

  const _FloatingCircleButton({
    required this.icon,
    required this.onTap,
    this.color = AppColors.primaryText,
  });

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
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

// Simple Navigation Sheet
class _NavigationSheet extends StatelessWidget {
  final Function(int) onPageSelected;
  const _NavigationSheet({required this.onPageSelected});

  @override
  Widget build(BuildContext context) {
    // For prototype, we generate 30 Juz. 
    // In production, use a full Surah list JSON.
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
                // Approximate page start for each Juz (Simplified logic)
                final startPage = (juz - 1) * 20 + 2; 
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