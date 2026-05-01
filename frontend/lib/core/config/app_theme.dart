import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color neonBlue = Color(0xFF00D9FF);
  static const Color neonPurple = Color(0xFF9C27FF);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color darkBackground = Color(0xFF0A0E27);
  static const Color darkSurface = Color(0xFF1E2749);
  static const Color textGrey = Color(0xFF6B7394);

  // Fonts - Using GoogleFonts
  static final String? _headingsFontFamily = GoogleFonts.rajdhani().fontFamily;
  static final String? _bodyFontFamily = GoogleFonts.outfit().fontFamily;

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: _bodyFontFamily,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: neonBlue,
      secondary: neonPurple,
      surface: darkSurface,
      error: neonOrange,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),

    // Typography
    textTheme: GoogleFonts.outfitTextTheme(const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(),
      bodyMedium: TextStyle(),
    )).copyWith(
      displayLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: neonBlue,
        textStyle: TextStyle(
          fontFamily: _headingsFontFamily,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),

    // Input Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonBlue),
      ),
      labelStyle: const TextStyle(
          color: textGrey, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      prefixIconColor: neonBlue,
      contentPadding: const EdgeInsets.all(16),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: _headingsFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  // Fallback / standard light theme (optional, as we seem to be going dark-mode only)
  static final lightTheme = darkTheme;
}
