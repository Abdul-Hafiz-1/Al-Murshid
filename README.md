# Al-Murshid - Quranic Recitation Practice App

A Flutter application for learning Quranic recitation with real-time feedback and tajweed guidance.

## 🎯 Features

### Core Functionality
- 📖 Complete Quranic text with Uthmanic script
- 🎤 Real-time recitation recognition
- 🎵 Reference audio for each ayah
- 📊 Progress tracking and statistics
- ✅ Word-by-word validation
- 🔄 Auto-advancement on correct recitation

### Recent Enhancements (v2.0) ✨
- 🔄 **RTL Swipe Navigation** - Proper Arabic right-to-left swiping
- 🔢 **Ayah Numbers** - Large Islamic markers and word numbering
- 🎯 **Direct Navigation** - Grid view to jump to any ayah
- ✔️ **Fixed Recognition** - 'Rahman' and 20+ variants now recognized
- 📢 **Real-time Feedback** - Status display, progress bar, word hints
- 🎛️ **Enhanced Controls** - Reset and replay buttons added
- 🌈 **Tajweed Colors** - Visual letter categorization system
- 📖 **Pronunciation Guides** - Long-press for harakat info
- 🧠 **Smart Recognition** - Improved matching algorithm
- 📈 **Progress Tracking** - Visual feedback during practice

### Educational Features
- 🌈 Tajweed rule visualization with color coding
- 📱 Long-press for pronunciation guides for every Arabic letter
- 📚 Harakat (diacritical mark) information
- 🎓 Sun and Moon letter categorization
- 💡 Emphasis and intonation guidance

## 📋 Getting Started

### Prerequisites
- Flutter SDK (3.10.4+)
- Android SDK or iOS SDK
- Microphone permission required

### Installation

1. Clone the repository
```bash
git clone [repository-url]
cd Al-Murshid
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## 📚 Documentation

### For Users:
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick start guide (1 page)
- **[RECITATION_IMPROVEMENTS.md](RECITATION_IMPROVEMENTS.md)** - Complete feature guide
- **[DELIVERY_SUMMARY.md](DELIVERY_SUMMARY.md)** - What was improved

### For Developers:
- **[IMPROVEMENTS_SUMMARY.md](IMPROVEMENTS_SUMMARY.md)** - Technical implementation details
- **[CHANGELOG.md](CHANGELOG.md)** - All changes and version history

### Quick Navigation:
- 🎯 **Start Here**: [DELIVERY_SUMMARY.md](DELIVERY_SUMMARY.md) - 5 min overview
- 📖 **Learn Features**: [RECITATION_IMPROVEMENTS.md](RECITATION_IMPROVEMENTS.md) - 15 min guide
- ⚡ **Quick Tips**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - 2 page cheat sheet
- 🛠️ **Technical**: [IMPROVEMENTS_SUMMARY.md](IMPROVEMENTS_SUMMARY.md) - Developer reference

## 🎮 How to Use

### Basic Recitation Practice
1. Open the app and navigate to Recitation Practice
2. Tap the **Green Mic button** to start
3. Speak each word clearly
4. Watch for **Green** (correct) or **Red** (incorrect) feedback
5. Use **Reset** (purple) to try again
6. **Next** (black) to go to next ayah

### Learn Tajweed
1. Find "**Tajweed Rules Off**" button in the ayah header
2. Click to enable **color-coded letters**
3. **Long-press any word** for pronunciation guide
4. See detailed tajweed rules and letter analysis

### Quick Navigation
1. Tap **Surah name** button
2. Select "**Ayahs**" tab
3. **Click grid** to jump to any ayah

## 🔧 Project Structure

```
lib/
├── screens/
│   ├── recitation_practice_screen.dart    (Main feature - v2.0 enhanced)
│   ├── home_options_screen.dart
│   ├── reading_screen.dart
│   └── ...
├── services/
│   ├── quran_page_api.dart
│   ├── tajweed_service.dart              (NEW - Tajweed rules)
│   └── reading_progress_service.dart
├── models/
│   ├── quran_models.dart
│   ├── last_read_position.dart
│   └── ...
├── providers/
│   └── app_providers.dart               (Updated with tajweed prefs)
├── theme/
│   └── app_theme.dart
└── data/
    ├── quran_data.dart
    ├── quran_repository.dart
    └── ...
```

## 🚀 Key Features in Detail

### RTL Navigation (v2.0)
- Swipe **left** → Next ayah
- Swipe **right** → Previous ayah
- First ayah on **left** side, last ayah on **right** side

### Fixed Rahman Recognition (v2.0)
- ✅ الرحمن (Uthmanic with alif)
- ✅ الرحمان (Standard with alif)
- ✅ رحمٰن (With superscript alif)
- All recognized as same word!

### Enhanced Microphone System (v2.0)
- 📢 Real-time status display
- 📊 Progress bar showing completion
- 💡 Word hints showing next word
- ⚠️ Clear error messages

### Tajweed Colors (v2.0)
- 🔵 **Blue** - Sun Letters (شمسية)
- 🟣 **Purple** - Moon Letters (قمرية)
- 🔴 **Red** - Tafkheem (Emphasis)
- 🟠 **Orange** - Noon & Meem
- 🟢 **Green** - Ya & Waw

## 🐛 Troubleshooting

### Recognition Issues
- Check microphone permissions
- Ensure clear speech input
- Refer to [QUICK_REFERENCE.md](QUICK_REFERENCE.md#-common-issues--fixes)

### "Rahman" Not Working?
- Should be fixed in v2.0!
- See [RECITATION_IMPROVEMENTS.md](RECITATION_IMPROVEMENTS.md#what-if-rahman-still-shows-wrong)

### Audio Not Playing
- Check device volume
- Verify audio permissions
- Try tapping Play button (orange)

For more help, see documentation files above.

## 📊 What's New in v2.0

10 major improvements including:
- Better swiping (proper RTL)
- Clear ayah numbering
- Fixed 'Rahman' recognition
- Real-time mic feedback
- Tajweed color visualization
- Pronunciation guides
- Enhanced controls
- Progress tracking
- Better error messages
- Smart word recognition

See [DELIVERY_SUMMARY.md](DELIVERY_SUMMARY.md) for complete details!

## 🎓 Learning Resources

- [Tajweed Service Documentation](lib/services/tajweed_service.dart)
- [Recitation Practice Screen](lib/screens/recitation_practice_screen.dart)
- [Feature Guides](RECITATION_IMPROVEMENTS.md)

## 🤝 Contributing

Contributions welcome! Please refer to the code documentation and feature guides.

## 📜 License

This project is part of Al-Murshid (The Guide) - Quranic learning application.

## 🙏 Acknowledgments

- Quranic text: Uthmanic Script
- Audio: Quranic recitation references
- Technology: Flutter, Dart, Google Speech-to-Text

---

**Latest Version**: 2.0 (January 2026)  
**Status**: ✅ Production Ready  
**Improvements**: 10 Major Features  
**Documentation**: ✅ Complete  

For detailed information, start with [DELIVERY_SUMMARY.md](DELIVERY_SUMMARY.md)!
