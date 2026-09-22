import 'package:flutter/material.dart';

import 'ben_mark.dart';

class BENNavIcon extends StatelessWidget {
  final BENNavIconType type;
  final bool selected;
  final double size;

  const BENNavIcon({
    super.key,
    required this.type,
    this.selected = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFFFFD200)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: .48);
    if (type == BENNavIconType.ben) {
      return BENMark(size: size, glow: selected);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BENNavPainter(type, color, selected)),
    );
  }
}

enum BENNavIconType { ben, map, explore, follow, create, messages, live, profile }

class _BENNavPainter extends CustomPainter {
  final BENNavIconType type;
  final Color color;
  final bool selected;

  _BENNavPainter(this.type, this.color, this.selected);

  Paint get stroke => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = selected ? 2.15 : 1.85
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    switch (type) {
      case BENNavIconType.ben:
        // BEN is rendered by BENNavIcon using the official master logo asset.
        break;
      case BENNavIconType.map:
        _map(canvas);
      case BENNavIconType.explore:
        _explore(canvas);
      case BENNavIconType.follow:
        _follow(canvas);
      case BENNavIconType.create:
        _create(canvas);
      case BENNavIconType.messages:
        _messages(canvas);
      case BENNavIconType.live:
        _live(canvas);
      case BENNavIconType.profile:
        _profile(canvas);
    }
  }

  void _map(Canvas c) {
    final p = Path()
      ..moveTo(12, 21)
      ..cubicTo(10.2, 18.1, 5.3, 14.1, 5.3, 9.5)
      ..cubicTo(5.3, 5.4, 8.2, 2.7, 12, 2.7)
      ..cubicTo(15.8, 2.7, 18.7, 5.4, 18.7, 9.5)
      ..cubicTo(18.7, 14.1, 13.8, 18.1, 12, 21);
    c.drawPath(p, stroke);
    c.drawCircle(const Offset(12, 9.2), 2.7, stroke);
    final route = Path()
      ..moveTo(2.5, 18.5)
      ..quadraticBezierTo(6.3, 16.2, 9.2, 18.4)
      ..quadraticBezierTo(12.1, 20.5, 15, 18.4)
      ..quadraticBezierTo(17.6, 16.4, 21.5, 18.2);
    c.drawPath(route, stroke..strokeWidth = 1.35);
  }

  void _explore(Canvas c) {
    c.drawCircle(const Offset(12, 12), 8.3, stroke);
    c.drawCircle(const Offset(12, 12), 3.2, stroke);
    final p = Path()..moveTo(12, 3.7)..lineTo(13.8, 9.7)..lineTo(20.3, 11.8)..lineTo(13.8, 13.8)..lineTo(12, 20.3)..lineTo(10.1, 13.8)..lineTo(3.7, 12)..lineTo(10.1, 9.9)..close();
    c.drawPath(p, stroke..strokeWidth = selected ? 1.5 : 1.2);
  }

  void _follow(Canvas c) {
    c.drawCircle(const Offset(9.2, 8.2), 3.4, stroke);
    final body = Path()
      ..moveTo(3.8, 19.8)
      ..cubicTo(4.4, 15.6, 6.2, 13.4, 9.2, 13.4)
      ..cubicTo(12.2, 13.4, 14.1, 15.6, 14.7, 19.8);
    c.drawPath(body, stroke);
    c.drawLine(const Offset(17.2, 8.5), const Offset(17.2, 16.8), stroke);
    c.drawLine(const Offset(13.1, 12.65), const Offset(21.3, 12.65), stroke);
  }

  void _create(Canvas c) {
    final plus = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.4 : 2.1
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(7, 12), const Offset(17, 12), plus);
    c.drawLine(const Offset(12, 7), const Offset(12, 17), plus);
  }

  void _messages(Canvas c) {
    final feather = Path()
      ..moveTo(4, 19.8)
      ..cubicTo(6.8, 18.9, 8.7, 17.2, 10.1, 15.1)
      ..cubicTo(12.7, 11.2, 16.2, 7.1, 20.1, 4.1)
      ..cubicTo(20.4, 8.9, 18.6, 13.7, 15.1, 16.5)
      ..cubicTo(11.7, 19.1, 7.6, 19.9, 4, 19.8);
    c.drawPath(feather, stroke);
    c.drawLine(const Offset(4, 19.8), const Offset(17.8, 7.1), stroke);
    c.drawLine(const Offset(10.2, 15.1), const Offset(15.7, 14.2), stroke);
    c.drawLine(const Offset(12.8, 11.8), const Offset(17.1, 10.4), stroke);
  }

  void _live(Canvas c) {
    c.drawCircle(const Offset(12, 12), 8.4, stroke);
    c.drawCircle(const Offset(12, 12), 2.8, stroke);
    c.drawLine(const Offset(12, 3.6), const Offset(12, 6.1), stroke);
    c.drawLine(const Offset(12, 17.9), const Offset(12, 20.4), stroke);
    c.drawLine(const Offset(3.6, 12), const Offset(6.1, 12), stroke);
    c.drawLine(const Offset(17.9, 12), const Offset(20.4, 12), stroke);
  }

  void _profile(Canvas c) {
    c.drawCircle(const Offset(12, 7.4), 3.6, stroke);
    final body = Path()
      ..moveTo(4.2, 20.2)
      ..cubicTo(4.9, 15.5, 7.5, 13.2, 12, 13.2)
      ..cubicTo(16.5, 13.2, 19.1, 15.5, 19.8, 20.2);
    c.drawPath(body, stroke);
    final spark = Path()
      ..moveTo(19.1, 3.2)
      ..lineTo(19.1, 5.8)
      ..moveTo(17.8, 4.5)
      ..lineTo(20.4, 4.5);
    c.drawPath(spark, stroke..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _BENNavPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.color != color ||
      oldDelegate.selected != selected;
}
