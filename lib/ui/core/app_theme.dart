import 'package:flutter/material.dart';

/// Design tokens, color palettes, and ThemeData definitions for the application.
///
/// Features a modern, minimalist dark mode aesthetic centered around deep obsidian
/// and midnight slate backgrounds (`#090D16`, `#111827`) paired with vibrant neon
/// emerald (`#10B981`), electric indigo (`#6366F1`), and cyan (`#06B6D4`) accents.
class AppTheme {
  // Vibrant Neon & Accent Palette
  static const Color primaryEmerald = Color(0xFF10B981); // High-momentum emerald
  static const Color primaryIndigo = Color(0xFF6366F1);  // Focus & analytical indigo
  static const Color accentAmber = Color(0xFFF59E0B);    // Warning & warmth amber
  static const Color accentRose = Color(0xFFF43F5E);     // High-urgency alert rose
  static const Color accentCyan = Color(0xFF06B6D4);     // Crisp cognitive cyan
  static const Color accentPurple = Color(0xFF8B5CF6);   // Creative violet
  static const Color accentBlue = Color(0xFF3B82F6);     // Electric neon blue

  // Deep Obsidian Dark Mode Palette
  static const Color darkBackground = Color(0xFF090D16); // Deep Obsidian Slate
  static const Color darkSurface = Color(0xFF111827);    // Elevated Dark Surface (Slate 900)
  static const Color darkCard = Color(0xFF161F30);       // Translucent Dark Card Container
  static const Color darkBorder = Color(0xFF26334D);     // Subtle Slate Border (Slate 800)
  static const Color darkSubtext = Color(0xFF94A3B8);    // Muted Slate 400 Text
  static const Color darkGlow = Color(0x3310B981);       // Ambient Emerald Glow

  // Crisp Light Mode Palette
  static const Color lightBackground = Color(0xFFF8FAFC); // Crisp Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);    // Slate 200
  static const Color lightSubtext = Color(0xFF64748B);   // Slate 500

  /// Dark Theme with sleek glassmorphic elevation and deep slate contrast
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: primaryEmerald,
      secondary: primaryIndigo,
      tertiary: accentCyan,
      error: accentRose,
      surface: darkSurface,
      surfaceContainerHighest: darkBorder,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFFF8FAFC),
      outline: darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.6,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryEmerald,
        unselectedItemColor: darkSubtext,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: primaryEmerald.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryEmerald, width: 1.5),
        ),
      ),
    );
  }

  /// Light Theme with clean slate aesthetics
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryEmerald,
      secondary: primaryIndigo,
      tertiary: accentCyan,
      error: accentRose,
      surface: lightSurface,
      surfaceContainerHighest: lightBorder,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF0F172A),
      outline: lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          letterSpacing: -0.6,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryEmerald,
        unselectedItemColor: lightSubtext,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        selectedColor: primaryEmerald.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryEmerald, width: 1.5),
        ),
      ),
    );
  }
}
