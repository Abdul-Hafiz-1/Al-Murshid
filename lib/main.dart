import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarteel/screens/splash_screen.dart';
import 'package:tarteel/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force light mode status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(
    const ProviderScope( // Add this wrapper
      child: AlMurshidApp(),
    ),
  );
}

class AlMurshidApp extends StatelessWidget {
  const AlMurshidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al-Murshid',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark, // Use dark assistant UI
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
