import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:quran/quran.dart' as quran;

// 👇 IMPORT YOUR DATA FILE HERE
import 'package:tarteel/data/quran_data.dart';
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
  final _api = QuranPageApi();
  
  // --- CONTROLLERS ---
  late PageController _mushafController; 
  late PageController _translationController;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // --- STATE ---
  // Page Index: 0 = Page 1, 1 = Page 2...
  int _currentPageIndex = 0; 
  // Surah Index: 0 = Fatiha, 1 = Baqarah...
  int _currentSurahIndex = 0; 
  
  // --- SYNC VARIABLES ---
  int _targetAyahToScroll = 1; 
  int _currentVisibleAyahInTranslation = 1; 
  
  bool _isTranslationMode = false;
  bool _areControlsVisible = true;
  Timer? _hideTimer;
  List<String> _bookmarkedAyahs = [];

  // --- AUDIO STATE ---
  PlayerState _playerState = PlayerState.stopped;
  bool _isAudioLoading = false;
  int? _playingSurah;
  int? _playingAyah;
  
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  final List<int> _juzList = List.generate(30, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _startHideTimer();
    _loadBookmarks();
    _setupAudio();
  }

  Future<void> _setupAudio() async {
    final audioContext = AudioContext(
      iOS: AudioContextIOS(category: AVAudioSessionCategory.playback, options: const {}),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    );
    await AudioPlayer.global.setAudioContext(audioContext);

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      _playNextAyah();
    });
  }

  @override
  void dispose() {
    try { _mushafController.dispose(); } catch(e) {}
    try { _translationController.dispose(); } catch(e) {}
    _hideTimer?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _playerState != PlayerState.playing) {
        setState(() => _areControlsVisible = false);
      }
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

    _currentPageIndex = initialPage - 1;
    _isTranslationMode = savedMode;

    if (_isTranslationMode) {
      // ✅ FIX: Convert page number to surah number and find the starting ayah
      int surahNum = QuranData.getSurahForPage(initialPage);
      
      // Get the starting ayah for this page
      var pageData = quran.getPageData(initialPage);
      int startAyah = pageData[0]['start'];

      _currentSurahIndex = surahNum - 1;  // Convert to 0-indexed for PageView
      _targetAyahToScroll = startAyah;
      
      _translationController = PageController(initialPage: _currentSurahIndex);
    } else {
      _mushafController = PageController(initialPage: _currentPageIndex);
    }
    
    setState(() {});
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
    if (_isTranslationMode) {
      // In translation mode: index is the Surah index (0-based)
      setState(() => _currentSurahIndex = index);
      
      // ✅ FIX: Convert surah number to page number for saving progress
      int surahNum = index + 1;
      int pageForThisSurah = quran.getPageNumber(surahNum, 1);
      _progressService.saveLastReadPage(pageForThisSurah);
    } else {
      // In Mushaf mode: index is the Page index (0-based)
      setState(() => _currentPageIndex = index);
      _progressService.saveLastReadPage(index + 1);
    }
  }

  void _toggleTranslationMode() {
    setState(() {
      if (_isTranslationMode) {
        // --- TRANSLATION -> MUSHAF ---
        // 1. Get the current surah and visible ayah in translation
        int currentSurah = _currentSurahIndex + 1;
        int currentAyah = _currentVisibleAyahInTranslation;
        
        // 2. Calculate the page number for this surah:ayah
        int targetPage = quran.getPageNumber(currentSurah, currentAyah);
        
        // 3. Switch to Mushaf at the calculated page
        _currentPageIndex = targetPage - 1;
        _mushafController = PageController(initialPage: _currentPageIndex);
        _isTranslationMode = false;
        
      } else {
        // --- MUSHAF -> TRANSLATION ---
        // 1. Get the current page number (1-indexed)
        int currentPage = _currentPageIndex + 1;
        
        // 2. Find which surah is at the top of this page
        int surahNum = QuranData.getSurahForPage(currentPage);
        
        // 3. Find the starting ayah of this page
        var pageData = quran.getPageData(currentPage);
        int startAyah = pageData[0]['start'];
        
        // 4. Update translation mode variables (surah index is 0-indexed)
        _currentSurahIndex = surahNum - 1;
        _targetAyahToScroll = startAyah;
        
        // 5. Switch to Translation at the correct surah
        _translationController = PageController(initialPage: _currentSurahIndex);
        _isTranslationMode = true;
      }
      _progressService.saveReadingMode(_isTranslationMode);
    });
    _startHideTimer();
  }

  void _showNavigationSheet() {
    _hideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _NavigationSheet(
        // Pass the list from your Data File
        surahList: QuranData.allSurahs,
        juzList: _juzList,
        onPageSelected: (pageOrSurahInfo) {
          Navigator.pop(context);
          if (_isTranslationMode) {
             // ✅ FIX: In translation mode, the selected value is a PAGE number
             // We need to convert it to the correct SURAH number
             int page = pageOrSurahInfo;
             int surahNum = QuranData.getSurahForPage(page);
             
             // Get the starting ayah for this page
             var pageData = quran.getPageData(page);
             int startAyah = pageData[0]['start'];
             
             setState(() {
               _currentSurahIndex = surahNum - 1;
               _targetAyahToScroll = startAyah;
             });
             _translationController.jumpToPage(_currentSurahIndex);
          } else {
             // Mushaf mode: directly use the page number
             int pageIndex = pageOrSurahInfo - 1;
             setState(() {
               _currentPageIndex = pageIndex;
             });
             _mushafController.jumpToPage(pageIndex);
          }
          _startHideTimer();
        },
      ),
    );
  }

  // --- AUDIO LOGIC ---
  Future<void> _playAyah(int surahNumber, int ayahNumber) async {
    setState(() {
      _isAudioLoading = true;
      _playingSurah = surahNumber;
      _playingAyah = ayahNumber;
      _areControlsVisible = true;
    });

    String? url;
    int attempts = 0;
    while (attempts < 3) {
      url = await _api.getAyahAudioUrl(surahNumber, ayahNumber);
      if (url != null) break;
      attempts++;
      await Future.delayed(const Duration(seconds: 1));
    }
    
    if (url != null) {
      await _audioPlayer.play(UrlSource(url));
      if (mounted) setState(() => _isAudioLoading = false);
    } else {
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _playerState = PlayerState.stopped;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Audio unavailable")));
      }
    }
  }

  void _pauseAudio() async => await _audioPlayer.pause();
  void _resumeAudio() async => await _audioPlayer.resume();
  void _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) setState(() { _playingSurah = null; _playingAyah = null; });
  }

  void _playNextAyah() {
    if (_playingSurah == null || _playingAyah == null) return;
    int totalAyahs = quran.getVerseCount(_playingSurah!);
    if (_playingAyah! < totalAyahs) {
      _playAyah(_playingSurah!, _playingAyah! + 1);
    } else {
      _stopAudio();
    }
  }

  bool _isBookmarked(String surah, int ayah) => _bookmarkedAyahs.contains("$surah:$ayah");

  Future<void> _toggleBookmark(String surah, int ayahNum) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('bookmarked_ayahs_list') ?? [];
    final key = "$surah:$ayahNum";

    if (_isBookmarked(surah, ayahNum)) {
      savedList.removeWhere((e) => jsonDecode(e)['surah'] == surah && jsonDecode(e)['ayah'] == ayahNum);
      setState(() => _bookmarkedAyahs.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bookmark Removed")));
    } else {
      Map<String, dynamic> newBookmark = {
        'surah': surah, 'ayah': ayahNum,
        'page': _currentPageIndex + 1, 'timestamp': DateTime.now().toIso8601String(),
      };
      savedList.add(jsonEncode(newBookmark));
      setState(() => _bookmarkedAyahs.add(key));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bookmark Added"), backgroundColor: AppColors.accentGreen));
    }
    await prefs.setStringList('bookmarked_ayahs_list', savedList);
  }

  void _showAyahMenu(int surahNumber, String surahName, String text, int ayahNum) {
    _hideTimer?.cancel();
    final isBookmarked = _isBookmarked(surahName, ayahNum);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.accentGreen, size: 32),
              title: const Text("Recite from here", style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { Navigator.pop(context); _playAyah(surahNumber, ayahNum); },
            ),
            const Divider(),
            ListTile(
              leading: Icon(isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add, color: AppColors.gold),
              title: Text(isBookmarked ? "Remove Bookmark" : "Bookmark Ayah"),
              onTap: () { Navigator.pop(context); _toggleBookmark(surahName, ayahNum); _startHideTimer(); },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.primaryText),
              title: const Text("Copy Ayah Text"),
              onTap: () { Clipboard.setData(ClipboardData(text: text)); Navigator.pop(context); _startHideTimer(); },
            ),
            const SizedBox(height: 10),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPlayingOrPaused = _playerState == PlayerState.playing || _playerState == PlayerState.paused || _isAudioLoading;

    Widget bodyContent;
    if (_isTranslationMode) {
      bodyContent = PageView.builder(
        controller: _translationController,
        itemCount: 114,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          int surahNum = index + 1;
          return _TranslationSurahLoader(
            surahNumber: surahNum,
            initialAyahScroll: _targetAyahToScroll,
            onTapContent: _toggleControls,
            onVisibleAyahChanged: (ayah) => _currentVisibleAyahInTranslation = ayah,
          );
        },
      );
    } else {
      bodyContent = PageView.builder(
        controller: _mushafController,
        itemCount: 604,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return _MushafPageLoader(
            pageNumber: index + 1,
            onTapContent: _toggleControls,
            onLongPressAyah: _showAyahMenu,
            currentPlayingAyah: (isPlayingOrPaused && _playingSurah != null) ? _playingAyah : null,
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
        child: Stack(
          children: [
            Directionality(textDirection: TextDirection.rtl, child: bodyContent),
            
            // CONTROLS OVERLAY
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
                        Positioned(top: 0, left: 0, child: _GlassButton(icon: Icons.arrow_back_ios_new_rounded, label: "Back", onTap: () => Navigator.pop(context, true))),
                        Positioned(top: 0, right: 0, child: _GlassButton(icon: Icons.grid_view_rounded, label: "Navigate", onTap: _showNavigationSheet)),
                        if (!isPlayingOrPaused)
                          Positioned(bottom: 20, left: 0, right: 0, child: Center(child: _TranslateToggle(isActive: _isTranslationMode, onTap: _toggleTranslationMode))),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // AUDIO PLAYER PANEL
            if (isPlayingOrPaused)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
                  child: Row(
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Reciting Surah $_playingSurah", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text("Ayah $_playingAyah", style: const TextStyle(color: Colors.grey, fontSize: 12))])),
                      if (_isAudioLoading) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen))
                      else ...[
                        IconButton(icon: const Icon(Icons.stop_rounded, color: Colors.red), onPressed: _stopAudio),
                        const SizedBox(width: 10),
                        Container(decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle), child: IconButton(icon: Icon(_playerState == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white), onPressed: () => _playerState == PlayerState.playing ? _pauseAudio() : _resumeAudio())),
                        const SizedBox(width: 10),
                        IconButton(icon: const Icon(Icons.skip_next_rounded, color: AppColors.primaryText), onPressed: _playNextAyah),
                      ]
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- LOADERS ----------------

class _MushafPageLoader extends StatefulWidget {
  final int pageNumber;
  final VoidCallback onTapContent;
  final Function(int, String, String, int) onLongPressAyah;
  final int? currentPlayingAyah;

  const _MushafPageLoader({required this.pageNumber, required this.onTapContent, required this.onLongPressAyah, this.currentPlayingAyah});

  @override
  State<_MushafPageLoader> createState() => _MushafPageLoaderState();
}

class _MushafPageLoaderState extends State<_MushafPageLoader> with AutomaticKeepAliveClientMixin {
  final _api = QuranPageApi();
  late Future<QuranPageResponse> _pageFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageFuture = _api.getPage(widget.pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<QuranPageResponse>(
      future: _pageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        return GestureDetector(
          onTap: widget.onTapContent,
          behavior: HitTestBehavior.translucent,
          child: _MushafPageView(pageData: snapshot.data!.data, onLongPress: widget.onLongPressAyah, highlightAyah: widget.currentPlayingAyah),
        );
      },
    );
  }
}

class _TranslationSurahLoader extends StatefulWidget {
  final int surahNumber;
  final int initialAyahScroll;
  final VoidCallback onTapContent;
  final Function(int) onVisibleAyahChanged;

  const _TranslationSurahLoader({required this.surahNumber, required this.initialAyahScroll, required this.onTapContent, required this.onVisibleAyahChanged});

  @override
  State<_TranslationSurahLoader> createState() => _TranslationSurahLoaderState();
}

class _TranslationSurahLoaderState extends State<_TranslationSurahLoader> with AutomaticKeepAliveClientMixin {
  final _api = QuranPageApi();
  late Future<List<QuranSurah>> _surahFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _surahFuture = _api.getSurahWithTranslation(widget.surahNumber);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<QuranSurah>>(
      future: _surahFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        return GestureDetector(
          onTap: widget.onTapContent,
          child: _TranslationSurahView(surahs: snapshot.data!, initialAyah: widget.initialAyahScroll, onVisibleAyahChanged: widget.onVisibleAyahChanged),
        );
      },
    );
  }
}

