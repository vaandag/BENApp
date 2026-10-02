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
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          height: 1.10,
        ),
        headlineSmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
          height: 1.20,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.25,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.40,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
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
          TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEAF2F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BenTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BenTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BenTokens.radiusMd),
          borderSide: const BorderSide(
            color: BenTokens.cyanDeep,
            width: 1.2,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, 48),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                BenTokens.radiusMd,
              ),
            ),
          ),
          backgroundColor: const WidgetStatePropertyAll(
            BenTokens.cyan,
          ),
          foregroundColor: const WidgetStatePropertyAll(
            BenTokens.ink,
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, 48),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                BenTokens.radiusMd,
              ),
            ),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(
              color: BenTokens.cyanDeep,
              width: 1,
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(
            BenTokens.ink,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, 44),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                BenTokens.radiusSm,
              ),
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(
            BenTokens.cyanDeep,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEAF2F4),
        selectedColor: BenTokens.cyan.withValues(alpha: .18),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
      ),

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: BenTokens.ink,
        foregroundColor: BenTokens.cyan,
      ),

      dividerTheme: DividerThemeData(
        color: BenTokens.ink.withValues(alpha: .07),
      ),
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
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          height: 1.10,
        ),
        headlineSmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
          height: 1.20,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.25,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.40,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
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
          borderRadius: BorderRadius.circular(
            BenTokens.radiusLg,
          ),
          side: BorderSide(
            color: Colors.white.withValues(alpha: .055),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xE6091118),
        surfaceTintColor: Colors.transparent,
        indicatorColor: BenTokens.cyan.withValues(alpha: .15),
        height: 72,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0A1822),
        hintStyle: const TextStyle(
          color: BenTokens.muted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            BenTokens.radiusMd,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: .06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            BenTokens.radiusMd,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: .06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            BenTokens.radiusMd,
          ),
          borderSide: const BorderSide(
            color: BenTokens.cyan,
            width: 1.2,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, 48),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                BenTokens.radiusMd,
              ),
            ),
          ),
          backgroundColor: const WidgetStatePropertyAll(
            BenTokens.cyan,
          ),
          foregroundColor: const WidgetStatePropertyAll(
            BenTokens.ink,
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, 48),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                BenTokens.radiusMd,
              ),
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: BenTokens.cyan.withValues(alpha: .42),
              width: 1,
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(
            BenTokens.cyan,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, 44),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                BenTokens.radiusSm,
              ),
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(
            BenTokens.cyan,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: BenTokens.panel2,
        selectedColor: BenTokens.cyan.withValues(alpha: .16),
        side: BorderSide(
          color: BenTokens.cyan.withValues(alpha: .08),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: BenTokens.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
      ),

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: BenTokens.cyan,
        foregroundColor: BenTokens.ink,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BenTokens.panel,
        modalBackgroundColor: BenTokens.panel,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: .07),
      ),
    );
  }
}