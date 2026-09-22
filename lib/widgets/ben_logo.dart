import 'package:flutter/material.dart';

import 'ben_mark.dart';

class BENLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool dark;
  final bool showPin;

  const BENLogo({
    super.key,
    this.size = 96,
    this.showWordmark = false,
    this.dark = true,
    this.showPin = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white : const Color(0xFF101217);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPin)
          BENMark(size: size, glow: false),
        if (showWordmark) ...[
          const SizedBox(height: 12),
          Text(
            'BEN',
            style: TextStyle(
              color: textColor,
              fontSize: size * .30,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
              height: .95,
            ),
          ),
        ],
      ],
    );
  }
}
