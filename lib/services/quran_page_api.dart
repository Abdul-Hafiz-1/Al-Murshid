import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranPageApi {
  // CHANGED TO HTTPS to fix Android blocking requests
  static const String _baseUrl = 'https://api.alquran.cloud/v1/page';
  static const String _ayahBaseUrl = 'https://api.alquran.cloud/v1/ayah';

  Future<QuranPageResponse> getPage(int pageNumber) async {
    return _fetchPage(pageNumber, 'quran-uthmani');
  }

  Future<QuranPageResponse> getTranslationPage(int pageNumber) async {
    return _fetchPage(pageNumber, 'en.ahmedraza');
  }

  // NEW: Fetch Audio URL (Mishary Al-Afasy)
  Future<String?> getAyahAudioUrl(int surahNumber, int ayahNumber) async {
    final url = Uri.parse('$_ayahBaseUrl/$surahNumber:$ayahNumber/ar.alafasy');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['audio']; // Returns the MP3 URL
      }
    } catch (e) {
      print("Audio Fetch Error: $e");
    }
    return null;
  }

  Future<QuranPageResponse> _fetchPage(int pageNumber, String edition) async {
    final url = Uri.parse('$_baseUrl/$pageNumber/$edition');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return QuranPageResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// ... Keep existing Models (QuranPageResponse, QuranPageData, etc.) ...
// Ensure QuranAyah has the 'surahNumber' field as defined in previous steps.
class QuranPageResponse {
  final QuranPageData data;
  QuranPageResponse({required this.data});
  factory QuranPageResponse.fromJson(Map<String, dynamic> json) {
    return QuranPageResponse(data: QuranPageData.fromJson(json['data']));
  }
}

class QuranPageData {
  final int number;
  final List<QuranAyah> ayahs;
  QuranPageData({required this.number, required this.ayahs});
  factory QuranPageData.fromJson(Map<String, dynamic> json) {
    return QuranPageData(
      number: json['number'],
      ayahs: (json['ayahs'] as List).map((e) => QuranAyah.fromJson(e)).toList(),
    );
  }
}

class QuranAyah {
  final String text;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final int juz;

  QuranAyah({
    required this.text,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.juz,
  });

  factory QuranAyah.fromJson(Map<String, dynamic> json) {
    final surah = json['surah'] ?? {};
    return QuranAyah(
      text: json['text'],
      numberInSurah: json['numberInSurah'],
      surahNumber: surah['number'] ?? 0,
      surahName: surah['name'] ?? '',
      juz: json['juz'] ?? 0,
    );
  }
}

class QuranSurahRef {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;

  QuranSurahRef({required this.number, required this.name, required this.englishName, required this.numberOfAyahs});

  factory QuranSurahRef.fromJson(Map<String, dynamic> json) {
    return QuranSurahRef(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      numberOfAyahs: json['numberOfAyahs'],
    );
  }
}