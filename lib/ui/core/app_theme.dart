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

  /// Crisp Light Mode Palette (Material Design 3 High Contrast)
  static const Color lightBackground = Color(0xFFF8FAFC); // Crisp Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);    // Pure White Surface
  static const Color lightCard = Color(0xFFFFFFFF);       // Elevated Card Surface
  static const Color lightBorder = Color(0xFFE2E8F0);     // Structural Slate 200 Border
  static const Color lightBorderActive = Color(0xFFCBD5E1); // Slate 300 for active inputs
  static const Color lightTextPrimary = Color(0xFF0F172A); // High Contrast Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightSubtext = Color(0xFF64748B);    // Slate 500
  static const Color lightEmerald = Color(0xFF059669);    // High Contrast Emerald 600
  static const Color lightIndigo = Color(0xFF4F46E5);     // Deep Indigo 600

  /// Material Design 3 Light Theme with crisp contrast, legible typography, and elevated cards
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: lightEmerald,
      secondary: lightIndigo,
      tertiary: accentCyan,
      error: const Color(0xFFDC2626),
      surface: lightSurface,
      surfaceContainerHighest: const Color(0xFFF1F5F9),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      outline: lightBorderActive,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 1,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x0A0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: lightBorder, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
          letterSpacing: -0.6,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: lightEmerald,
        unselectedItemColor: lightSubtext,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightEmerald,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: const Color(0xFFD1FAE5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder),
        ),
        labelStyle: const TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(
          color: lightTextSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        helperStyle: const TextStyle(
          color: lightSubtext,
          fontSize: 12,
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFDC2626),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        prefixIconColor: lightSubtext,
        suffixIconColor: lightSubtext,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorderActive, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorderActive, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightEmerald, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightEmerald,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 24,
      ),
    );
  }

  /// Dark Theme aliased to Light Theme for Light Theme Exclusivity requirement
  static ThemeData get darkTheme => lightTheme;
}

