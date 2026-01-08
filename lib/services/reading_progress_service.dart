import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgressService {
  static const _pageKey = 'last_read_page';
  static const _modeKey = 'reading_mode'; // 0 = Mushaf, 1 = Translation

  /// Load the last read page number (1-604)
  Future<int?> loadLastReadPage() async {
    final prefs = await SharedPreferences.getInstance();
    final page = prefs.getInt(_pageKey);
    return page;
  }

  /// Save the current page number (1-604)
  Future<void> saveLastReadPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) {
      throw ArgumentError('Page number must be between 1 and 604');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pageKey, pageNumber);
  }

  /// Load reading mode preference (false = Mushaf, true = Translation)
  Future<bool> loadReadingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_modeKey) ?? false; // Default to Mushaf mode
  }

  /// Save reading mode preference
  Future<void> saveReadingMode(bool isTranslationMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modeKey, isTranslationMode);
  }
}

