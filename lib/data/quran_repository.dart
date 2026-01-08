import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:tarteel/models/quran_models.dart';

/// Loads Quran text from the bundled JSON from quran-json
/// (`quran.json` from [quran-json](https://github.com/risan/quran-json)).
class QuranRepository {
  QuranRepository({this.assetPath = 'assets/quran/quran.json'});

  final String assetPath;

  Future<List<QuranSurah>> getAllSurahs() async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final list = json.decode(jsonStr) as List<dynamic>;
    final surahs = list
        .map((e) => QuranSurah.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return surahs;
  }

  Future<QuranSurah> getSurah(int number) async {
    final surahs = await getAllSurahs();
    return surahs.firstWhere(
      (s) => s.id == number,
      orElse: () => surahs.first,
    );
  }
}

