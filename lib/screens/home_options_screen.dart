import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/screens/reading_screen.dart';
import 'package:tarteel/screens/settings_screen.dart';
import 'package:tarteel/services/reading_progress_service.dart';
import 'package:tarteel/theme/app_theme.dart';

class HomeOptionsScreen extends StatefulWidget {
  const HomeOptionsScreen({super.key});

  @override
  State<HomeOptionsScreen> createState() => _HomeOptionsScreenState();
}

class _HomeOptionsScreenState extends State<HomeOptionsScreen> {
  final _progressService = ReadingProgressService();
  Future<int?>? _lastReadPageFuture;
  List<Map<String, dynamic>> _bookmarks = [];
  
  final _greetings = const [
    'Assalamu Alaikum', 'Peace be upon you', 'Salut', 
    'Hola', 'Nǐ hǎo', 'Konnichiwa', 'Salam'
  ];
  int _currentGreetingIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastReadPageFuture = _progressService.loadLastReadPage();
    _loadBookmarks();
    Future<void>.delayed(const Duration(seconds: 3), _rotateGreeting);
  }
  
  // NEW: Load real bookmarks from storage
  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('bookmarked_ayahs_list') ?? [];
    
    if (mounted) {
      setState(() {
        _bookmarks = savedList
            .map((e) => jsonDecode(e) as Map<String, dynamic>)
            .toList()
            .reversed // Show newest first
            .toList();
      });
    }
  }

  void _rotateGreeting() {
    if (!mounted) return;
    setState(() {
      _currentGreetingIndex = (_currentGreetingIndex + 1) % _greetings.length;
    });
    Future<void>.delayed(const Duration(seconds: 3), _rotateGreeting);
  }

  void _openReading({int? initialPage}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingScreen(initialPage: initialPage),
      ),
    ).then((_) {
      // Refresh bookmarks when returning from reading screen
      _loadBookmarks();
      setState(() {
        _lastReadPageFuture = _progressService.loadLastReadPage();
      });
    });
  }
  
  void _openSettings() {
     Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: Container(
            color: AppColors.background,
            child: Column(
              children: [
                // Header & Greeting
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 600),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 0.2),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Align(
                                  key: ValueKey(_greetings[_currentGreetingIndex]),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _greetings[_currentGreetingIndex],
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Al-Murshid',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_outlined, color: AppColors.primaryText),
                      ),
                    ],
                  ),
                ),

                // Last Read Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: FutureBuilder<int?>(
                    future: _lastReadPageFuture,
                    builder: (context, snapshot) {
                      final lastPage = snapshot.data;
                      if (lastPage == null) {
                        return _LastReadCard(
                          title: 'Start Your Journey',
                          subtitle: 'Begin reading the Quran',
                          progress: 0.0,
                          buttonLabel: 'Start Reading',
                          onPressed: () => _openReading(),
                        );
                      }
                      return _LastReadCard(
                        title: 'Where you left off',
                        subtitle: 'Page $lastPage',
                        progress: lastPage / 604.0,
                        buttonLabel: 'Continue',
                        onPressed: () => _openReading(initialPage: lastPage),
                      );
                    },
                  ),
                ),

                // Bookmarks Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: _BookmarksStack(bookmarks: _bookmarks),
                ),

                const SizedBox(height: 4),

                // Main Menu
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Main Menu',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _CardTile(
                                  title: 'Read Quran',
                                  subtitle: 'Mushaf view for focused recitation',
                                  icon: Icons.menu_book_rounded,
                                  onTap: () => _openReading(),
                                ),
                                const SizedBox(height: 12),
                                _CardTile(
                                  title: 'Recitation Practice',
                                  subtitle: 'Listen, repeat, and refine',
                                  icon: Icons.mic_none_rounded,
                                  onTap: () => _showComingSoon('Coming soon...'),
                                ),
                                const SizedBox(height: 12),
                                _CardTile(
                                  title: 'Hifz Practice',
                                  subtitle: 'Smart repetition for memorisation',
                                  icon: Icons.psychology_alt_outlined,
                                  onTap: () => _showComingSoon('Coming soon...'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showComingSoon(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ... _LastReadCard class (Same as before) ...
class _LastReadCard extends StatelessWidget {
  const _LastReadCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppColors.accentGreen.withOpacity(0.95),
            AppColors.accentGreen.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.bookmark_border_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFDF5C1),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.18),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _BookmarksStack extends StatefulWidget {
  final List<Map<String, dynamic>> bookmarks;
  const _BookmarksStack({required this.bookmarks});

  @override
  State<_BookmarksStack> createState() => _BookmarksStackState();
}

class _BookmarksStackState extends State<_BookmarksStack> {
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  Widget build(BuildContext context) {
    if (widget.bookmarks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.2),
              ),
              child: Icon(Icons.bookmarks_outlined, color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Bookmarks',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryText),
                  ),
                  Text(
                    'No bookmarks yet. Long press an ayah to save.',
                    style: TextStyle(fontSize: 12, color: AppColors.primaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.bookmarks.length,
        itemBuilder: (context, index) {
          final b = widget.bookmarks[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReadingScreen(initialPage: b['page']),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
                  ],
                ),
                child: Row(
                  children: [
                     Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withOpacity(0.2),
                      ),
                      child: Icon(Icons.bookmark, color: AppColors.gold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          b['surah'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          'Ayah ${b['ayah']}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ... _CardTile class (Same as before) ...
class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return Material(
      color: isDisabled ? Colors.grey.shade100 : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(18),
      elevation: isDisabled ? 0 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isDisabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.grey.shade300
                      : AppColors.accentGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: isDisabled ? Colors.grey : AppColors.accentGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? Colors.grey.shade600
                            : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDisabled
                            ? Colors.grey.shade500
                            : AppColors.primaryText.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDisabled)
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}