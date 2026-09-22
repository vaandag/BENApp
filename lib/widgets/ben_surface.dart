import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_tokens.dart';

class BenSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry radius;
  final bool highlighted;
  final bool glass;

  const BenSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = const BorderRadius.all(Radius.circular(BenTokens.radiusLg)),
    this.highlighted = false,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = highlighted
        ? BenTokens.cyan.withValues(alpha: .55)
        : (dark ? Colors.white.withValues(alpha: .065) : Colors.black.withValues(alpha: .06));

    final decoration = BoxDecoration(
      color: glass
          ? (dark ? const Color(0x99101F2A) : const Color(0xD9FFFFFF))
          : (dark ? BenTokens.panel : Colors.white),
      borderRadius: radius,
      border: Border.all(color: border, width: highlighted ? 1.2 : 1),
      boxShadow: BenTokens.softShadow(dark),
    );

    Widget content = Container(padding: padding, decoration: decoration, child: child);
    if (glass) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: content),
      );
    }
    return content;
  }
}

class BenSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const BenSectionTitle({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: color, letterSpacing: -.5)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: TextStyle(fontSize: 12, color: color.withValues(alpha: .52), fontWeight: FontWeight.w600)),
        ],
      ])),
      trailing ?? const SizedBox.shrink(),
    ]);
  }
}

class BenIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final bool active;
  const BenIconButton({super.key, required this.icon, required this.onTap, this.badge, this.active = false});

  @override
  State<BenIconButton> createState() => _BenIconButtonState();
}

class _BenIconButtonState extends State<BenIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? .90 : 1,
        duration: const Duration(milliseconds: 120),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.active
                  ? BenTokens.cyan.withValues(alpha: .14)
                  : (dark ? Colors.white.withValues(alpha: .045) : Colors.black.withValues(alpha: .045)),
              shape: BoxShape.circle,
              border: Border.all(color: widget.active ? BenTokens.cyan.withValues(alpha: .45) : Colors.white.withValues(alpha: dark ? .06 : 0)),
            ),
            child: Icon(widget.icon, size: 20, color: widget.active ? BenTokens.cyan : Theme.of(context).colorScheme.onSurface),
          ),
          if (widget.badge != null)
            Positioned(right: -1, top: -1, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: BenTokens.cyan, borderRadius: BorderRadius.circular(10), border: Border.all(color: dark ? BenTokens.night : Colors.white, width: 2)),
              child: Text(widget.badge!, style: const TextStyle(color: BenTokens.ink, fontSize: 8, fontWeight: FontWeight.w900)),
            )),
        ]),
      ),
    );
  }
}
