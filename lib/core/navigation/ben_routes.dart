import 'package:flutter/material.dart';

import '../../screens/comments_screen.dart';

class BenRoutes {
  static Future<int?> openComments(
    BuildContext context, {
    int? memoryId,
    String? memoryKey,
    String title = 'Yorumlar',
    int initialCount = 0,
  }) {
    return Navigator.of(context, rootNavigator: true).push<int>(
      PageRouteBuilder<int>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (routeContext, animation, secondaryAnimation) => CommentsScreen(
          title: title,
          initialCount: initialCount,
          memoryId: memoryId,
          memoryKey: memoryKey,
        ),
        transitionsBuilder: (routeContext, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .045),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: .985, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
