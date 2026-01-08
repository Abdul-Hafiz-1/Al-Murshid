class QuranAyah {
  const QuranAyah({
    required this.id,
    required this.text,
  });

  final int id; // verse id within surah (from quran-json "id")
  final String text;

  factory QuranAyah.fromMap(Map<String, dynamic> map) {
    return QuranAyah(
      id: map['id'] as int,
      text: map['text'] as String,
    );
  }
}

class QuranSurah {
  const QuranSurah({
    required this.id,
    required this.name,
    required this.transliteration,
    required this.type,
    required this.totalVerses,
    required this.ayahs,
  });

  final int id; // surah number (1-114)
  final String name; // Arabic name
  final String transliteration;
  final String type; // meccan / medinan
  final int totalVerses;
  final List<QuranAyah> ayahs;

  factory QuranSurah.fromMap(Map<String, dynamic> map) {
    final ayahs = (map['verses'] as List<dynamic>)
        .map((e) => QuranAyah.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return QuranSurah(
      id: map['id'] as int,
      name: map['name'] as String,
      transliteration: map['transliteration'] as String,
      type: map['type'] as String,
      totalVerses: map['total_verses'] as int,
      ayahs: ayahs,
    );
  }
}

