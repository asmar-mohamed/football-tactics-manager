import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1ED6B0); // neon teal
  static const Color accent = Color(0xFF1ED6B0);
  static const Color bg = Color(0xFF0A1021); // dark navy background
  static const Color card = Color(0xFF0F172A); // slate/dark card
  static const Color cardSoft = Color(0xFF111827);
  static const Color pitchGreen = Color(0xFF186A3B);
  static const Color pitchLight = Color(0xFF1FA25E);
  static const Color navy = Color(0xFF0B1D39);
  static const Color danger = Color(0xFFE55353);

  static ThemeData light() {
    const scaffold = Colors.white;
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
      useMaterial3: true,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardColor: Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
      ),
    );
  }
}
