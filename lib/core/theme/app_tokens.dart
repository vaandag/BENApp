import 'package:flutter/material.dart';

/// BEN görsel sisteminin tek kaynağı.
/// Görsel dil: koyu petrol / teal ışık / ince çerçeveler.
class BenTokens {
  BenTokens._();

  // Profil ekranındaki koyu petrol / teal dili tüm uygulamanın ortak paletidir.
  static const cyan = Color(0xFF31D5C3);
  static const cyanBright = Color(0xFFB7F5EA);
  static const cyanSoft = Color(0xFF85C8BD);
  static const cyanDeep = Color(0xFF1D9F92);
  static const gold = Color(0xFFE6C45D);
  static const goldBright = Color(0xFFF1D987);

  static const ink = Color(0xFF07110F);
  static const night = Color(0xFF07110F);
  static const night2 = Color(0xFF091A17);
  static const navy = Color(0xFF0E211E);
  static const panel = Color(0xFF0E211E);
  static const panel2 = Color(0xFF142D28);
  static const line = Color(0xFF205D53);
  static const paper = Color(0xFFF1F6F3);
  static const white = Color(0xFFE8F5F1);
  static const muted = Color(0xFF9ABBB3);
  static const danger = Color(0xFFFF6B7A);
  static const success = Color(0xFF67F5B2);

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