// ---------------- VIEWS ----------------

class _TranslationSurahView extends StatefulWidget {
  final List<QuranSurah> surahs;
  final int initialAyah;
  final Function(int) onVisibleAyahChanged;

  const _TranslationSurahView({required this.surahs, required this.initialAyah, required this.onVisibleAyahChanged});

  @override
  State<_TranslationSurahView> createState() => _TranslationSurahViewState();
}

class _TranslationSurahViewState extends State<_TranslationSurahView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    if (widget.initialAyah > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Index mapping: 0 is Header. Ayah 1 is Index 1.
        try { _itemScrollController.jumpTo(index: widget.initialAyah); } catch(e) {}
      });
    }
    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final firstIndex = positions.first.index;
        // Map Index 0 -> Ayah 1 (Header), Index 1 -> Ayah 1.
        int visibleAyah = firstIndex == 0 ? 1 : firstIndex;
        widget.onVisibleAyahChanged(visibleAyah);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final arabicSurah = widget.surahs[0];
    final englishSurah = widget.surahs.length > 1 ? widget.surahs[1] : widget.surahs[0];

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
      itemCount: arabicSurah.ayahs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(children: [
              Text(arabicSurah.name, style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(arabicSurah.englishName, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ]),
          );
        }
        final i = index - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Align(alignment: Alignment.centerRight, child: RichText(textDirection: TextDirection.rtl, textAlign: TextAlign.right, text: TextSpan(style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 26, color: Colors.black, height: 1.6), children: [TextSpan(text: arabicSurah.ayahs[i].text + " "), WidgetSpan(alignment: PlaceholderAlignment.middle, child: _AyahEndSymbol(number: arabicSurah.ayahs[i].numberInSurah))]))),
            const SizedBox(height: 16),
            Directionality(textDirection: TextDirection.ltr, child: Text("${englishSurah.ayahs[i].numberInSurah}. ${englishSurah.ayahs[i].text}", style: const TextStyle(fontSize: 17, height: 1.5, color: AppColors.primaryText))),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, thickness: 0.5),
          ]),
        );
      },
    );
  }
}

