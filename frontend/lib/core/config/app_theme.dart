import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rhockai/core/config/design_system.dart';

/// Application theme.
///
/// Single source of truth for colour, type and component styling is
/// [AppDesign] — this file only maps those tokens onto Flutter's
/// [ThemeData]. It deliberately re-declares nothing.
class AppTheme {
  // Backwards-compatible aliases. Prefer AppDesign in new code.
  static const Color neonBlue = AppDesign.electricBlue;
  static const Color neonPurple = AppDesign.neonPurple;
  static const Color purpleText = AppDesign.purpleText;
  static const Color neonGreen = AppDesign.energyGreen;
  static const Color neonOrange = AppDesign.warningOrange;
  static const Color errorRed = AppDesign.errorRed;
  static const Color darkBackground = AppDesign.primaryDark;
  static const Color darkSurface = AppDesign.cardDark;
  static const Color textGrey = AppDesign.textTertiary;
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color cardShadow = Color(0x33000000);

  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: const [
          BoxShadow(
            color: cardShadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration glassDecoration() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(color: glassBorder),
      );

  static ThemeData buildTheme(Color accentColor) {
    final headingFont = GoogleFonts.rajdhani().fontFamily;
    final bodyFont = GoogleFonts.outfit().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppDesign.primaryDark,
      fontFamily: bodyFont,

      colorScheme: ColorScheme.dark(
        primary: accentColor,
        onPrimary: AppDesign.primaryDark,
        secondary: AppDesign.purpleText,
        onSecondary: AppDesign.primaryDark,
        surface: AppDesign.cardDark,
        onSurface: AppDesign.textPrimary,
        surfaceContainerHighest: AppDesign.surfaceDark,
        error: AppDesign.errorRed,
        onError: Colors.white,
        outline: AppDesign.textTertiary,
      ),

      // Typography — Rajdhani for display, Outfit for body.
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontWeight: FontWeight.w700),
          displaySmall: TextStyle(fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
          headlineSmall: TextStyle(fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(),
          bodyMedium: TextStyle(),
          labelSmall: TextStyle(fontSize: 12, letterSpacing: 0.6),
        ),
      ).copyWith(
        displayLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
        displaySmall: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppDesign.primaryDark,
          backgroundColor: accentColor,
          textStyle: TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
        ),
      ),

      // Filled buttons — the M3 default going forward.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          textStyle: TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: AppDesign.textPrimary,
          side: const BorderSide(color: glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDesign.surfaceDark.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesign.space16,
          vertical: AppDesign.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          borderSide: const BorderSide(color: AppDesign.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          borderSide: const BorderSide(color: AppDesign.errorRed, width: 2),
        ),
        // 4.08:1 on the surface used to fail WCAG AA for 12px text.
        labelStyle: const TextStyle(
          color: AppDesign.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          fontSize: 13,
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        prefixIconColor: accentColor,
        suffixIconColor: AppDesign.textSecondary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppDesign.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppDesign.textPrimary),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        space: 1,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppDesign.surfaceDark,
        contentTextStyle: const TextStyle(color: AppDesign.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDesign.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppDesign.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        ),
      ),

      // Dialogs and sheets read better with a readable scrim on dark UI.
      // (Kept subtle so content stays the focus.)
    );
  }

  static final lightTheme = buildTheme(AppDesign.electricBlue);
}