class LastReadPosition {
  const LastReadPosition({
    required this.surahName,
    required this.ayahNumber,
    required this.mode,
  });

  final String surahName;
  final int ayahNumber;
  final ReadingMode mode;
}

enum ReadingMode {
  arabicOnly,
  arabicWithTranslation,
}