class _MushafPageView extends StatelessWidget {
  final QuranPageData pageData;
  final Function(int, String, String, int) onLongPress;
  final int? highlightAyah;
  const _MushafPageView({required this.pageData, required this.onLongPress, this.highlightAyah});
  @override
  Widget build(BuildContext context) {
    String pageSurahName = ""; int pageJuz = 0;
    if (pageData.ayahs.isNotEmpty) { pageSurahName = pageData.ayahs.first.surahName; pageJuz = pageData.ayahs.first.juz; }
    List<Widget> contentWidgets = [];
    if (pageData.ayahs.isEmpty) return const SizedBox();
    String currentSurah = ""; List<InlineSpan> currentSpans = [];
    const quranTextStyle = TextStyle(fontFamily: 'UthmanicHafs', fontSize: 24, color: Colors.black, height: 1.7);
    void flushSpans() { if (currentSpans.isNotEmpty) { contentWidgets.add(RichText(textAlign: TextAlign.justify, textDirection: TextDirection.rtl, text: TextSpan(style: quranTextStyle, children: List.from(currentSpans)))); currentSpans.clear(); } }
    for (var ayah in pageData.ayahs) {
      if (ayah.numberInSurah == 1) {
        flushSpans(); currentSurah = ayah.surahName; contentWidgets.add(_SurahHeader(surahName: currentSurah)); contentWidgets.add(const SizedBox(height: 8));
        if (ayah.surahNumber != 9) { contentWidgets.add(const Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 22, color: AppColors.primaryText))); contentWidgets.add(const SizedBox(height: 12)); }
      }
      String displayText = ayah.text;
      if (ayah.numberInSurah == 1 && ayah.surahNumber != 1 && ayah.surahNumber != 9) { if (displayText.startsWith("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")) { displayText = displayText.substring("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ".length).trim(); } }
      final isPlaying = highlightAyah == ayah.numberInSurah;
      currentSpans.add(TextSpan(text: "$displayText ", style: isPlaying ? const TextStyle(color: AppColors.accentGreen, fontFamily: 'UthmanicHafs', fontSize: 24, height: 1.7) : null, recognizer: LongPressGestureRecognizer()..onLongPress = () { HapticFeedback.mediumImpact(); onLongPress(ayah.surahNumber, currentSurah.isEmpty ? pageSurahName : currentSurah, ayah.text, ayah.numberInSurah); }));
      currentSpans.add(WidgetSpan(alignment: PlaceholderAlignment.middle, child: _AyahEndSymbol(number: ayah.numberInSurah)));
      currentSpans.add(const TextSpan(text: "  "));
    }
    flushSpans();
    return Center(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.topCenter, child: Container(width: MediaQuery.of(context).size.width, padding: const EdgeInsets.fromLTRB(20, 10, 20, 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(pageSurahName, style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 16, fontWeight: FontWeight.bold)), Text("Juz $pageJuz", style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 14, color: Colors.grey))])), ...contentWidgets, const SizedBox(height: 20), Text("${pageData.number}", textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 14, color: Colors.grey))]))));
  }
}

