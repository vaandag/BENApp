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
    this.padding = const EdgeInsets.all(BenTokens.space4),
    this.radius = const BorderRadius.all(
      Radius.circular(BenTokens.radiusLg),
    ),
    this.highlighted = false,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final surfaceColor = glass
        ? (dark
            ? const Color(0x99101F2A)
            : const Color(0xE6FFFFFF))
        : (dark ? BenTokens.panel : Colors.white);

    final borderColor = highlighted
        ? BenTokens.cyan.withValues(alpha: .55)
        : (dark
            ? BenTokens.glassBorderDark
            : BenTokens.glassBorderLight);

    final decoration = BoxDecoration(
      color: surfaceColor,
      borderRadius: radius,
      border: Border.all(
        color: borderColor,
        width: highlighted
            ? BenTokens.borderFocus
            : BenTokens.borderThin,
      ),
      boxShadow: BenTokens.softShadow(dark),
    );

    Widget content = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (glass) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}

class BenSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const BenSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final color = theme.colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.35,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: BenTokens.space1),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: .55),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: BenTokens.space3),
          trailing!,
        ],
      ],
    );
  }
}

class BenIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final bool active;

  const BenIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
    this.active = false,
  });

  @override
  State<BenIconButton> createState() => _BenIconButtonState();
}

class _BenIconButtonState extends State<BenIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final foreground = theme.colorScheme.onSurface;

    final background = widget.active
        ? BenTokens.cyan.withValues(alpha: .14)
        : (dark
            ? Colors.white.withValues(alpha: .045)
            : Colors.black.withValues(alpha: .045));

    final borderColor = widget.active
        ? BenTokens.cyan.withValues(alpha: .45)
        : (dark
            ? Colors.white.withValues(alpha: .06)
            : Colors.transparent);

    return Semantics(
      button: true,
      label: widget.badge == null ? null : 'Bildirim ${widget.badge}',
      child: AnimatedScale(
        scale: _pressed ? .94 : 1,
        duration: BenTokens.motionFast,
        curve: BenTokens.motionCurve,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: background,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onTap,
                onTapDown: (_) => _setPressed(true),
                onTapCancel: () => _setPressed(false),
                onTapUp: (_) => _setPressed(false),
                splashColor: BenTokens.cyan.withValues(alpha: .10),
                highlightColor: BenTokens.cyan.withValues(alpha: .05),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor,
                      width: widget.active
                          ? BenTokens.borderThin
                          : BenTokens.borderHairline,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: widget.active
                        ? BenTokens.cyan
                        : foreground,
                  ),
                ),
              ),
            ),
            if (widget.badge != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BenTokens.cyan,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: dark
                          ? BenTokens.night
                          : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: BenTokens.ink,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}