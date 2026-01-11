import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranPageApi {
  static const String _baseUrl = 'http://api.alquran.cloud/v1/page';

  Future<QuranPageResponse> getPage(int pageNumber) async {
    return _fetchPage(pageNumber, 'quran-uthmani');
  }

  Future<QuranPageResponse> getTranslationPage(int pageNumber) async {
    // 'en.ahmedraza' is the specific identifier for Kanz-ul-Iman
    return _fetchPage(pageNumber, 'en.ahmedraza');
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