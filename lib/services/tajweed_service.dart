import 'package:flutter/material.dart';

/// Tajweed Rules Service
/// 
/// This service provides tajweed rules for Quranic recitation.
/// It helps highlight different tajweed rules and characteristics in the text.

class TajweedService {
  // Harakat (Vowels)
  static const String fatha = '\u064E';    // َ
  static const String damma = '\u064F';    // ُ
  static const String kasra = '\u0650';    // ِ
  static const String sukun = '\u0652';    // ْ
  static const String shadda = '\u0651';   // ّ
  static const String tanwin = '\u064B\u064C\u064D'; // ٌ ٍ ً

  // Letter analysis
  static bool isHamza(String char) => char == 'ء';
  static bool isSunLetter(String char) => 'تثجدذزسشصضطظلن'.contains(char);
  static bool isQamarLetter(String char) => 'أبحخعغفقكم'.contains(char);
  static bool isYaAndWaw(String char) => 'يو'.contains(char);

  /// Get tajweed color for a character based on rules
  static Color getTajweedColor(String char) {
    if (isSunLetter(char)) {
      return Colors.blue; // Sun letters (Al-Huruf ash-Shamsiyyah)
    }
    if (isQamarLetter(char)) {
      return Colors.purple; // Moon letters (Al-Huruf al-Qamariyyah)
    }
    if (char == 'ن' || char == 'م') {
      return Colors.orange; // Noon and Meem for Ikhfa and Idgham
    }
    if (char == 'ر') {
      return Colors.red; // Ra (Tafkheem)
    }
    if (isYaAndWaw(char)) {
      return Colors.green; // Ya and Waw
    }
    return Colors.black; // Default
  }

  /// Get tajweed rule name
  static String getTajweedRule(String char) {
    if (isSunLetter(char)) {
      return 'Sun Letter (شمسية)';
    }
    if (isQamarLetter(char)) {
      return 'Moon Letter (قمرية)';
    }
    if (char == 'ر') {
      return 'Tafkheem (تفخيم)';
    }
    return 'Standard';
  }

  /// Extract harakats from word
  static String extractHarakats(String word) {
    return word.replaceAll(RegExp(r'[^\u064B-\u065F\u0670]'), '');
  }

  /// Check if word has specific harakat
  static bool hasHarakat(String word, String harakat) {
    return word.contains(harakat);
  }

  /// Get harakat name
  static String getHarakatName(String harakat) {
    switch (harakat) {
      case fatha:
        return 'Fatha (فتحة)';
      case damma:
        return 'Damma (ضمة)';
      case kasra:
        return 'Kasra (كسرة)';
      case sukun:
        return 'Sukun (سكون)';
      case shadda:
        return 'Shadda (شدة)';
      default:
        return 'Unknown';
    }
  }

  /// Normalize word for display with tajweed highlights
  static String normalizeForDisplay(String word) {
    // Remove only processing diacritics, keep display diacritics
    return word
        .replaceAll('ٱ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }

  /// Analyze word for tajweed features
  static Map<String, dynamic> analyzeWord(String word) {
    return {
      'original': word,
      'normalized': normalizeForDisplay(word),
      'harakats': extractHarakats(word),
      'hasShadda': word.contains(shadda),
      'hasTanwin': word.contains(RegExp(r'[\u064B\u064C\u064D]')),
      'hasHamza': word.contains('ء'),
      'letters': word.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '').split(''),
    };
  }

  /// Get reading guide for difficult letters
  static String getReadingGuide(String letter) {
    final guides = {
      'ع': 'Ayn - Pharyngeal sound, deep and guttural',
      'غ': 'Ghayn - Similar to Ayn but softer, from nasal cavity',
      'خ': 'Khah - Like German "ch" sound',
      'ق': 'Qaf - From deep throat, emphatic',
      'ح': 'Ha - Emphatic, from throat',
      'ه': 'Ha - Light, from throat',
      'ش': 'Sheen - Like English "sh"',
      'ص': 'Sad - Emphatic "s"',
      'س': 'Seen - Like English "s"',
      'ض': 'Dad - Emphatic "d"',
      'د': 'Dal - Like English "d"',
      'ط': 'Tah - Emphatic "t"',
      'ت': 'Ta - Like English "t"',
      'ظ': 'Zah - Emphatic "z"',
      'ز': 'Zay - Like English "z"',
      'ر': 'Ra - Rolled "r"',
      'ل': 'Lam - Like English "l", but deeper in Quranic recitation',
      'ن': 'Noon - Like English "n"',
      'م': 'Meem - Like English "m"',
      'ف': 'Fa - Like English "f"',
      'ب': 'Ba - Like English "b"',
      'ء': 'Hamza - Glottal stop, no sound',
      'ي': 'Ya - Like English "y"',
      'و': 'Waw - Like English "w"',
      'ك': 'Kaf - Like English "k"',
      'ج': 'Jeem - Like English "j"',
      'ث': 'Tha - Like English "th"',
      'ذ': 'Dhal - Like English "th" (voiced)',
    };
    return guides[letter] ?? 'No guide available';
  }
}
