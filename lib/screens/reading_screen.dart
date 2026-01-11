import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // REQUIRED
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
  final _progressService = ReadingProgressService();
  late PageController _pageController;

  int _currentPageIndex = 0;
  bool _isTranslationMode = false;
  bool _areControlsVisible = true;
  Timer? _hideTimer;
  List<String> _bookmarkedAyahs = [];

  // --- DATA ---
  // Ensure you populate this list with all 114 Surahs
  final List<Map<String, dynamic>> _allSurahs = [
    {"number": 1, "name": "Al-Fatiha", "english": "The Opening", "page": 1},
    {"number": 2, "name": "Al-Baqarah", "english": "The Cow", "page": 2},
    {"number": 3, "name": "Ali 'Imran", "english": "Family of Imran", "page": 50},
    {"number": 4, "name": "An-Nisa", "english": "The Women", "page": 77},
    {"number": 18, "name": "Al-Kahf", "english": "The Cave", "page": 293},
    {"number": 36, "name": "Ya-Sin", "english": "Ya Sin", "page": 440},
    {"number": 67, "name": "Al-Mulk", "english": "The Sovereignty", "page": 562},
    {"number": 114, "name": "An-Nas", "english": "Mankind", "page": 604},
    // ... Add the rest here ...
  ];

  final List<int> _juzList = List.generate(30, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _startHideTimer();
    _loadBookmarks();
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
      if (mounted) setState(() => _areControlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _areControlsVisible = !_areControlsVisible);
    if (_areControlsVisible) _startHideTimer();
  }

  Future<void> _loadInitialState() async {
    final savedMode = await _progressService.loadReadingMode();
    int initialPage = widget.initialPage ?? 1;

    if (widget.initialPage == null) {
      final savedPage = await _progressService.loadLastReadPage();
      if (savedPage != null) initialPage = savedPage;
    }

    setState(() {
      _isTranslationMode = savedMode;
      _currentPageIndex = initialPage - 1;
      _pageController = PageController(initialPage: _currentPageIndex);
    });
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('bookmarked_ayahs_list') ?? [];
    setState(() {
      _bookmarkedAyahs = list.map((e) {
        final map = jsonDecode(e);
        return "${map['surah']}:${map['ayah']}";
      }).toList();
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPageIndex = index);
    _progressService.saveLastReadPage(index + 1);
  }

  void _toggleTranslationMode() {
    setState(() => _isTranslationMode = !_isTranslationMode);
    _progressService.saveReadingMode(_isTranslationMode);
    _startHideTimer();
  }

  void _showNavigationSheet() {
    _hideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _NavigationSheet(
        surahList: _allSurahs,
        juzList: _juzList,
        onPageSelected: (page) {
          Navigator.pop(context);
          _pageController.jumpToPage(page - 1);
          _startHideTimer();
        },
      ),
    );
  }

  bool _isBookmarked(String surah, int ayah) {
    return _bookmarkedAyahs.contains("$surah:$ayah");
  }

  Future<void> _toggleBookmark(String surah, int ayahNum) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('bookmarked_ayahs_list') ?? [];
    final key = "$surah:$ayahNum";

    if (_isBookmarked(surah, ayahNum)) {
      savedList.removeWhere((e) {
        final map = jsonDecode(e);
        return map['surah'] == surah && map['ayah'] == ayahNum;
      });
      setState(() {
        _bookmarkedAyahs.remove(key);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Removed Bookmark: $surah $ayahNum"),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } else {
      Map<String, dynamic> newBookmark = {
        'surah': surah,
        'ayah': ayahNum,
        'page': _currentPageIndex + 1,
        'timestamp': DateTime.now().toIso8601String(),
      };
      savedList.add(jsonEncode(newBookmark));
      setState(() {
        _bookmarkedAyahs.add(key);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bookmark Added"),
          backgroundColor: AppColors.accentGreen,
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
    await prefs.setStringList('bookmarked_ayahs_list', savedList);
  }

  void _showAyahMenu(String surah, String text, int ayahNum) {
    _hideTimer?.cancel();
    final isBookmarked = _isBookmarked(surah, ayahNum);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                  color: AppColors.gold,
                ),
                title: Text(isBookmarked ? "Remove Bookmark" : "Bookmark Ayah"),
                onTap: () {
                  Navigator.pop(context);
                  _toggleBookmark(surah, ayahNum);
                  _startHideTimer();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.primaryText),
                title: const Text("Copy Ayah Text"),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ayah copied to clipboard"),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                  _startHideTimer();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
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
        child: Stack(
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 604,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _PageLoader(
                    pageNumber: index + 1,
                    isTranslationMode: _isTranslationMode,
                    onTapContent: _toggleControls,
                    onLongPressAyah: _showAyahMenu,
                  );
                },
              ),
            ),
            AnimatedOpacity(
              opacity: _areControlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_areControlsVisible,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0, left: 0,
                          child: _GlassButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            label: "Back",
                            onTap: () => Navigator.pop(context, true),
                          ),
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: _GlassButton(
                            icon: Icons.grid_view_rounded,
                            label: "Navigate",
                            onTap: _showNavigationSheet,
                          ),
                        ),
                        Positioned(
                          bottom: 20, left: 0, right: 0,
                          child: Center(
                            child: _TranslateToggle(
                              isActive: _isTranslationMode,
                              onTap: _toggleTranslationMode,
                            ),
                          ),
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
    );
  }
}

