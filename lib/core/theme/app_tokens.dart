import 'package:flutter/material.dart';

/// BEN görsel sisteminin tek kaynağı.
/// Görsel dil: siyah zemin, beyaz vurgu ve dengeli gri tonları.
class BenTokens {
  BenTokens._();

  // Siyah-beyaz palet bütün ekranlarda aynı kontrastı korur.
  static const cyan = Color(0xFFF2F2F2);
  static const cyanBright = Color(0xFFFFFFFF);
  static const cyanSoft = Color(0xFFD0D0D0);
  static const cyanDeep = Color(0xFFB8B8B8);
  static const gold = Color(0xFFBDBDBD);
  static const goldBright = Color(0xFFEAEAEA);

  static const ink = Color(0xFF000000);
  static const night = Color(0xFF000000);
  static const night2 = Color(0xFF101010);
  static const navy = Color(0xFF151515);
  static const panel = Color(0xFF141414);
  static const panel2 = Color(0xFF222222);
  static const line = Color(0xFF3A3A3A);
  static const paper = Color(0xFFF1F1F1);
  static const white = Color(0xFFF4F4F4);
  static const muted = Color(0xFFA5A5A5);
  static const danger = Color(0xFFFF6B7A);
  static const success = Color(0xFFD5D5D5);

  static const radiusSm = 12.0;
  static const radiusMd = 18.0;
  static const radiusLg = 24.0;
  static const radiusXl = 32.0;
  // ─────────────────────────────────────────────
  // BEN DESIGN SYSTEM — SPACING
  // ─────────────────────────────────────────────

  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const space6 = 24.0;
  static const space7 = 28.0;
  static const space8 = 32.0;
  static const space10 = 40.0;
  static const space12 = 48.0;
  static const space16 = 64.0;

  // ─────────────────────────────────────────────
  // BEN DESIGN SYSTEM — BORDERS
  // ─────────────────────────────────────────────

  static const borderHairline = 0.6;
  static const borderThin = 1.0;
  static const borderFocus = 1.5;

  static const glassBorderDark = Color(0x0FFFFFFF);
  static const glassBorderLight = Color(0x12061017);

  // ─────────────────────────────────────────────
  // BEN DESIGN SYSTEM — LAYOUT
  // ─────────────────────────────────────────────

  static const contentMaxWidth = 680.0;
  static const screenHorizontal = 16.0;
  static const screenHorizontalWide = 20.0;

  // ─────────────────────────────────────────────
  // BEN DESIGN SYSTEM — OPACITY
  // ─────────────────────────────────────────────

  static const opacitySubtle = 0.06;
  static const opacitySoft = 0.10;
  static const opacityMedium = 0.16;
  static const opacityStrong = 0.24;

  /// Ortak hareket dili: BEN ekranlarının birbirinden kopuk hissettirmemesi için
  /// tüm geçişlerde aynı ritim ve easing değerleri kullanılır.
  static const motionFast = Duration(milliseconds: 180);
  static const motionStandard = Duration(milliseconds: 280);
  static const motionSlow = Duration(milliseconds: 420);
  static const motionCurve = Curves.easeOutCubic;
  static const motionReverseCurve = Curves.easeInCubic;

  static List<BoxShadow> softShadow(bool dark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? .34 : .10),
          blurRadius: dark ? 34 : 24,
          offset: const Offset(0, 14),
        ),
      ];
}
