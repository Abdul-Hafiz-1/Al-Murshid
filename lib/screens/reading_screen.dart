import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
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
  late PageController _pageController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // --- STATE ---
  int _currentPageIndex = 0;
  bool _isTranslationMode = false;
  bool _areControlsVisible = true;
  Timer? _hideTimer;
  List<String> _bookmarkedAyahs = [];

  // Audio State
  PlayerState _playerState = PlayerState.stopped;
  bool _isAudioLoading = false;
  int? _playingSurah;
  int? _playingAyah;
  
  // Streams
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  // --- DATA ---
  final List<Map<String, dynamic>> _allSurahs = [
    {"number": 1, "name": "Al-Fatiha", "english": "The Opening", "page": 1, "ayahs": 7},
    {"number": 2, "name": "Al-Baqarah", "english": "The Cow", "page": 2, "ayahs": 286},
    {"number": 3, "name": "Ali 'Imran", "english": "Family of Imran", "page": 50, "ayahs": 200},
    {"number": 4, "name": "An-Nisa", "english": "The Women", "page": 77, "ayahs": 176},
    {"number": 5, "name": "Al-Ma'idah", "english": "The Table Spread", "page": 106, "ayahs": 120},
    {"number": 6, "name": "Al-An'am", "english": "The Cattle", "page": 128, "ayahs": 165},
    {"number": 7, "name": "Al-A'raf", "english": "The Heights", "page": 151, "ayahs": 206},
    {"number": 8, "name": "Al-Anfal", "english": "The Spoils of War", "page": 177, "ayahs": 75},
    {"number": 9, "name": "At-Tawbah", "english": "The Repentance", "page": 187, "ayahs": 129},
    {"number": 10, "name": "Yunus", "english": "Jonah", "page": 208, "ayahs": 109},
    {"number": 11, "name": "Hud", "english": "Hud", "page": 221, "ayahs": 123},
    {"number": 12, "name": "Yusuf", "english": "Joseph", "page": 235, "ayahs": 111},
    {"number": 13, "name": "Ar-Ra'd", "english": "The Thunder", "page": 249, "ayahs": 43},
    {"number": 14, "name": "Ibrahim", "english": "Abraham", "page": 255, "ayahs": 52},
    {"number": 15, "name": "Al-Hijr", "english": "The Rocky Tract", "page": 262, "ayahs": 99},
    {"number": 16, "name": "An-Nahl", "english": "The Bee", "page": 267, "ayahs": 128},
    {"number": 17, "name": "Al-Isra", "english": "The Night Journey", "page": 282, "ayahs": 111},
    {"number": 18, "name": "Al-Kahf", "english": "The Cave", "page": 293, "ayahs": 110},
    {"number": 19, "name": "Maryam", "english": "Mary", "page": 305, "ayahs": 98},
    {"number": 20, "name": "Ta-Ha", "english": "Ta-Ha", "page": 312, "ayahs": 135},
    {"number": 21, "name": "Al-Anbiya", "english": "The Prophets", "page": 322, "ayahs": 112},
    {"number": 22, "name": "Al-Hajj", "english": "The Pilgrimage", "page": 332, "ayahs": 78},
    {"number": 23, "name": "Al-Mu'minun", "english": "The Believers", "page": 342, "ayahs": 118},
    {"number": 24, "name": "An-Nur", "english": "The Light", "page": 350, "ayahs": 64},
    {"number": 25, "name": "Al-Furqan", "english": "The Criterian", "page": 359, "ayahs": 77},
    {"number": 26, "name": "Ash-Shu'ara", "english": "The Poets", "page": 367, "ayahs": 227},
    {"number": 27, "name": "An-Naml", "english": "The Ant", "page": 377, "ayahs": 93},
    {"number": 28, "name": "Al-Qasas", "english": "The Stories", "page": 385, "ayahs": 88},
    {"number": 29, "name": "Al-Ankabut", "english": "The Spider", "page": 396, "ayahs": 69},
    {"number": 30, "name": "Ar-Rum", "english": "The Romans", "page": 404, "ayahs": 60},
    {"number": 31, "name": "Luqman", "english": "Luqman", "page": 411, "ayahs": 34},
    {"number": 32, "name": "As-Sajdah", "english": "The Prostration", "page": 415, "ayahs": 30},
    {"number": 33, "name": "Al-Ahzab", "english": "The Combined Forces", "page": 418, "ayahs": 73},
    {"number": 34, "name": "Saba", "english": "Sheba", "page": 428, "ayahs": 54},
    {"number": 35, "name": "Fatir", "english": "Originator", "page": 434, "ayahs": 45},
    {"number": 36, "name": "Ya-Sin", "english": "Ya Sin", "page": 440, "ayahs": 83},
    {"number": 37, "name": "As-Saffat", "english": "Those who set the Ranks", "page": 446, "ayahs": 182},
    {"number": 38, "name": "Sad", "english": "The Letter \"Saad\"", "page": 453, "ayahs": 88},
    {"number": 39, "name": "Az-Zumar", "english": "The Troops", "page": 458, "ayahs": 75},
    {"number": 40, "name": "Ghafir", "english": "The Forgiver", "page": 467, "ayahs": 85},
    {"number": 41, "name": "Fussilat", "english": "Explained in Detail", "page": 477, "ayahs": 54},
    {"number": 42, "name": "Ash-Shura", "english": "The Consultation", "page": 483, "ayahs": 53},
    {"number": 43, "name": "Az-Zukhruf", "english": "The Ornaments of Gold", "page": 489, "ayahs": 89},
    {"number": 44, "name": "Ad-Dukhan", "english": "The Smoke", "page": 496, "ayahs": 59},
    {"number": 45, "name": "Al-Jathiyah", "english": "The Crouching", "page": 499, "ayahs": 37},
    {"number": 46, "name": "Al-Ahqaf", "english": "The Wind-Curved Sandhills", "page": 502, "ayahs": 35},
    {"number": 47, "name": "Muhammad", "english": "Muhammad", "page": 507, "ayahs": 38},
    {"number": 48, "name": "Al-Fath", "english": "The Victory", "page": 511, "ayahs": 29},
    {"number": 49, "name": "Al-Hujurat", "english": "The Rooms", "page": 515, "ayahs": 18},
    {"number": 50, "name": "Qaf", "english": "The Letter \"Qaf\"", "page": 518, "ayahs": 45},
    {"number": 51, "name": "Ad-Dhariyat", "english": "The Winnowing Winds", "page": 520, "ayahs": 60},
    {"number": 52, "name": "At-Tur", "english": "The Mount", "page": 523, "ayahs": 49},
    {"number": 53, "name": "An-Najm", "english": "The Star", "page": 526, "ayahs": 62},
    {"number": 54, "name": "Al-Qamar", "english": "The Moon", "page": 528, "ayahs": 55},
    {"number": 55, "name": "Ar-Rahman", "english": "The Beneficent", "page": 531, "ayahs": 78},
    {"number": 56, "name": "Al-Waqi'ah", "english": "The Inevitable", "page": 534, "ayahs": 96},
    {"number": 57, "name": "Al-Hadid", "english": "The Iron", "page": 537, "ayahs": 29},
    {"number": 58, "name": "Al-Mujadila", "english": "The Pleading Woman", "page": 542, "ayahs": 22},
    {"number": 59, "name": "Al-Hashr", "english": "The Exile", "page": 545, "ayahs": 24},
    {"number": 60, "name": "Al-Mumtahanah", "english": "She that is to be examined", "page": 549, "ayahs": 13},
    {"number": 61, "name": "As-Saff", "english": "The Ranks", "page": 551, "ayahs": 14},
    {"number": 62, "name": "Al-Jumu'ah", "english": "The Congregation, Friday", "page": 553, "ayahs": 11},
    {"number": 63, "name": "Al-Munafiqun", "english": "The Hypocrites", "page": 554, "ayahs": 11},
    {"number": 64, "name": "At-Taghabun", "english": "The Mutual Disillusion", "page": 556, "ayahs": 18},
    {"number": 65, "name": "At-Talaq", "english": "The Divorce", "page": 558, "ayahs": 12},
    {"number": 66, "name": "At-Tahrim", "english": "The Prohibition", "page": 560, "ayahs": 12},
    {"number": 67, "name": "Al-Mulk", "english": "The Sovereignty", "page": 562, "ayahs": 30},
    {"number": 68, "name": "Al-Qalam", "english": "The Pen", "page": 564, "ayahs": 52},
    {"number": 69, "name": "Al-Haqqah", "english": "The Reality", "page": 566, "ayahs": 52},
    {"number": 70, "name": "Al-Ma'arij", "english": "The Ascending Stairways", "page": 568, "ayahs": 44},
    {"number": 71, "name": "Nuh", "english": "Noah", "page": 570, "ayahs": 28},
    {"number": 72, "name": "Al-Jinn", "english": "The Jinn", "page": 572, "ayahs": 28},
    {"number": 73, "name": "Al-Muzzammil", "english": "The Enshrouded One", "page": 574, "ayahs": 20},
    {"number": 74, "name": "Al-Muddaththir", "english": "The Cloaked One", "page": 575, "ayahs": 56},
    {"number": 75, "name": "Al-Qiyamah", "english": "The Resurrection", "page": 577, "ayahs": 40},
    {"number": 76, "name": "Al-Insan", "english": "The Man", "page": 578, "ayahs": 31},
    {"number": 77, "name": "Al-Mursalat", "english": "The Emissaries", "page": 580, "ayahs": 50},
    {"number": 78, "name": "An-Naba", "english": "The Tidings", "page": 582, "ayahs": 40},
    {"number": 79, "name": "An-Nazi'at", "english": "Those who drag forth", "page": 583, "ayahs": 46},
    {"number": 80, "name": "Abasa", "english": "He Frowned", "page": 585, "ayahs": 42},
    {"number": 81, "name": "At-Takwir", "english": "The Overthrowing", "page": 586, "ayahs": 29},
    {"number": 82, "name": "Al-Infitar", "english": "The Cleaving", "page": 587, "ayahs": 19},
    {"number": 83, "name": "Al-Mutaffifin", "english": "The Defrauding", "page": 587, "ayahs": 36},
    {"number": 84, "name": "Al-Inshiqaq", "english": "The Sundering", "page": 589, "ayahs": 25},
    {"number": 85, "name": "Al-Buruj", "english": "The Mansions of the Stars", "page": 590, "ayahs": 22},
    {"number": 86, "name": "At-Tariq", "english": "The Morning Star", "page": 591, "ayahs": 17},
    {"number": 87, "name": "Al-A'la", "english": "The Most High", "page": 591, "ayahs": 19},
    {"number": 88, "name": "Al-Ghashiyah", "english": "The Overwhelming", "page": 592, "ayahs": 26},
    {"number": 89, "name": "Al-Fajr", "english": "The Dawn", "page": 593, "ayahs": 30},
    {"number": 90, "name": "Al-Balad", "english": "The City", "page": 594, "ayahs": 20},
    {"number": 91, "name": "Ash-Shams", "english": "The Sun", "page": 595, "ayahs": 15},
    {"number": 92, "name": "Al-Layl", "english": "The Night", "page": 595, "ayahs": 21},
    {"number": 93, "name": "Ad-Duha", "english": "The Morning Hours", "page": 596, "ayahs": 11},
    {"number": 94, "name": "Ash-Sharh", "english": "The Relief", "page": 596, "ayahs": 8},
    {"number": 95, "name": "At-Tin", "english": "The Fig", "page": 597, "ayahs": 8},
    {"number": 96, "name": "Al-'Alaq", "english": "The Clot", "page": 597, "ayahs": 19},
    {"number": 97, "name": "Al-Qadr", "english": "The Power", "page": 598, "ayahs": 5},
    {"number": 98, "name": "Al-Bayyinah", "english": "The Clear Proof", "page": 598, "ayahs": 8},
    {"number": 99, "name": "Az-Zalzalah", "english": "The Earthquake", "page": 599, "ayahs": 8},
    {"number": 100, "name": "Al-'Adiyat", "english": "The Courser", "page": 599, "ayahs": 11},
    {"number": 101, "name": "Al-Qari'ah", "english": "The Calamity", "page": 600, "ayahs": 11},
    {"number": 102, "name": "At-Takathur", "english": "The Rivalry in world increase", "page": 600, "ayahs": 8},
    {"number": 103, "name": "Al-'Asr", "english": "The Declining Day", "page": 601, "ayahs": 3},
    {"number": 104, "name": "Al-Humazah", "english": "The Traducer", "page": 601, "ayahs": 9},
    {"number": 105, "name": "Al-Fil", "english": "The Elephant", "page": 601, "ayahs": 5},
    {"number": 106, "name": "Quraysh", "english": "Quraysh", "page": 602, "ayahs": 4},
    {"number": 107, "name": "Al-Ma'un", "english": "The Small Kindnesses", "page": 602, "ayahs": 7},
    {"number": 108, "name": "Al-Kawthar", "english": "The Abundance", "page": 602, "ayahs": 3},
    {"number": 109, "name": "Al-Kafirun", "english": "The Disbelievers", "page": 603, "ayahs": 6},
    {"number": 110, "name": "An-Nasr", "english": "The Divine Support", "page": 603, "ayahs": 3},
    {"number": 111, "name": "Al-Masad", "english": "The Palm Fiber", "page": 603, "ayahs": 5},
    {"number": 112, "name": "Al-Ikhlas", "english": "The Sincerity", "page": 604, "ayahs": 4},
    {"number": 113, "name": "Al-Falaq", "english": "The Daybreak", "page": 604, "ayahs": 5},
    {"number": 114, "name": "An-Nas", "english": "Mankind", "page": 604, "ayahs": 6}
  ];

  final List<int> _juzList = List.generate(30, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _startHideTimer();
    _loadBookmarks();
    _setupAudio();
  }

  // Split initialization to be cleaner and async-aware
  Future<void> _setupAudio() async {
    // 1. CONFIGURE AUDIO CONTEXT
    // CRITICAL: Empty Set for iOS 'options' to avoid assertion crash
    // CRITICAL: stayAwake: true for Android background playback
    await _audioPlayer.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {}, 
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));

    // 2. SYNC PLAYER STATE
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });

    // 3. CONTINUOUS PLAYBACK
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      _playNextAyah();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  // --- AUDIO LOGIC (WITH RETRY) ---

  Future<void> _playAyah(int surahNumber, int ayahNumber) async {
    setState(() {
      _isAudioLoading = true;
      _playingSurah = surahNumber;
      _playingAyah = ayahNumber;
      _areControlsVisible = true;
    });

    String? url;
    // RETRY LOGIC: Try 3 times to fetch URL (Resilience for background/doze mode)
    int attempts = 0;
    while (attempts < 3) {
      url = await _api.getAyahAudioUrl(surahNumber, ayahNumber);
      if (url != null) break;
      attempts++;
      await Future.delayed(const Duration(seconds: 1)); // Wait before retry
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Audio unavailable. Check internet.")),
        );
      }
    }
  }

  void _pauseAudio() async {
    await _audioPlayer.pause();
  }

  void _resumeAudio() async {
    await _audioPlayer.resume();
  }

  void _playNextAyah() {
    if (_playingSurah == null || _playingAyah == null) return;

    final surahData = _allSurahs.firstWhere(
      (s) => s['number'] == _playingSurah, 
      orElse: () => {'ayahs': 0}
    );
    
    final int maxAyahs = surahData['ayahs'];

    if (_playingAyah! < maxAyahs) {
      _playAyah(_playingSurah!, _playingAyah! + 1);
    } else {
      _stopAudio();
    }
  }

  void _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) setState(() {
      _playingSurah = null;
      _playingAyah = null;
    });
  }

  // --- BOOKMARK LOGIC ---
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
      setState(() => _bookmarkedAyahs.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bookmark Removed")));
    } else {
      Map<String, dynamic> newBookmark = {
        'surah': surah,
        'ayah': ayahNum,
        'page': _currentPageIndex + 1,
        'timestamp': DateTime.now().toIso8601String(),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.accentGreen, size: 32),
                title: const Text("Recite from here", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Plays until end of Surah"),
                onTap: () {
                  Navigator.pop(context);
                  _playAyah(surahNumber, ayahNum);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add, color: AppColors.gold),
                title: Text(isBookmarked ? "Remove Bookmark" : "Bookmark Ayah"),
                onTap: () {
                  Navigator.pop(context);
                  _toggleBookmark(surahName, ayahNum);
                  _startHideTimer();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.primaryText),
                title: const Text("Copy Ayah Text"),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied"), duration: Duration(seconds: 1)));
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
    final isPlayingOrPaused = _playerState == PlayerState.playing || _playerState == PlayerState.paused || _isAudioLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
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
                    currentPlayingAyah: (isPlayingOrPaused && _playingSurah != null) ? _playingAyah : null,
                  );
                },
              ),
            ),
            
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
                        Positioned(
                          top: 0, left: 0,
                          child: _GlassButton(
                            icon: Icons.arrow_back_ios_new_rounded, label: "Back",
                            onTap: () => Navigator.pop(context, true),
                          ),
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: _GlassButton(
                            icon: Icons.grid_view_rounded, label: "Navigate",
                            onTap: _showNavigationSheet,
                          ),
                        ),
                        
                        if (!isPlayingOrPaused)
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

            // AUDIO PLAYER BOTTOM PANEL
            if (isPlayingOrPaused)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Reciting Surah $_playingSurah", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("Ayah $_playingAyah", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Controls
                      if (_isAudioLoading)
                        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen))
                      else ...[
                        // STOP
                        IconButton(
                          icon: const Icon(Icons.stop_rounded, color: Colors.red),
                          onPressed: _stopAudio,
                        ),
                        const SizedBox(width: 10),
                        // PLAY/PAUSE
                        Container(
                          decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle),
                          child: IconButton(
                            icon: Icon(_playerState == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                            onPressed: () {
                              if (_playerState == PlayerState.playing) {
                                _pauseAudio();
                              } else {
                                _resumeAudio();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // NEXT
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: AppColors.primaryText),
                          onPressed: _playNextAyah,
                        ),
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

class _PageLoader extends StatefulWidget {
  final int pageNumber;
  final bool isTranslationMode;
  final VoidCallback onTapContent;
  final Function(int, String, String, int) onLongPressAyah;
  final int? currentPlayingAyah;

  const _PageLoader({
    required this.pageNumber,
    required this.isTranslationMode,
    required this.onTapContent,
    required this.onLongPressAyah,
    this.currentPlayingAyah,
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
      setState(() => _loadData());
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
                  highlightAyah: widget.currentPlayingAyah,
                ),
        );
      },
    );
  }
}

