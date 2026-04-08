import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HUSH Design System — matching the web app's CSS tokens
class HushColors {
  // Background
  static const bgPrimary = Color(0xFF0A0E17);
  static const bgSecondary = Color(0xFF111827);
  static const bgCard = Color(0xD9141B2D); // rgba(20, 27, 45, 0.85)
  static const bgCardHover = Color(0xE61E2841); // rgba(30, 40, 65, 0.9)
  static const bgGlass = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
  static const bgOverlay = Color(0x99000000); // rgba(0,0,0,0.6)

  // Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  static const textAccent = Color(0xFF67E8F9);

  // Light Mode Colors
  static const bgPrimaryLight = Color(0xFFF8FAFC); // Slate 50
  static const bgSecondaryLight = Color(0xFFF1F5F9); // Slate 100
  static const bgCardLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const textSecondaryLight = Color(0xFF475569); // Slate 600
  static const borderLightMode = Color(0xFFE2E8F0); // Slate 200

  // Brand gradient colors
  static const gradientCyan = Color(0xFF67E8F9);
  static const gradientBlue = Color(0xFF4A9EFF);
  static const gradientPurple = Color(0xFFA855F7);
  static const gradientPink = Color(0xFFEC4899);
  static const gradientOrange = Color(0xFFF97316);
  static const gradientYellow = Color(0xFFFBBF24);

  // Borders (Dark Mode)
  static const borderSubtle = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const borderLight = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
  static const borderAccent = Color(0x4D67E8F9); // rgba(103,232,249,0.3)

  // Tier colors
  static const tierGray = Color(0xFF8B8B8B);
  static const tierBlue = Color(0xFF4A9EFF);
  static const tierGreen = Color(0xFF34D399);
  static const tierYellow = Color(0xFFFBBF24);
  static const tierOrange = Color(0xFFF97316);
  static const tierRed = Color(0xFFEF4444);
  static const tierPurple = Color(0xFFA855F7);
  static const tierPink = Color(0xFFEC4899);
  static const tierTurquoise = Color(0xFF06B6D4);
  static const tierGold = Color(0xFFFFD700);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientCyan, gradientBlue, gradientPurple, gradientPink, gradientOrange, gradientYellow],
  );

  static const brandGradientSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x2667E8F9),
      Color(0x264A9EFF),
      Color(0x26A855F7),
    ],
  );

  /// Get tier color by level (1-10)
  static Color tierColor(int level) {
    switch (level) {
      case 1: return tierGray;
      case 2: return tierBlue;
      case 3: return tierGreen;
      case 4: return tierYellow;
      case 5: return tierOrange;
      case 6: return tierRed;
      case 7: return tierPurple;
      case 8: return tierPink;
      case 9: return tierTurquoise;
      case 10: return tierGold;
      default: return tierGray;
    }
  }
}

ThemeData hushDarkTheme() {
  final textTheme = GoogleFonts.interTextTheme().apply(
    bodyColor: HushColors.textPrimary,
    displayColor: HushColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: HushColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      surface: HushColors.bgPrimary,
      primary: HushColors.textAccent,
      secondary: HushColors.gradientPurple,
      onSurface: HushColors.textPrimary,
      onPrimary: HushColors.bgPrimary,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: HushColors.bgPrimary,
      foregroundColor: HushColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: HushColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: HushColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HushColors.borderSubtle),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: HushColors.bgSecondary,
      selectedItemColor: HushColors.textAccent,
      unselectedItemColor: HushColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HushColors.textAccent,
        foregroundColor: HushColors.bgPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HushColors.bgGlass,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HushColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HushColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HushColors.borderAccent),
      ),
      hintStyle: const TextStyle(color: HushColors.textMuted),
    ),
    dividerTheme: const DividerThemeData(
      color: HushColors.borderSubtle,
      thickness: 1,
    ),
  );
}

ThemeData hushLightTheme() {
  final textTheme = GoogleFonts.interTextTheme().apply(
    bodyColor: HushColors.textPrimaryLight,
    displayColor: HushColors.textPrimaryLight,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: HushColors.bgPrimaryLight,
    colorScheme: const ColorScheme.light(
      surface: HushColors.bgPrimaryLight,
      primary: HushColors.textAccent,
      secondary: HushColors.gradientPurple,
      onSurface: HushColors.textPrimaryLight,
      onPrimary: Colors.white,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: HushColors.bgPrimaryLight,
      foregroundColor: HushColors.textPrimaryLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: HushColors.textPrimaryLight,
      ),
    ),
    cardTheme: CardThemeData(
      color: HushColors.bgCardLight,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HushColors.borderLightMode),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: HushColors.textAccent,
      unselectedItemColor: HushColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HushColors.textAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HushColors.borderLightMode),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HushColors.borderLightMode),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HushColors.textAccent),
      ),
      hintStyle: const TextStyle(color: HushColors.textMuted),
    ),
    dividerTheme: const DividerThemeData(
      color: HushColors.borderLightMode,
      thickness: 1,
    ),
  );
}
