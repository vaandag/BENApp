import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

enum BenHeaderActionType { notifications, search, more }

/// BEN üst çubuğu için özel çizgi ikonları ve cam görünümlü dokunma alanı.
class BenHeaderAction extends StatelessWidget {
  final BenHeaderActionType type;
  final VoidCallback onTap;

  const BenHeaderAction({
    super.key,
    required this.type,
    required this.onTap,
  });

  String get _tooltip => switch (type) {
        BenHeaderActionType.notifications => 'Bildirimler',
        BenHeaderActionType.search => 'Ara',
        BenHeaderActionType.more => 'Daha fazla',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: _tooltip,
        child: Material(
          color: const Color(0xFF151515),
          shape: const CircleBorder(
            side: BorderSide(color: Color(0xFF383838), width: 1),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            splashColor: BenTokens.gold.withValues(alpha: .14),
            child: SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(
                painter: _BenHeaderActionPainter(type),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenHeaderActionPainter extends CustomPainter {
  final BenHeaderActionType type;

  const _BenHeaderActionPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate((size.width - 24) / 2, (size.height - 24) / 2);
    final white = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final gold = Paint()
      ..color = BenTokens.gold
      ..style = PaintingStyle.fill;

    switch (type) {
      case BenHeaderActionType.search:
        canvas.drawCircle(const Offset(9.5, 9.5), 6.2, white);
        canvas.drawLine(const Offset(14.2, 14.2), const Offset(20.2, 20.2), white);
        canvas.drawCircle(const Offset(9.5, 9.5), 2, gold);
        canvas.drawLine(const Offset(9.5, 1.2), const Offset(9.5, 2.2), gold);
        canvas.drawLine(const Offset(1.2, 9.5), const Offset(2.2, 9.5), gold);
        break;
      case BenHeaderActionType.notifications:
        final bell = Path()
          ..moveTo(5.2, 17.1)
          ..cubicTo(6.5, 15.8, 6.8, 14.4, 6.8, 12.2)
          ..lineTo(6.8, 9.8)
          ..cubicTo(6.8, 6.7, 8.8, 4.5, 12, 4.5)
          ..cubicTo(15.2, 4.5, 17.2, 6.7, 17.2, 9.8)
          ..lineTo(17.2, 12.2)
          ..cubicTo(17.2, 14.4, 17.5, 15.8, 18.8, 17.1)
          ..close();
        canvas.drawPath(bell, white);
        canvas.drawLine(const Offset(5.2, 17.1), const Offset(18.8, 17.1), white);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(12, 19), radius: 2.2),
          0,
          3.14159,
          false,
          white,
        );
        canvas.drawCircle(const Offset(12, 2.5), 1.6, gold);
        canvas.drawCircle(const Offset(20.2, 4), 2.2, gold);
        break;
      case BenHeaderActionType.more:
        for (final x in [6.0, 12.0, 18.0]) {
          canvas.drawCircle(Offset(x, 12), 1.55, white);
        }
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BenHeaderActionPainter oldDelegate) =>
      oldDelegate.type != type;
}
