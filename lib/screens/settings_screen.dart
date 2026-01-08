import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.primaryText),
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Al-Murshid'),
                subtitle: const Text('Version 1.0.0'),
                leading: Icon(
                  Icons.info_outline,
                  color: AppColors.accentGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
