import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Settings Provider (Translation Mode, etc.)
class SettingsNotifier extends StateNotifier<bool> {
  SettingsNotifier() : super(false) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isTranslationMode') ?? false;
  }

  Future<void> toggleTranslation() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isTranslationMode', state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, bool>((ref) {
  return SettingsNotifier();
});

// 2. Last Read Page Provider
class LastReadNotifier extends StateNotifier<int> {
  LastReadNotifier() : super(1) {
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('lastReadPage') ?? 1;
  }

  Future<void> setLastRead(int page) async {
    state = page;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastReadPage', page);
  }
}

final lastReadProvider = StateNotifierProvider<LastReadNotifier, int>((ref) {
  return LastReadNotifier();
});

// 3. Bookmarks Provider
class BookmarksNotifier extends StateNotifier<List<int>> {
  BookmarksNotifier() : super([]) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('bookmarks') ?? [];
    state = list.map((e) => int.parse(e)).toList();
  }

  Future<void> toggleBookmark(int page) async {
    final prefs = await SharedPreferences.getInstance();
    if (state.contains(page)) {
      state = [
        ...state.where((element) => element != page)
      ]; // Remove
    } else {
      state = [...state, page]; // Add
    }
    prefs.setStringList('bookmarks', state.map((e) => e.toString()).toList());
  }
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, List<int>>((ref) {
  return BookmarksNotifier();
});