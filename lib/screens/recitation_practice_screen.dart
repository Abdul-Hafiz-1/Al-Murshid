import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran/quran.dart' as quran;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:tarteel/theme/app_theme.dart';
import 'package:tarteel/services/quran_page_api.dart';
import 'package:tarteel/data/quran_data.dart'; 

class RecitationPracticeScreen extends StatefulWidget {
  final int initialSurah;
  final int initialAyah;

  const RecitationPracticeScreen({
    super.key,
    this.initialSurah = 1, 
    this.initialAyah = 1,
  });

  @override
  State<RecitationPracticeScreen> createState() => _RecitationPracticeScreenState();
}

class _RecitationPracticeScreenState extends State<RecitationPracticeScreen> {
  // --- STATE ---
  late int _currentSurah;
  late PageController _pageController;
  
  // --- AUDIO & SPEECH ---
  late stt.SpeechToText _speech;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _api = QuranPageApi();

  bool _isMicActive = false;
  String _spokenText = "";
  String _statusMessage = "Tap Mic to Start";
  
  // 0=Pending, 1=Perfect(Green), 2=Warning(Orange), 3=Wrong(Red)
  List<int> _wordStatuses = [];
  List<String> _ayahWords = [];
  int _currentWordIndex = 0; 

  bool _areControlsVisible = true;
  Timer? _hideTimer;
  Timer? _micResetTimer;

  @override
  void initState() {
    super.initState();
    _currentSurah = widget.initialSurah;
    _pageController = PageController(initialPage: widget.initialAyah - 1);
    
    _speech = stt.SpeechToText();
    _prepareAyah(widget.initialAyah); 
    _startHideTimer();
  }

  @override
  void dispose() {
    _isMicActive = false;
    _pageController.dispose();
    _speech.stop();
    _audioPlayer.dispose();
    _hideTimer?.cancel();
    _micResetTimer?.cancel();
    super.dispose();
  }

  // --- 1. DATA ---

  void _onAyahChanged(int pageIndex) {
    _softStopMic();
    int ayahNum = pageIndex + 1;
    _prepareAyah(ayahNum);
    
    if (_isMicActive) {
      _micResetTimer = Timer(const Duration(milliseconds: 600), _startListeningLoop);
    }
    _startHideTimer();
  }

