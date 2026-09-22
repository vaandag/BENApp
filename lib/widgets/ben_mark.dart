import 'package:flutter/material.dart';

/// BEN marka varlığının tek, gerçek görsel kaynağı.
/// Navigasyon ikonları veya harita pinleri bunun yerine geçmez.
class BENMark extends StatelessWidget {
  final double size;
  final bool glow;

  const BENMark({super.key, this.size = 44, this.glow = true});

  static const assetPath = 'assets/branding/ben_master_logo.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'BEN',
    );

    if (!glow) return image;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD200).withValues(alpha: .18),
            blurRadius: size * .28,
            spreadRadius: size * .015,
          ),
        ],
      ),
      child: image,
    );
  }
}