class _PageLoader extends StatefulWidget {
  final int pageNumber;
  final bool isTranslationMode;
  final VoidCallback onTapContent;
  final Function(String, String, int) onLongPressAyah;

  const _PageLoader({
    required this.pageNumber,
    required this.isTranslationMode,
    required this.onTapContent,
    required this.onLongPressAyah,
  });

  @override
  State<_PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<_PageLoader> with AutomaticKeepAliveClientMixin {
  final _api = QuranPageApi();
  late Future<List<dynamic>> _pageFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _pageFuture = Future.wait([
      _api.getPage(widget.pageNumber),
      if (widget.isTranslationMode) _api.getTranslationPage(widget.pageNumber)
    ]);
  }

  @override
  void didUpdateWidget(covariant _PageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTranslationMode != widget.isTranslationMode) {
      setState(() {
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: _pageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data as List<dynamic>;
        final arabicData = (data[0] as QuranPageResponse).data;
        final translationData = widget.isTranslationMode && data.length > 1
            ? (data[1] as QuranPageResponse).data
            : null;

        return GestureDetector(
          onTap: widget.onTapContent,
          behavior: HitTestBehavior.translucent,
          child: widget.isTranslationMode && translationData != null
              ? _TranslationPageView(arabicData: arabicData, translationData: translationData)
              : _MushafPageView(
                  pageData: arabicData, 
                  onLongPress: widget.onLongPressAyah,
                ),
        );
      },
    );
  }
}

class _MushafPageView extends StatelessWidget {
  final QuranPageData pageData;
  final Function(String, String, int) onLongPress;

  const _MushafPageView({required this.pageData, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    String pageSurahName = "";
    int pageJuz = 0;

    if (pageData.ayahs.isNotEmpty) {
      final firstAyah = pageData.ayahs.first;
      pageSurahName = firstAyah.surahName;
      pageJuz = firstAyah.juz;
    }

    List<Widget> contentWidgets = [];
    if (pageData.ayahs.isEmpty) return const SizedBox();

    String currentSurah = "";
    List<InlineSpan> currentSpans = [];

    // FONT: Using Local UthmanicHafs
    const quranTextStyle = TextStyle(
      fontFamily: 'UthmanicHafs', 
      fontSize: 24, 
      color: Colors.black,
      height: 1.7,
    );

    void flushSpans() {
      if (currentSpans.isNotEmpty) {
        contentWidgets.add(
          RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: quranTextStyle,
              children: List.from(currentSpans),
            ),
          ),
        );
        currentSpans.clear();
      }
    }

    for (var ayah in pageData.ayahs) {
      // 2. SURAH START LOGIC
      if (ayah.numberInSurah == 1) {
        flushSpans();
        
        currentSurah = ayah.surahName;
        contentWidgets.add(_SurahHeader(surahName: currentSurah));
        contentWidgets.add(const SizedBox(height: 8));
        
        // Show Bismillah only if it's the start (and not Tawbah)
        if (ayah.surahNumber != 9) {
           contentWidgets.add(
             const Text(
               "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
               textAlign: TextAlign.center,
               style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 22, color: AppColors.primaryText),
             )
           );
           contentWidgets.add(const SizedBox(height: 12));
        }
      }

      String displayText = ayah.text;
      
      // 3. REMOVE BISMILLAH FROM TEXT OF FIRST AYAH
      if (ayah.numberInSurah == 1 && ayah.surahNumber != 1 && ayah.surahNumber != 9) {
        // Standard Uthmani Bismillah to strip
        const bismillah = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";
        if (displayText.contains(bismillah)) {
           displayText = displayText.replaceFirst(bismillah, "").trim();
        } else if (displayText.startsWith("بِسْمِ")) {
           // Heuristic for slight encoding variations
           displayText = displayText.replaceFirst(RegExp(r'^.*?ٱلرَّحِيمِ\s*'), '');
        }
      }