  void _prepareAyah(int ayahNum) {
    String text = quran.getVerse(_currentSurah, ayahNum);
    
    if (ayahNum == 1 && _currentSurah != 1 && _currentSurah != 9) {
      text = text.replaceAll("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "").trim();
    }

    setState(() {
      _ayahWords = text.split(' ');
      _wordStatuses = List.filled(_ayahWords.length, 0);
      _currentWordIndex = 0;
      _spokenText = "";
      _statusMessage = "Ready";
    });
  }

  void _jumpToSurah(int surahNumber) {
    setState(() {
      _currentSurah = surahNumber;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    });
    _prepareAyah(1);
    Navigator.pop(context);
  }

  // --- 2. ROBUST MIC LOGIC ---

  void _toggleMic() {
    setState(() => _isMicActive = !_isMicActive);
    if (_isMicActive) {
      _startListeningLoop();
    } else {
      _stopListeningSession();
    }
  }

  Future<void> _startListeningLoop() async {
    if (!_isMicActive) return;

    if (await Permission.microphone.request().isDenied) {
      setState(() => _isMicActive = false);
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (val) {
        if (!mounted) return;
        if (val == 'listening') setState(() => _statusMessage = "Listening...");
        
        // Auto-Restart Loop
        if ((val == 'done' || val == 'notListening') && _isMicActive) {
           if (_audioPlayer.state != PlayerState.playing) {
              _micResetTimer?.cancel();
              _micResetTimer = Timer(const Duration(milliseconds: 50), _startListeningLoop);
           }
        }
      },
      onError: (val) => _isMicActive ? _startListeningLoop() : null,
    );

    if (available) {
      _speech.listen(
        onResult: (val) {
          setState(() => _spokenText = val.recognizedWords);
          _verifyRecitation(val.recognizedWords);
        },
        localeId: 'ar_SA', 
        listenFor: const Duration(seconds: 60), 
        pauseFor: const Duration(seconds: 10),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void _stopListeningSession() {
    _speech.stop();
    _micResetTimer?.cancel();
    setState(() {
      _isMicActive = false;
      _statusMessage = "Paused";
    });
  }

  void _softStopMic() {
    _speech.stop();
    _micResetTimer?.cancel();
  }

  // --- 3. FORGIVING SCORING SYSTEM ---

  void _verifyRecitation(String recognizedText) {
    if (recognizedText.isEmpty) return;

    List<String> spokenWords = recognizedText.split(' ');
    
    // Look back a few words
    int lookBackCount = 6;
    int startScan = (spokenWords.length - lookBackCount).clamp(0, spokenWords.length);
    
    for (int i = startScan; i < spokenWords.length; i++) {
      if (_currentWordIndex >= _ayahWords.length) break;

      String spoken = spokenWords[i];
      String target = _ayahWords[_currentWordIndex];
      
      int score = _gradeWord(spoken, target);
      
      if (score == 1 || score == 2) { 
        setState(() {
          _wordStatuses[_currentWordIndex] = score; 
          _currentWordIndex++; 
        });
        continue;
      } 

      // Check Skip (Did they say the next word?)
      if (_currentWordIndex < _ayahWords.length - 1) {
        String nextTarget = _ayahWords[_currentWordIndex + 1];
        if (_gradeWord(spoken, nextTarget) <= 2) {
          setState(() {
            _wordStatuses[_currentWordIndex] = 3; // Skipped = Red
            _wordStatuses[_currentWordIndex + 1] = _gradeWord(spoken, nextTarget); 
            _currentWordIndex += 2; 
          });
          continue;
        }
      }
    }

    if (_currentWordIndex >= _ayahWords.length) {
      _handleSuccess();
    }
  }

  /// Returns:
  /// 1 = Green (Match)
  /// 2 = Orange (Mismatch Harakat ONLY)
  /// 3 = Red (Mismatch Letters)
  int _gradeWord(String spoken, String quranWord) {
    String qStandard = _uthmanicToStandard(quranWord);
    String sStandard = _uthmanicToStandard(spoken);

    String qSkeleton = _removeVowels(qStandard);
    String sSkeleton = _removeVowels(sStandard);

    // --- OVERRIDES FOR COMMON ISSUES ---
    // Handle Rahman variants (Al-Rahman vs Al-Rahmaan)
    if ((qSkeleton.contains("رحمن") || qSkeleton.contains("رحمان")) && 
        (sSkeleton.contains("رحمن") || sSkeleton.contains("رحمان"))) {
      return 1;
    }
    // Handle Maghdoobi (Al-Maghdoobi)
    if (qSkeleton.contains("مغضوب") && sSkeleton.contains("مغضوب")) return 1;
    
    // Exact Letter Match?
    if (qSkeleton == sSkeleton) {
       // Check Vowels
       String sVowels = _extractVowels(sStandard);
       // ✅ FIX: If phone gave NO vowels, assume correct (Green).
       if (sVowels.isEmpty) return 1; 
       
       String qVowels = _extractVowels(qStandard);
       if (qVowels != sVowels) return 2; // Only Orange if vowels EXPLICITLY mismatch
       return 1;
    }
    
    return 3; // Red
  }

  String _uthmanicToStandard(String text) {
    return text
        .replaceAll('ٱ', 'ا') 
        .replaceAll('آ', 'ا') 
        .replaceAll('إ', 'ا') 
        .replaceAll('أ', 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ٰ', 'ا') 
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ''); 
  }

  String _removeVowels(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  String _extractVowels(String text) {
    return text.replaceAll(RegExp(r'[^\u064E\u064F\u0650\u0652\u0651]'), '');
  }

  // --- 4. SUCCESS ---

  void _handleSuccess() async {
    _softStopMic();
    
    // If we have red words, it's not a success
    if (_wordStatuses.contains(3)) {
       _playCorrection();
       return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Correct!"), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
    );
    
    await Future.delayed(const Duration(seconds: 1));
    if (mounted && _isMicActive) {
      int next = _pageController.page!.round() + 1;
      if (next < quran.getVerseCount(_currentSurah)) {
        _pageController.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else {
        setState(() {
          _isMicActive = false;
          _statusMessage = "Surah Complete";
        });
      }
    }
  }

  Future<void> _playCorrection() async {
    _softStopMic();
    setState(() => _statusMessage = "Listening to Correction...");

    int currentAyah = _pageController.page!.round() + 1;
    String? url = await _api.getAyahAudioUrl(_currentSurah, currentAyah);
    
    if (url != null) {
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.first.then((_) {
        if (mounted && _isMicActive) _startListeningLoop();
      });
    }
  }

  // --- 5. UI ---

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isMicActive) setState(() => _areControlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _areControlsVisible = !_areControlsVisible);
    if (_areControlsVisible) _startHideTimer();
  }

  void _showNavigationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PracticeNavigationSheet(
        surahList: QuranData.allSurahs,
        onSurahSelected: _jumpToSurah,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalAyahs = quran.getVerseCount(_currentSurah);
    String surahName = quran.getSurahNameArabic(_currentSurah);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ayah View
          GestureDetector(
            onTap: _toggleControls,
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalAyahs,
              onPageChanged: _onAyahChanged,
              itemBuilder: (context, index) {
                int ayahNum = index + 1;
                bool isCurrent = (index == (_pageController.hasClients ? _pageController.page?.round() : widget.initialAyah - 1));
                
                return _AyahPracticeView(
                  surahName: surahName,
                  ayahNumber: ayahNum,
                  words: isCurrent ? _ayahWords : quran.getVerse(_currentSurah, ayahNum).split(' '),
                  statuses: isCurrent ? _wordStatuses : [],
                );
              },
            ),
          ),

          // Top Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _areControlsVisible ? 0 : -100,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded, 
                      label: "Back", 
                      onTap: () => Navigator.pop(context)
                    ),
                    _GlassButton(
                      icon: Icons.grid_view_rounded, 
                      label: quran.getSurahName(_currentSurah), 
                      onTap: _showNavigationSheet
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_isMicActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text(_statusMessage, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: "correction",
                      backgroundColor: Colors.orangeAccent,
                      mini: true,
                      onPressed: _playCorrection,
                      child: const Icon(Icons.hearing, color: Colors.white),
                    ),
                    const SizedBox(width: 30),
                    
                    GestureDetector(
                      onTap: _toggleMic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: _isMicActive ? Colors.red : AppColors.accentGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isMicActive ? Colors.red : AppColors.accentGreen).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Icon(
                          _isMicActive ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    
                    FloatingActionButton(
                      heroTag: "next",
                      backgroundColor: AppColors.primaryText,
                      mini: true,
                      onPressed: () {
                         int next = _pageController.page!.round() + 1;
                         if (next < totalAyahs) _pageController.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      },
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Debug (Active Word)
          if (_isMicActive)
             Positioned(
              bottom: 160,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _spokenText.isEmpty ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    _spokenText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _AyahPracticeView extends StatelessWidget {
  final String surahName;
  final int ayahNumber;
  final List<String> words;
  final List<int> statuses; 

  const _AyahPracticeView({
    required this.surahName,
    required this.ayahNumber,
    required this.words,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$surahName - Ayah $ayahNumber",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6.0,
                runSpacing: 12.0,
                children: List.generate(words.length, (index) {
                  Color color = Colors.black;
                  // Status Logic: 1=Green, 2=Orange, 3=Red
                  if (statuses.isNotEmpty && index < statuses.length) {
                    if (statuses[index] == 1) color = Colors.green; // Perfect
                    if (statuses[index] == 2) color = Colors.orange; // Vowel Warning
                    if (statuses[index] == 3) color = Colors.red; // Wrong
                  }

                  return Text(
                    words[index],
                    style: TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: 32,
                      color: color,
                      fontWeight: (color != Colors.black) ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 120), 
          ],
        ),
      ),
    );
  }
}

class _PracticeNavigationSheet extends StatefulWidget {
  final List<Map<String, dynamic>> surahList;
  final Function(int) onSurahSelected;

  const _PracticeNavigationSheet({required this.surahList, required this.onSurahSelected});

  @override
  State<_PracticeNavigationSheet> createState() => _PracticeNavigationSheetState();
}

class _PracticeNavigationSheetState extends State<_PracticeNavigationSheet> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filtered = widget.surahList.where((s) {
      final q = _searchQuery.toLowerCase();
      return s['transliteration'].toString().toLowerCase().contains(q) ||
             s['number'].toString().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Select Surah to Practice',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final s = filtered[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    child: Text("${s['number']}"),
                  ),
                  title: Text(s['transliteration'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(s['english']),
                  onTap: () => widget.onSurahSelected(s['number']),
                );
              },
            ),
          ),
        ],
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