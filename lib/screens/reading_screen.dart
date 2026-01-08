import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/services/quran_page_api.dart';
import 'package:tarteel/services/reading_progress_service.dart';
import 'package:tarteel/theme/app_theme.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, this.initialPage});

  /// Initial page number (1-604). If null, loads last saved page or page 1.
  final int? initialPage;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final _api = QuranPageApi();
  final _progressService = ReadingProgressService();
  late PageController _pageController;
  int _currentPageIndex = 0; // 0-based index (0-603)
  bool _isTranslationMode = false;
  bool _isLoadingMode = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    // Load reading mode preference
    final savedMode = await _progressService.loadReadingMode();
    setState(() {
      _isTranslationMode = savedMode;
    });

    // Determine initial page
    int initialPage = widget.initialPage ?? 1;
    if (initialPage == 1) {
      final savedPage = await _progressService.loadLastReadPage();
      if (savedPage != null) {
        initialPage = savedPage;
      }
    }

    // Convert page number (1-604) to index (0-603) for RTL
    // Page 1 (Fatiha) should be at index 0 (rightmost in RTL)
    _currentPageIndex = initialPage - 1;

    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    // Auto-save page number (convert index to page: 0->1, 1->2, etc.)
    final pageNumber = index + 1;
    _progressService.saveLastReadPage(pageNumber);
  }

  Future<void> _toggleMode() async {
    setState(() {
      _isLoadingMode = true;
    });
    final newMode = !_isTranslationMode;
    await _progressService.saveReadingMode(newMode);
    setState(() {
      _isTranslationMode = newMode;
      _isLoadingMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                reverse: false, // Page 1 (index 0) is first, swipe left for next
                onPageChanged: _onPageChanged,
                itemCount: 604,
                itemBuilder: (context, index) {
                  final pageNumber = index + 1; // Convert to 1-604
                  return FutureBuilder<QuranPageResponse>(
                    future: _api.getPage(pageNumber),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGreen,
                          ),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.primaryText,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unable to load page $pageNumber',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final pageData = snapshot.data!.data;
                      return _MushafPage(
                        pageData: pageData,
                        isTranslationMode: _isTranslationMode,
                      );
                    },
                  );
                },
              ),
              // Overlay controls
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _FloatingCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      _FloatingCircleButton(
                        icon: Icons.bookmark_border_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Page ${_currentPageIndex + 1} bookmarked'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Mode toggle button (bottom center)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: _ModeToggleButton(
                    isTranslationMode: _isTranslationMode,
                    isLoading: _isLoadingMode,
                    onToggle: _toggleMode,
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
  });

  final QuranPageData pageData;
  final bool isTranslationMode;

  @override
  Widget build(BuildContext context) {
    final firstSurah = pageData.surahs.first;
    final lastSurah = pageData.surahs.last;
    final isNewSurah = firstSurah.number != lastSurah.number ||
        (pageData.ayahs.isNotEmpty &&
            pageData.ayahs.first.numberInSurah == 1);

    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.gold,
              width: 2.4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.black.withOpacity(0.25),
                  width: 0.9,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full-width surah header
                    if (isNewSurah) ...[
                      _SurahHeader(
                        surah: firstSurah,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      if (firstSurah.number != 9)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'UthmanicHafs',
                              fontSize: 20,
                              height: 1.6,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final ayah in pageData.ayahs) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: _AyahText(
                                  text: ayah.text,
                                  number: ayah.numberInSurah,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            if (isTranslationMode) ...[
                              const SizedBox(height: 8),
                              const Text(
                                '(Translation mode - coming soon)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        '${pageData.number}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
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

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({
    required this.surah,
    required this.isFullWidth,
  });

  final QuranSurahReference surah;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width, no horizontal padding
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold,
          width: 1.8,
        ),
        color: AppColors.accentGreen.withOpacity(0.07),
      ),
      child: Column(
        children: [
          Text(
            surah.englishNameTranslation,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            surah.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahText extends StatelessWidget {
  const _AyahText({required this.text, required this.number});

  final String text;
  final int number;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'UthmanicHafs', // Using UthmanicHafs (Amiri can be added later)
          fontSize: 28,
          height: 1.7,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryText,
        ),
        children: [
          TextSpan(text: '$text '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _AyahEndMarker(number: number),
          ),
        ],
      ),
    );
  }
}

class _AyahEndMarker extends StatelessWidget {
  const _AyahEndMarker({required this.number});

  final int number;

  String _toArabicNumerals(int num) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: The end-of-ayah symbol
            Text(
              '\u06DD', // U+06DD end of ayah symbol
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 30,
                color: AppColors.gold,
              ),
            ),
            // Layer 2: Ayah number overlaid
            Center(
              child: Text(
                _toArabicNumerals(number),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  const _ModeToggleButton({
    required this.isTranslationMode,
    required this.isLoading,
    required this.onToggle,
  });

  final bool isTranslationMode;
  final bool isLoading;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentGreen,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: isLoading ? null : onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                Text(
                  isTranslationMode ? 'Translation' : 'Mushaf',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isTranslationMode
                      ? Icons.menu_book_rounded
                      : Icons.translate_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
