import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/app_state.dart';
import 'features/home/home_screen.dart';

class TorontoAiParkingApp extends StatelessWidget {
  const TorontoAiParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E5A46),
      primary: const Color(0xFF0E5A46),
      secondary: const Color(0xFFD7A84A),
      tertiary: const Color(0xFF6A7FDB),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'FaithPark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF6F0E6),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.88),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.92),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      locale: Locale(appState.settingsService.languageCode),
      home: const HomeScreen(),
    );
  }
}
