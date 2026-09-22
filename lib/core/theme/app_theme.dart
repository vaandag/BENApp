import 'package:flutter/material.dart';
import 'app_tokens.dart';

class AppTheme {
  // Compatibility aliases used by legacy BEN screens.
  static const Color ink = BenTokens.ink;
  static const Color navy = BenTokens.navy;
  static const Color paper = BenTokens.paper;
  static const Color gold = BenTokens.gold;
  static const Color goldSoft = BenTokens.cyanBright;

  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BenTokens.cyan,
      brightness: Brightness.light,
    ).copyWith(
      primary: BenTokens.ink,
      secondary: BenTokens.cyanDeep,
      surface: Colors.white,
      onSurface: BenTokens.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: BenTokens.paper,
      fontFamily: 'sans',
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.7),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.3),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.35),
      ),
      splashColor: BenTokens.cyan.withValues(alpha: .08),
      highlightColor: BenTokens.cyan.withValues(alpha: .04),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: BenTokens.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BenTokens.radiusLg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: BenTokens.cyan.withValues(alpha: .18),
        height: 72,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEAF2F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: BenTokens.ink,
        foregroundColor: BenTokens.cyan,
      ),
      dividerTheme: DividerThemeData(color: BenTokens.ink.withValues(alpha: .07)),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BenTokens.cyan,
      brightness: Brightness.dark,
    ).copyWith(
      primary: BenTokens.cyan,
      secondary: BenTokens.cyan,
      surface: BenTokens.panel,
      onSurface: BenTokens.white,
      outline: Colors.white.withValues(alpha: .10),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: BenTokens.night,
      fontFamily: 'sans',
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.7),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.3),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.35),
      ),
      splashColor: BenTokens.cyan.withValues(alpha: .10),
      highlightColor: BenTokens.cyan.withValues(alpha: .05),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: BenTokens.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: BenTokens.panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BenTokens.radiusLg),
          side: BorderSide(color: Colors.white.withValues(alpha: .055)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xE6091118),
        surfaceTintColor: Colors.transparent,
        indicatorColor: BenTokens.cyan.withValues(alpha: .15),
        height: 72,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0A1822),
        hintStyle: const TextStyle(color: BenTokens.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: BenTokens.cyan, width: 1.2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: BenTokens.cyan,
        foregroundColor: BenTokens.ink,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BenTokens.panel,
        modalBackgroundColor: BenTokens.panel,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: .07)),
    );
  }
}
