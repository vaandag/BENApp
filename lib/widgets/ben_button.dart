import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

enum BenButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
}

class BenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BenButtonVariant variant;
  final bool loading;
  final bool expand;
  final double height;

  const BenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = BenButtonVariant.primary,
    this.loading = false,
    this.expand = false,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null && !loading;

    final button = SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: switch (variant) {
        BenButtonVariant.primary => _buildPrimary(
            context,
            enabled,
            dark,
          ),
        BenButtonVariant.secondary => _buildSecondary(
            context,
            enabled,
            dark,
          ),
        BenButtonVariant.ghost => _buildGhost(
            context,
            enabled,
            dark,
          ),
        BenButtonVariant.danger => _buildDanger(
            context,
            enabled,
            dark,
          ),
      },
    );

    return button;
  }

  Widget _buildPrimary(
    BuildContext context,
    bool enabled,
    bool dark,
  ) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: BenTokens.cyan,
        foregroundColor: BenTokens.ink,
        disabledBackgroundColor: BenTokens.cyan.withValues(alpha: .25),
        disabledForegroundColor: BenTokens.ink.withValues(alpha: .45),
        elevation: 0,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BenTokens.radiusMd),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: .05,
        ),
      ),
      child: _content(
        color: BenTokens.ink,
        disabledColor: BenTokens.ink.withValues(alpha: .45),
      ),
    );
  }

  Widget _buildSecondary(
    BuildContext context,
    bool enabled,
    bool dark,
  ) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: dark
            ? BenTokens.cyan
            : BenTokens.cyanDeep,
        disabledForegroundColor: dark
            ? BenTokens.cyan.withValues(alpha: .30)
            : BenTokens.cyanDeep.withValues(alpha: .30),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        side: BorderSide(
          color: dark
              ? BenTokens.cyan.withValues(alpha: .42)
              : BenTokens.cyanDeep.withValues(alpha: .55),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BenTokens.radiusMd),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: _content(
        color: dark
            ? BenTokens.cyan
            : BenTokens.cyanDeep,
        disabledColor: dark
            ? BenTokens.cyan.withValues(alpha: .30)
            : BenTokens.cyanDeep.withValues(alpha: .30),
      ),
    );
  }

  Widget _buildGhost(
    BuildContext context,
    bool enabled,
    bool dark,
  ) {
    final color = dark
        ? BenTokens.cyan
        : BenTokens.cyanDeep;

    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color.withValues(alpha: .30),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            BenTokens.radiusSm,
          ),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: _content(
        color: color,
        disabledColor: color.withValues(alpha: .30),
      ),
    );
  }

  Widget _buildDanger(
    BuildContext context,
    bool enabled,
    bool dark,
  ) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: BenTokens.danger,
        foregroundColor: Colors.white,
        disabledBackgroundColor: BenTokens.danger.withValues(
          alpha: .25,
        ),
        disabledForegroundColor: Colors.white.withValues(
          alpha: .45,
        ),
        elevation: 0,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            BenTokens.radiusMd,
          ),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: _content(
        color: Colors.white,
        disabledColor: Colors.white.withValues(alpha: .45),
      ),
    );
  }

  Widget _content({
    required Color color,
    required Color disabledColor,
  }) {
    if (loading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            disabledColor,
          ),
        ),
      );
    }

    final iconWidget = icon == null
        ? null
        : Icon(
            icon,
            size: 18,
            color: color,
          );

    if (iconWidget == null) {
      return Text(label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: BenTokens.space2),
        Text(label),
      ],
    );
  }
}