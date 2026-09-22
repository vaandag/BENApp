import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// BEN genelinde kullanılan tek sayfa geçiş dili.
class BENPageTransitionsBuilder extends PageTransitionsBuilder {
  const BENPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: BenTokens.motionCurve,
      reverseCurve: BenTokens.motionReverseCurve,
    );
    final slide = Tween<Offset>(
      begin: const Offset(.035, .012),
      end: Offset.zero,
    ).animate(curved);
    final scale = Tween<double>(begin: .985, end: 1).animate(curved);
    final fade = Tween<double>(begin: 0, end: 1).animate(curved);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class BENPageTransitionsTheme {
  const BENPageTransitionsTheme._();

  static PageTransitionsTheme get value => const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: BENPageTransitionsBuilder(),
          TargetPlatform.iOS: BENPageTransitionsBuilder(),
          TargetPlatform.linux: BENPageTransitionsBuilder(),
          TargetPlatform.macOS: BENPageTransitionsBuilder(),
          TargetPlatform.windows: BENPageTransitionsBuilder(),
          TargetPlatform.fuchsia: BENPageTransitionsBuilder(),
        },
      );
}
