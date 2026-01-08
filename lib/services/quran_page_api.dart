import 'dart:convert';
import 'package:http/http.dart' as http;

/// API service to fetch Quran pages from alquran.cloud
class QuranPageApi {
  static const String baseUrl = 'http://api.alquran.cloud/v1/page';

  /// Fetch a single page (1-604) in Uthmani script
  Future<QuranPageResponse> getPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) {
      throw ArgumentError('Page number must be between 1 and 604');
    }

    try {
      final url = Uri.parse('$baseUrl/$pageNumber/quran-uthmani');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return QuranPageResponse.fromJson(json);
      } else {
        throw Exception(
            'Failed to load page $pageNumber: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to Quran API: $e');
    }
  }
}

class QuranPageResponse {
  final int code;
  final String status;
  final QuranPageData data;

  QuranPageResponse({
    required this.code,
    required this.status,
    required this.data,
  });

  factory QuranPageResponse.fromJson(Map<String, dynamic> json) {
    return QuranPageResponse(
      code: json['code'] as int,
      status: json['status'] as String,
      data: QuranPageData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class QuranPageData {
  final int number;
  final List<QuranAyahData> ayahs;
  final List<QuranSurahReference> surahs;

  QuranPageData({
    required this.number,
    required this.ayahs,
    required this.surahs,
  });

  factory QuranPageData.fromJson(Map<String, dynamic> json) {
    // Parse Surahs map: {"1": {...}, "2": {...}} -> List<QuranSurahReference>
    final surahsMap = json['surahs'] as Map<String, dynamic>;
    final surahsList = surahsMap.values
        .map((e) => QuranSurahReference.fromJson(e as Map<String, dynamic>))
        .toList();

    // Sort by surah number to ensure correct order
    surahsList.sort((a, b) => a.number.compareTo(b.number));

    return QuranPageData(
      number: json['number'] as int,
      ayahs: (json['ayahs'] as List<dynamic>)
          .map((e) => QuranAyahData.fromJson(e as Map<String, dynamic>))
          .toList(),
      surahs: surahsList,
    );
  }
}

class QuranAyahData {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;

  QuranAyahData({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.sajda,
  });

  factory QuranAyahData.fromJson(Map<String, dynamic> json) {
    return QuranAyahData(
      number: json['number'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      juz: json['juz'] as int,
      manzil: json['manzil'] as int,
      page: json['page'] as int,
      ruku: json['ruku'] as int,
      hizbQuarter: json['hizbQuarter'] as int,
      sajda: json['sajda'] as bool? ?? false,
    );
  }
}

class QuranSurahReference {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  QuranSurahReference({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory QuranSurahReference.fromJson(Map<String, dynamic> json) {
    return QuranSurahReference(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String,
    );
  }
}