class _AyahEndSymbol extends StatelessWidget {
  final int number;
  const _AyahEndSymbol({required this.number});
  String _toArabic(int num) { const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩']; return num.toString().split('').map((d) => arabicDigits[int.parse(d)]).join(); }
  @override
  Widget build(BuildContext context) { return Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 40, height: 40, child: Stack(alignment: Alignment.center, children: [const Text('\u06DD', style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 34, color: AppColors.gold, height: 1.0)), Padding(padding: const EdgeInsets.only(top: 4), child: Directionality(textDirection: TextDirection.ltr, child: Text(_toArabic(number), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black, height: 1.0))))])); }
}

class _SurahHeader extends StatelessWidget {
  final String surahName;
  const _SurahHeader({required this.surahName});
  @override
  Widget build(BuildContext context) { return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: const Color(0xFFE6E0C6), border: Border.symmetric(horizontal: BorderSide(color: AppColors.gold, width: 2))), child: Text(surahName, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 22, fontWeight: FontWeight.bold))); }
}

class _GlassButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]))); }
}

class _TranslateToggle extends StatelessWidget {
  final bool isActive; final VoidCallback onTap;
  const _TranslateToggle({required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: isActive ? AppColors.accentGreen : Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.translate, size: 18, color: isActive ? Colors.white : Colors.black), const SizedBox(width: 8), Text(isActive ? "Translation ON" : "Translate", style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.bold))]))); }
}

