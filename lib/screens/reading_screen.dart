import 'dart:async';
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

class _ReadingScreenState extends State<ReadingScreen>
    with SingleTickerProviderStateMixin {
  final _api = QuranPageApi();
  final _progressService = ReadingProgressService();
  late PageController _pageController;
  
  // State
  int _currentPageIndex = 0;
  bool _isTranslationMode = false;
  bool _controlsVisible = true;
  bool _isBookmarked = false; // Page bookmark state
  Timer? _hideTimer;

  // Navigation Data (Mock Data for Tabs)
  final List<int> _juzList = List.generate(30, (index) => index + 1);
  // Ideally, you fetch the Surah list from the API or a local JSON asset
  final List<Map<String, dynamic>> _surahListMock = [
    {'number': 1, 'name': 'Al-Fatiha', 'page': 1},
    {'number': 2, 'name': 'Al-Baqarah', 'page': 2},
    {'number': 3, 'name': 'Al-Imran', 'page': 50},
    {'number': 4, 'name': 'An-Nisa', 'page': 77},
    // ... add more or fetch real data
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _startHideTimer();
  }

  Future<void> _loadInitialState() async {
    final savedMode = await _progressService.loadReadingMode();
    
    // Determine Page
    int initialPage = widget.initialPage ?? 1;
    if (widget.initialPage == null) {
      final savedPage = await _progressService.loadLastReadPage();
      if (savedPage != null) initialPage = savedPage;
    }

    // Check Bookmark
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_pages') ?? [];
    final isBookmarked = bookmarks.contains(initialPage.toString());

    setState(() {
      _isTranslationMode = savedMode;
      _currentPageIndex = initialPage - 1; // 0-based
      _isBookmarked = isBookmarked;
      _pageController = PageController(initialPage: _currentPageIndex);
    });
  }

  void _onPageChanged(int index) async {
    final pageNum = index + 1;
    
    // Check bookmark
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_pages') ?? [];
    
    setState(() {
      _currentPageIndex = index;
      _isBookmarked = bookmarks.contains(pageNum.toString());
    });

    _progressService.saveLastReadPage(pageNum);
  }

  Future<void> _togglePageBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_pages') ?? [];
    final pageStr = (_currentPageIndex + 1).toString();

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
    _startHideTimer(); // Reset timer on interaction
  }

  void _showNavigationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _NavigationSheet(
        surahList: _surahListMock,
        juzList: _juzList,
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
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // 1. The Quran Pager (RTL)
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
                        );
                      },
                    );
                  },
                ),
              ),

              // 2. Animated Controls Overlay
              AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _FloatingCircleButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                              Row(
                                children: [
                                  _FloatingCircleButton(
                                    icon: Icons.grid_view_rounded, // Nav Icon
                                    onTap: _showNavigationDialog,
                                  ),
                                  const SizedBox(width: 12),
                                  _FloatingCircleButton(
                                    icon: _isBookmarked 
                                        ? Icons.bookmark_rounded 
                                        : Icons.bookmark_border_rounded,
                                    color: _isBookmarked 
                                        ? AppColors.gold 
                                        : AppColors.primaryText,
                                    onTap: _togglePageBookmark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Bottom Bar (Mode Toggle)
                          _ModeToggleButton(
                            isTranslationMode: _isTranslationMode,
                            onToggle: () {
                                setState(() {
                                  _isTranslationMode = !_isTranslationMode;
                                });
                                _startHideTimer();
                            },
                          ),
                        ],
                      ),
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
    final firstSurah = pageData.surahs.first;
    // Check if page starts with a new Surah (Ayah 1)
    final isNewSurah = pageData.ayahs.first.numberInSurah == 1;

    return SafeArea(
      child: Center(
        // FittedBox forces the content to scale down to fit the screen
        // "One Glance" experience
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            // Constrain width to phone size so text wraps correctly before scaling
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isNewSurah) ...[
                  _SurahHeader(surahName: firstSurah.name),
                  const SizedBox(height: 12),
                  if (firstSurah.number != 9)
                    const Text(
                      'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'UthmanicHafs',
                        fontSize: 24,
                        color: AppColors.primaryText,
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

                // The Text Block
                RichText(
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: 24, // Base size, scaled by FittedBox
                      height: 1.8,
                      color: Colors.black,
                    ),
                    children: pageData.ayahs.map((ayah) {
                      return WidgetSpan(
                        child: GestureDetector(
                          onLongPress: () {
                            // Long Press Logic for Specific Ayah
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Ayah ${ayah.numberInSurah} Selected"),
                                duration: const Duration(seconds: 1),
                                backgroundColor: AppColors.accentGreen,
                              ),
                            );
                          },
                          child: RichText(
                            textDirection: TextDirection.rtl,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'UthmanicHafs',
                                fontSize: 24,
                                height: 1.8,
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(text: ayah.text + " "),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: _AyahEndSymbol(number: ayah.numberInSurah),
                                ),
                                const TextSpan(text: "  "),
                              ],
                            ),
                          ),
                        ),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Symbol
          const Text(
            '\u06DD', 
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 34,
              color: AppColors.gold,
              height: 1.1, // Fixed height to center visual
            ),
          ),
          // The Number (Precise positioning)
          Padding(
            padding: const EdgeInsets.only(top: 2), 
            child: Text(
              _toArabic(number),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 12,
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
          fontSize: 22,
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
          color: AppColors.background.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  final bool isTranslationMode;
  final VoidCallback onToggle;

  const _ModeToggleButton({required this.isTranslationMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentGreen,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTranslationMode ? "Translation" : "Mushaf View",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(
              isTranslationMode ? Icons.translate : Icons.menu_book,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// Navigation Sheet with Tabs
class _NavigationSheet extends StatelessWidget {
  final List<Map<String, dynamic>> surahList;
  final List<int> juzList;
  final Function(int) onPageSelected;

  const _NavigationSheet({
    required this.surahList,
    required this.juzList,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Tab Bar
            TabBar(
              labelColor: AppColors.accentGreen,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.accentGreen,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(text: "Surah"),
                Tab(text: "Juz"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Surah List
                  ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: surahList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final surah = surahList[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold),
                          ),
                          child: Text(
                            "${surah['number']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          surah['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => onPageSelected(surah['page']),
                      );
                    },
                  ),
                  
                  // Juz Grid
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: juzList.length,
                    itemBuilder: (context, index) {
                      final juz = juzList[index];
                      return InkWell(
                        onTap: () {
                          // Calc start page for Juz (Approximate for now)
                          int startPage = (juz - 1) * 20 + 2; 
                          onPageSelected(startPage > 604 ? 604 : startPage);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "$juz",
                            style: const TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}