// ---------------- VIEWS ----------------

class _MushafPageView extends StatelessWidget {
  final QuranPageData pageData;
  final Function(int, String, String, int) onLongPress;
  final int? highlightAyah;

  const _MushafPageView({required this.pageData, required this.onLongPress, this.highlightAyah});

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
      if (ayah.numberInSurah == 1) {
        flushSpans();
        currentSurah = ayah.surahName;
        contentWidgets.add(_SurahHeader(surahName: currentSurah));
        contentWidgets.add(const SizedBox(height: 8));
        
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
      if (ayah.numberInSurah == 1 && ayah.surahNumber != 1 && ayah.surahNumber != 9) {
        const bismillah = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";
        if (displayText.startsWith(bismillah)) {
          displayText = displayText.substring(bismillah.length).trim();
        } else {
           if (displayText.length > 20 && displayText.contains("ٱلرَّحِيمِ")) {
              displayText = displayText.replaceFirst(RegExp(r'^.*?ٱلرَّحِيمِ\s*'), '');
           }
        }
      }

      final isPlaying = highlightAyah == ayah.numberInSurah;

      currentSpans.add(
        TextSpan(
          text: "$displayText ",
          style: isPlaying ? const TextStyle(color: AppColors.accentGreen, fontFamily: 'UthmanicHafs', fontSize: 24, height: 1.7) : null,
          recognizer: LongPressGestureRecognizer()
            ..onLongPress = () {
              HapticFeedback.mediumImpact();
              onLongPress(ayah.surahNumber, currentSurah.isEmpty ? pageSurahName : currentSurah, ayah.text, ayah.numberInSurah);
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
          const Text(
            '\u06DD',
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 34,
              color: AppColors.gold,
              height: 1.0, 
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4), 
            child: Directionality(
              textDirection: TextDirection.ltr, 
              child: Text(
                _toArabic(number),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
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