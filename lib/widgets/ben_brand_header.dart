import 'package:flutter/material.dart';

import 'ben_mark.dart';

class BENBrandHeader extends StatelessWidget {
  final String? subtitle;
  final VoidCallback? onTap;

  const BENBrandHeader({super.key, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BENMark(size: 34, glow: false),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BEN',
              style: TextStyle(
                fontSize: 21,
                height: .95,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .46),
                ),
              ),
          ],
        ),
      ],
    );

    return onTap == null
        ? content
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: content,
          );
  }
}
