// lib/data/quran_data.dart

class QuranData {
  static int getSurahForPage(int pageNumber) {
    // Find the last surah that starts on or before this page
    final surah = allSurahs.lastWhere(
      (s) => (s['page'] as int) <= pageNumber,
      orElse: () => allSurahs.first,
    );
    return surah['number'] as int;
  }

  static Map<String, dynamic> getPageData(int pageNumber) {
    // Returns the first ayah of the page to scroll to
    // Simple logic: If we are at the start of a surah, return ayah 1.
    // Otherwise, we approximate or return 1 (Perfect sync requires a heavier database).
    return {'surah': getSurahForPage(pageNumber), 'start': 1};
  }

  static int getPageForSurahAndAyah(int surahNumber, int ayahNumber) {
    // Get the starting page of the surah
    if (surahNumber < 1 || surahNumber > 114) {
      return 1;
    }
    
    final surah = allSurahs[surahNumber - 1]; // Convert to 0-indexed
    int startPage = surah['page'] as int;
    
    // Estimate additional pages based on ayah position
    // This is a rough estimate assuming ~15 ayahs per page on average
    // Fine-tuning based on surah lengths for better accuracy
    final surahAyahs = surah['ayahs'] as int;
    if (ayahNumber <= surahAyahs) {
      int estimatedAdditionalPages = (ayahNumber - 1) ~/ 15;
      return startPage + estimatedAdditionalPages;
    }
    
    return startPage;
  }