class _NavigationSheet extends StatefulWidget {
  final List<Map<String, dynamic>> surahList; final List<int> juzList; final Function(int) onPageSelected;
  const _NavigationSheet({required this.surahList, required this.juzList, required this.onPageSelected});
  @override
  State<_NavigationSheet> createState() => _NavigationSheetState();
}

class _NavigationSheetState extends State<_NavigationSheet> {
  String _searchQuery = "";
  @override
  Widget build(BuildContext context) {
    final filteredSurahs = widget.surahList.where((s) {
      final name = s['name'].toString().toLowerCase(); final english = s['english'].toString().toLowerCase(); final number = s['number'].toString(); final q = _searchQuery.toLowerCase(); return name.contains(q) || english.contains(q) || number.contains(q);
    }).toList();
    return Container(height: MediaQuery.of(context).size.height * 0.85, decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: DefaultTabController(length: 2, child: Column(children: [const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))), Padding(padding: const EdgeInsets.all(16.0), child: TextField(decoration: InputDecoration(hintText: 'Search Surah (Name or Number)', prefixIcon: const Icon(Icons.search, color: Colors.grey), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)), onChanged: (val) => setState(() => _searchQuery = val))), const TabBar(tabs: [Tab(text: "Surah"), Tab(text: "Juz")], labelColor: AppColors.accentGreen), Expanded(child: TabBarView(children: [ListView.builder(itemCount: filteredSurahs.length, itemBuilder: (ctx, i) { final s = filteredSurahs[i]; return ListTile(leading: CircleAvatar(backgroundColor: AppColors.surfaceLight, child: Text("${s['number']}", style: const TextStyle(fontSize: 12, color: AppColors.primaryText))), title: Text(s['transliteration'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(s['english']), trailing: Text("Page ${s['page']}", style: const TextStyle(color: Colors.grey)), onTap: () => widget.onPageSelected(s['page'])); }), GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: widget.juzList.length, itemBuilder: (ctx, i) => InkWell(onTap: () => widget.onPageSelected((widget.juzList[i] - 1) * 20 + 2), child: Container(alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: AppColors.gold), borderRadius: BorderRadius.circular(8)), child: Text("${widget.juzList[i]}"))))]))])));
  }
}