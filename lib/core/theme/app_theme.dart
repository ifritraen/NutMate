import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/app_settings.dart';

class AppTheme {
  static const Color primaryViolet = Color(0xFF9D4EDD);
  static const Color secondaryCyan = Color(0xFF00F5D4);
  static const Color accentRose = Color(0xFFF72585);
  static const Color goldAccent = Color(0xFFFFC107);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color cardDark = Color(0xFF1E1B2E);
  static const Color backgroundDark = Color(0xFF0F0E17);

  static Color getAccentColor(AppAccentColor accent) {
    switch (accent) {
      case AppAccentColor.cyan:
        return secondaryCyan;
      case AppAccentColor.violet:
        return primaryViolet;
      case AppAccentColor.gold:
        return goldAccent;
      case AppAccentColor.emerald:
        return emeraldAccent;
    }
  }

  static ThemeData getDarkTheme(AppSettings settings) {
    final isAmoled = settings.themeMode == AppThemeMode.amoled;
    final bg = isAmoled ? Colors.black : backgroundDark;
    final cardBg = isAmoled ? const Color(0xFF121212) : cardDark;
    final accent = getAccentColor(settings.accentColor);

    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primaryViolet,
        secondary: accent,
        tertiary: accentRose,
        surface: cardBg,
        background: bg,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: accent,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryViolet,
        inactiveTrackColor: Colors.white12,
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardBg,
        selectedColor: accent.withOpacity(0.3),
        side: const BorderSide(color: Colors.white24),
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