      currentSpans.add(
        TextSpan(
          text: "$displayText ",
          recognizer: LongPressGestureRecognizer()
            ..onLongPress = () {
              HapticFeedback.mediumImpact();
              onLongPress(currentSurah.isEmpty ? pageSurahName : currentSurah, ayah.text, ayah.numberInSurah);
            },
        ),
      );
      
      currentSpans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _AyahEndSymbol(number: ayah.numberInSurah),
        ),
      );
      currentSpans.add(const TextSpan(text: "  "));
    }
    
    flushSpans();

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PAGE HEADER
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pageSurahName,
                      style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Juz $pageJuz",
                      style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              ...contentWidgets,
              
              const SizedBox(height: 20),
              Text(
                "${pageData.number}", 
                textAlign: TextAlign.center, 
                style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 14, color: Colors.grey)
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslationPageView extends StatelessWidget {
  final QuranPageData arabicData;
  final QuranPageData translationData;

  const _TranslationPageView({required this.arabicData, required this.translationData});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
      itemCount: arabicData.ayahs.length,
      itemBuilder: (context, index) {
        final arabicAyah = arabicData.ayahs[index];
        final englishAyah = translationData.ayahs.length > index ? translationData.ayahs[index] : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  arabicAyah.text,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 22, height: 1.8),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    englishAyah?.text ?? "Loading...",
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.primaryText),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------- WIDGETS ----------------

class _AyahEndSymbol extends StatelessWidget {
  final int number;
  const _AyahEndSymbol({required this.number});

  String _toArabic(int num) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // FIX: Use Amiri (Google Font) ONLY for the circle.
          // This solves the box issue if UthmanicHafs lacks the specific glyph map.
          Text(
            '\u06DD',
            style: GoogleFonts.amiri( // Ensures the symbol renders
              fontSize: 34,
              color: AppColors.gold,
              height: 1.0, 
            ),
          ),
          // FIX: Digits LTR inside the circle
          Padding(
            padding: const EdgeInsets.only(top: 4), 
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                _toArabic(number),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'UthmanicHafs', // Keep numbers consistent
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.0,
                ),
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
        border: Border.symmetric(horizontal: BorderSide(color: AppColors.gold, width: 2)),
      ),
      child: Text(
        surahName,
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ... Keep _GlassButton, _TranslateToggle, _NavigationSheet (No changes needed) ...
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Row(children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }
}

class _TranslateToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _TranslateToggle({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGreen : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, size: 18, color: isActive ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(isActive ? "Translation ON" : "Translate",
                style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _NavigationSheet extends StatefulWidget {
  final List<Map<String, dynamic>> surahList;
  final List<int> juzList;
  final Function(int) onPageSelected;

  const _NavigationSheet({required this.surahList, required this.juzList, required this.onPageSelected});

  @override
  State<_NavigationSheet> createState() => _NavigationSheetState();
}

class _NavigationSheetState extends State<_NavigationSheet> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredSurahs = widget.surahList.where((s) {
      final name = s['name'].toString().toLowerCase();
      final english = s['english'].toString().toLowerCase();
      final number = s['number'].toString();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || english.contains(q) || number.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: DefaultTabController(
        length: 2,
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Surah (Name or Number)',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const TabBar(tabs: [Tab(text: "Surah"), Tab(text: "Juz")], labelColor: AppColors.accentGreen),
          Expanded(
            child: TabBarView(children: [
              ListView.builder(
                itemCount: filteredSurahs.length,
                itemBuilder: (ctx, i) {
                  final s = filteredSurahs[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceLight,
                      child: Text("${s['number']}", style: const TextStyle(fontSize: 12, color: AppColors.primaryText)),
                    ),
                    title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(s['english']),
                    trailing: Text("Page ${s['page']}", style: const TextStyle(color: Colors.grey)),
                    onTap: () => widget.onPageSelected(s['page']),
                  );
                },
              ),
              GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: widget.juzList.length,
                itemBuilder: (ctx, i) => InkWell(
                  onTap: () => widget.onPageSelected((widget.juzList[i] - 1) * 20 + 2),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.gold), borderRadius: BorderRadius.circular(8)),
                    child: Text("${widget.juzList[i]}"),
                  ),
                ),
              ),
            ]),
          )
        ]),
      ),
    );
  }
}