import 'package:flutter/material.dart';

abstract final class SublyColors {
  static const navy = Color(0xFF123426);
  static const purple = Color(0xFF36A95F);
  static const accent = Color(0xFFA7D95F);
  static const background = Color(0xFFF7FBF5);
  static const green = Color(0xFF21A864);
  static const red = Color(0xFFF04438);
  static const orange = Color(0xFFF79009);
}

abstract final class SublyTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: SublyColors.purple,
      brightness: brightness,
      surface: dark ? const Color(0xFF12251A) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF09170F)
          : SublyColors.background,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: SublyColors.purple.withValues(alpha: .14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