  // Complete List of 114 Surahs with Search Metadata
  static final List<Map<String, dynamic>> allSurahs = [
    {"number": 1, "name": "سورة الفاتحة", "english": "The Opening", "transliteration": "Al-Fatiha", "page": 1, "ayahs": 7},
    {"number": 2, "name": "سورة البقرة", "english": "The Cow", "transliteration": "Al-Baqarah", "page": 2, "ayahs": 286},
    {"number": 3, "name": "سورة آل عمران", "english": "Family of Imran", "transliteration": "Ali 'Imran", "page": 50, "ayahs": 200},
    {"number": 4, "name": "سورة النساء", "english": "The Women", "transliteration": "An-Nisa", "page": 77, "ayahs": 176},
    {"number": 5, "name": "سورة المائدة", "english": "The Table Spread", "transliteration": "Al-Ma'idah", "page": 106, "ayahs": 120},
    {"number": 6, "name": "سورة الأنعام", "english": "The Cattle", "transliteration": "Al-An'am", "page": 128, "ayahs": 165},
    {"number": 7, "name": "سورة الأعراف", "english": "The Heights", "transliteration": "Al-A'raf", "page": 151, "ayahs": 206},
    {"number": 8, "name": "سورة الأنفال", "english": "The Spoils of War", "transliteration": "Al-Anfal", "page": 177, "ayahs": 75},
    {"number": 9, "name": "سورة التوبة", "english": "The Repentance", "transliteration": "At-Tawbah", "page": 187, "ayahs": 129},
    {"number": 10, "name": "سورة يونس", "english": "Jonah", "transliteration": "Yunus", "page": 208, "ayahs": 109},
    {"number": 11, "name": "سورة هود", "english": "Hud", "transliteration": "Hud", "page": 221, "ayahs": 123},
    {"number": 12, "name": "سورة يوسف", "english": "Joseph", "transliteration": "Yusuf", "page": 235, "ayahs": 111},
    {"number": 13, "name": "سورة الرعد", "english": "The Thunder", "transliteration": "Ar-Ra'd", "page": 249, "ayahs": 43},
    {"number": 14, "name": "سورة إبراهيم", "english": "Abraham", "transliteration": "Ibrahim", "page": 255, "ayahs": 52},
    {"number": 15, "name": "سورة الحجر", "english": "The Rocky Tract", "transliteration": "Al-Hijr", "page": 262, "ayahs": 99},
    {"number": 16, "name": "سورة النحل", "english": "The Bee", "transliteration": "An-Nahl", "page": 267, "ayahs": 128},
    {"number": 17, "name": "سورة الإسراء", "english": "The Night Journey", "transliteration": "Al-Isra", "page": 282, "ayahs": 111},
    {"number": 18, "name": "سورة الكهف", "english": "The Cave", "transliteration": "Al-Kahf", "page": 293, "ayahs": 110},
    {"number": 19, "name": "سورة مريم", "english": "Mary", "transliteration": "Maryam", "page": 305, "ayahs": 98},
    {"number": 20, "name": "سورة طه", "english": "Ta-Ha", "transliteration": "Ta-Ha", "page": 312, "ayahs": 135},
    {"number": 21, "name": "سورة الأنبياء", "english": "The Prophets", "transliteration": "Al-Anbiya", "page": 322, "ayahs": 112},
    {"number": 22, "name": "سورة الحج", "english": "The Pilgrimage", "transliteration": "Al-Hajj", "page": 332, "ayahs": 78},
    {"number": 23, "name": "سورة المؤمنون", "english": "The Believers", "transliteration": "Al-Mu'minun", "page": 342, "ayahs": 118},
    {"number": 24, "name": "سورة النور", "english": "The Light", "transliteration": "An-Nur", "page": 350, "ayahs": 64},
    {"number": 25, "name": "سورة الفرقان", "english": "The Criterian", "transliteration": "Al-Furqan", "page": 359, "ayahs": 77},
    {"number": 26, "name": "سورة الشعراء", "english": "The Poets", "transliteration": "Ash-Shu'ara", "page": 367, "ayahs": 227},
    {"number": 27, "name": "سورة النمل", "english": "The Ant", "transliteration": "An-Naml", "page": 377, "ayahs": 93},
    {"number": 28, "name": "سورة القصص", "english": "The Stories", "transliteration": "Al-Qasas", "page": 385, "ayahs": 88},
    {"number": 29, "name": "سورة العنكبوت", "english": "The Spider", "transliteration": "Al-Ankabut", "page": 396, "ayahs": 69},
    {"number": 30, "name": "سورة الروم", "english": "The Romans", "transliteration": "Ar-Rum", "page": 404, "ayahs": 60},
    {"number": 31, "name": "سورة لقمان", "english": "Luqman", "transliteration": "Luqman", "page": 411, "ayahs": 34},
    {"number": 32, "name": "سورة السجدة", "english": "The Prostration", "transliteration": "As-Sajdah", "page": 415, "ayahs": 30},
    {"number": 33, "name": "سورة الأحزاب", "english": "The Combined Forces", "transliteration": "Al-Ahzab", "page": 418, "ayahs": 73},
    {"number": 34, "name": "سورة سبأ", "english": "Sheba", "transliteration": "Saba", "page": 428, "ayahs": 54},
    {"number": 35, "name": "سورة فاطر", "english": "Originator", "transliteration": "Fatir", "page": 434, "ayahs": 45},
    {"number": 36, "name": "سورة يس", "english": "Ya Sin", "transliteration": "Ya-Sin", "page": 440, "ayahs": 83},
    {"number": 37, "name": "سورة الصافات", "english": "Those who set the Ranks", "transliteration": "As-Saffat", "page": 446, "ayahs": 182},
    {"number": 38, "name": "سورة ص", "english": "The Letter \"Saad\"", "transliteration": "Sad", "page": 453, "ayahs": 88},
    {"number": 39, "name": "سورة الزمر", "english": "The Troops", "transliteration": "Az-Zumar", "page": 458, "ayahs": 75},
    {"number": 40, "name": "سورة غافر", "english": "The Forgiver", "transliteration": "Ghafir", "page": 467, "ayahs": 85},
    {"number": 41, "name": "سورة فصلت", "english": "Explained in Detail", "transliteration": "Fussilat", "page": 477, "ayahs": 54},
    {"number": 42, "name": "سورة الشورى", "english": "The Consultation", "transliteration": "Ash-Shura", "page": 483, "ayahs": 53},
    {"number": 43, "name": "سورة الزخرف", "english": "The Ornaments of Gold", "transliteration": "Az-Zukhruf", "page": 489, "ayahs": 89},
    {"number": 44, "name": "سورة الدخان", "english": "The Smoke", "transliteration": "Ad-Dukhan", "page": 496, "ayahs": 59},
    {"number": 45, "name": "سورة الجاثية", "english": "The Crouching", "transliteration": "Al-Jathiyah", "page": 499, "ayahs": 37},
    {"number": 46, "name": "سورة الأحقاف", "english": "The Wind-Curved Sandhills", "transliteration": "Al-Ahqaf", "page": 502, "ayahs": 35},
    {"number": 47, "name": "سورة محمد", "english": "Muhammad", "transliteration": "Muhammad", "page": 507, "ayahs": 38},
    {"number": 48, "name": "سورة الفتح", "english": "The Victory", "transliteration": "Al-Fath", "page": 511, "ayahs": 29},
    {"number": 49, "name": "سورة الحجرات", "english": "The Rooms", "transliteration": "Al-Hujurat", "page": 515, "ayahs": 18},
    {"number": 50, "name": "سورة ق", "english": "The Letter \"Qaf\"", "transliteration": "Qaf", "page": 518, "ayahs": 45},
    {"number": 51, "name": "سورة الذاريات", "english": "The Winnowing Winds", "transliteration": "Ad-Dhariyat", "page": 520, "ayahs": 60},
    {"number": 52, "name": "سورة الطور", "english": "The Mount", "transliteration": "At-Tur", "page": 523, "ayahs": 49},
    {"number": 53, "name": "سورة النجم", "english": "The Star", "transliteration": "An-Najm", "page": 526, "ayahs": 62},
    {"number": 54, "name": "سورة القمر", "english": "The Moon", "transliteration": "Al-Qamar", "page": 528, "ayahs": 55},
    {"number": 55, "name": "سورة الرحمن", "english": "The Beneficent", "transliteration": "Ar-Rahman", "page": 531, "ayahs": 78},
    {"number": 56, "name": "سورة الواقعة", "english": "The Inevitable", "transliteration": "Al-Waqi'ah", "page": 534, "ayahs": 96},
    {"number": 57, "name": "سورة الحديد", "english": "The Iron", "transliteration": "Al-Hadid", "page": 537, "ayahs": 29},
    {"number": 58, "name": "سورة المجادلة", "english": "The Pleading Woman", "transliteration": "Al-Mujadila", "page": 542, "ayahs": 22},
    {"number": 59, "name": "سورة الحشر", "english": "The Exile", "transliteration": "Al-Hashr", "page": 545, "ayahs": 24},
    {"number": 60, "name": "سورة الممتحنة", "english": "She that is to be examined", "transliteration": "Al-Mumtahanah", "page": 549, "ayahs": 13},
    {"number": 61, "name": "سورة الصف", "english": "The Ranks", "transliteration": "As-Saff", "page": 551, "ayahs": 14},
    {"number": 62, "name": "سورة الجمعة", "english": "The Congregation, Friday", "transliteration": "Al-Jumu'ah", "page": 553, "ayahs": 11},
    {"number": 63, "name": "سورة المنافقون", "english": "The Hypocrites", "transliteration": "Al-Munafiqun", "page": 554, "ayahs": 11},
    {"number": 64, "name": "سورة التغابن", "english": "The Mutual Disillusion", "transliteration": "At-Taghabun", "page": 556, "ayahs": 18},
    {"number": 65, "name": "سورة الطلاق", "english": "The Divorce", "transliteration": "At-Talaq", "page": 558, "ayahs": 12},
    {"number": 66, "name": "سورة التحريم", "english": "The Prohibition", "transliteration": "At-Tahrim", "page": 560, "ayahs": 12},
    {"number": 67, "name": "سورة الملك", "english": "The Sovereignty", "transliteration": "Al-Mulk", "page": 562, "ayahs": 30},
    {"number": 68, "name": "سورة القلم", "english": "The Pen", "transliteration": "Al-Qalam", "page": 564, "ayahs": 52},
    {"number": 69, "name": "سورة الحاقة", "english": "The Reality", "transliteration": "Al-Haqqah", "page": 566, "ayahs": 52},
    {"number": 70, "name": "سورة المعارج", "english": "The Ascending Stairways", "transliteration": "Al-Ma'arij", "page": 568, "ayahs": 44},
    {"number": 71, "name": "سورة نوح", "english": "Noah", "transliteration": "Nuh", "page": 570, "ayahs": 28},
    {"number": 72, "name": "سورة الجن", "english": "The Jinn", "transliteration": "Al-Jinn", "page": 572, "ayahs": 28},
    {"number": 73, "name": "سورة المزمل", "english": "The Enshrouded One", "transliteration": "Al-Muzzammil", "page": 574, "ayahs": 20},
    {"number": 74, "name": "سورة المدثر", "english": "The Cloaked One", "transliteration": "Al-Muddaththir", "page": 575, "ayahs": 56},
    {"number": 75, "name": "سورة القيامة", "english": "The Resurrection", "transliteration": "Al-Qiyamah", "page": 577, "ayahs": 40},
    {"number": 76, "name": "سورة الإنسان", "english": "The Man", "transliteration": "Al-Insan", "page": 578, "ayahs": 31},
    {"number": 77, "name": "سورة المرسلات", "english": "The Emissaries", "transliteration": "Al-Mursalat", "page": 580, "ayahs": 50},
    {"number": 78, "name": "سورة النبأ", "english": "The Tidings", "transliteration": "An-Naba", "page": 582, "ayahs": 40},
    {"number": 79, "name": "سورة النازعات", "english": "Those who drag forth", "transliteration": "An-Nazi'at", "page": 583, "ayahs": 46},
    {"number": 80, "name": "سورة عبس", "english": "He Frowned", "transliteration": "Abasa", "page": 585, "ayahs": 42},
    {"number": 81, "name": "سورة التكوير", "english": "The Overthrowing", "transliteration": "At-Takwir", "page": 586, "ayahs": 29},
    {"number": 82, "name": "سورة الانفطار", "english": "The Cleaving", "transliteration": "Al-Infitar", "page": 587, "ayahs": 19},
    {"number": 83, "name": "سورة المطففين", "english": "The Defrauding", "transliteration": "Al-Mutaffifin", "page": 587, "ayahs": 36},
    {"number": 84, "name": "سورة الانشقاق", "english": "The Sundering", "transliteration": "Al-Inshiqaq", "page": 589, "ayahs": 25},
    {"number": 85, "name": "سورة البروج", "english": "The Mansions of the Stars", "transliteration": "Al-Buruj", "page": 590, "ayahs": 22},
    {"number": 86, "name": "سورة الطارق", "english": "The Morning Star", "transliteration": "At-Tariq", "page": 591, "ayahs": 17},
    {"number": 87, "name": "سورة الأعلى", "english": "The Most High", "transliteration": "Al-A'la", "page": 591, "ayahs": 19},
    {"number": 88, "name": "سورة الغاشية", "english": "The Overwhelming", "transliteration": "Al-Ghashiyah", "page": 592, "ayahs": 26},
    {"number": 89, "name": "سورة الفجر", "english": "The Dawn", "transliteration": "Al-Fajr", "page": 593, "ayahs": 30},
    {"number": 90, "name": "سورة البلد", "english": "The City", "transliteration": "Al-Balad", "page": 594, "ayahs": 20},
    {"number": 91, "name": "سورة الشمس", "english": "The Sun", "transliteration": "Ash-Shams", "page": 595, "ayahs": 15},
    {"number": 92, "name": "سورة الليل", "english": "The Night", "transliteration": "Al-Layl", "page": 595, "ayahs": 21},
    {"number": 93, "name": "سورة الضحى", "english": "The Morning Hours", "transliteration": "Ad-Duha", "page": 596, "ayahs": 11},
    {"number": 94, "name": "سورة الشرح", "english": "The Relief", "transliteration": "Ash-Sharh", "page": 596, "ayahs": 8},
    {"number": 95, "name": "سورة التين", "english": "The Fig", "transliteration": "At-Tin", "page": 597, "ayahs": 8},
    {"number": 96, "name": "سورة العلق", "english": "The Clot", "transliteration": "Al-'Alaq", "page": 597, "ayahs": 19},
    {"number": 97, "name": "سورة القدر", "english": "The Power", "transliteration": "Al-Qadr", "page": 598, "ayahs": 5},
    {"number": 98, "name": "سورة البينة", "english": "The Clear Proof", "transliteration": "Al-Bayyinah", "page": 598, "ayahs": 8},
    {"number": 99, "name": "سورة الزلزلة", "english": "The Earthquake", "transliteration": "Az-Zalzalah", "page": 599, "ayahs": 8},
    {"number": 100, "name": "سورة العاديات", "english": "The Courser", "transliteration": "Al-'Adiyat", "page": 599, "ayahs": 11},
    {"number": 101, "name": "سورة القارعة", "english": "The Calamity", "transliteration": "Al-Qari'ah", "page": 600, "ayahs": 11},
    {"number": 102, "name": "سورة التكاثر", "english": "The Rivalry in world increase", "transliteration": "At-Takathur", "page": 600, "ayahs": 8},
    {"number": 103, "name": "سورة العصر", "english": "The Declining Day", "transliteration": "Al-'Asr", "page": 601, "ayahs": 3},
    {"number": 104, "name": "سورة الهمزة", "english": "The Traducer", "transliteration": "Al-Humazah", "page": 601, "ayahs": 9},
    {"number": 105, "name": "سورة الفيل", "english": "The Elephant", "transliteration": "Al-Fil", "page": 601, "ayahs": 5},
    {"number": 106, "name": "سورة قريش", "english": "Quraysh", "transliteration": "Quraysh", "page": 602, "ayahs": 4},
    {"number": 107, "name": "سورة الماعون", "english": "The Small Kindnesses", "transliteration": "Al-Ma'un", "page": 602, "ayahs": 7},
    {"number": 108, "name": "سورة الكوثر", "english": "The Abundance", "transliteration": "Al-Kawthar", "page": 602, "ayahs": 3},
    {"number": 109, "name": "سورة الكافرون", "english": "The Disbelievers", "transliteration": "Al-Kafirun", "page": 603, "ayahs": 6},
    {"number": 110, "name": "سورة النصر", "english": "The Divine Support", "transliteration": "An-Nasr", "page": 603, "ayahs": 3},
    {"number": 111, "name": "سورة المسد", "english": "The Palm Fiber", "transliteration": "Al-Masad", "page": 603, "ayahs": 5},
    {"number": 112, "name": "سورة الإخلاص", "english": "The Sincerity", "transliteration": "Al-Ikhlas", "page": 604, "ayahs": 4},
    {"number": 113, "name": "سورة الفلق", "english": "The Daybreak", "transliteration": "Al-Falaq", "page": 604, "ayahs": 5},
    {"number": 114, "name": "سورة الناس", "english": "Mankind", "transliteration": "An-Nas", "page": 604, "ayahs": 6}
  ];
}