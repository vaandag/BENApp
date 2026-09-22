import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BENParticleSplashScreen extends StatefulWidget {
  const BENParticleSplashScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<BENParticleSplashScreen> createState() => _BENParticleSplashScreenState();
}

class _BENParticleSplashScreenState extends State<BENParticleSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_done) {
          _done = true;
          widget.onFinished();
        }
      })..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      body: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final logoT = Curves.easeOutBack.transform(((t - .68) / .18).clamp(0.0, 1.0));
            final logoOpacity = Curves.easeOut.transform(((t - .72) / .12).clamp(0.0, 1.0));
            final logoScale = .72 + .28 * logoT;
            final logoRotation = (1 - logoT) * .10;
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _BENParticlePainter(t),
                  size: Size.infinite,
                ),
                if (logoOpacity > 0)
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, MediaQuery.of(context).size.height * .115 * (1 - logoT)),
                      child: Opacity(
                        opacity: logoOpacity,
                        child: Transform.rotate(
                          angle: logoRotation,
                          child: Transform.scale(
                            scale: logoScale,
                            child: Image.asset(
                              'assets/branding/ben_master_logo.png',
                              width: math.min(MediaQuery.of(context).size.width * .32, 190),
                              height: math.min(MediaQuery.of(context).size.width * .32, 190),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.tx,
    required this.ty,
    required this.sx,
    required this.sy,
    required this.size,
    required this.phase,
    required this.delay,
  });
  final double tx, ty, sx, sy, size, phase, delay;
}

class _BENParticlePainter extends CustomPainter {
  _BENParticlePainter(this.progress);
  final double progress;

  static const bg = Color(0xFF05070A);
  static const gold = Color(0xFFFFD21A);
  static const goldHot = Color(0xFFFFF7B0);

  List<_Particle>? _cache;
  Size? _cacheSize;
  Path? _outerCache;
  Path? _innerCache;

  Offset _center(Size size) => Offset(size.width / 2, size.height * .34);
  double _ease(double x) {
    x = x.clamp(0.0, 1.0);
    return x * x * (3.0 - 2.0 * x);
  }
  double _easeOut(double x) => 1 - math.pow(1 - x.clamp(0.0, 1.0), 3).toDouble();
  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Path _outerPath(Size size) {
    if (_outerCache != null && _cacheSize == size) return _outerCache!;
    final c = _center(size);
    final r = math.min(size.width * .155, 116.0);
    final p = Path();
    p.moveTo(c.dx, c.dy + r * 2.18);
    p.cubicTo(c.dx - r * .30, c.dy + r * 1.66, c.dx - r * 1.02, c.dy + r * .86,
        c.dx - r, c.dy);
    p.arcTo(Rect.fromCircle(center: c, radius: r), math.pi, math.pi, false);
    p.cubicTo(c.dx + r * 1.02, c.dy + r * .86, c.dx + r * .30, c.dy + r * 1.66,
        c.dx, c.dy + r * 2.18);
    p.close();
    _outerCache = p;
    return p;
  }

  Path _innerPath(Size size) {
    if (_innerCache != null && _cacheSize == size) return _innerCache!;
    final c = _center(size);
    final r = math.min(size.width * .155, 116.0) * .58;
    final p = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    _innerCache = p;
    return p;
  }

  List<Offset> _targetPoints(Size size) {
    final c = _center(size);
    final r = math.min(size.width * .155, 116.0);
    final pts = <Offset>[];
    // Dense outer contour.
    for (var i = 0; i < 760; i++) {
      final t = i / 759.0;
      final a = math.pi + math.pi * t;
      pts.add(Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a)));
    }
    for (var i = 0; i < 420; i++) {
      final t = i / 419.0;
      final y = c.dy + r * (0.02 + 2.16 * t);
      final half = r * (1.0 - t);
      pts.add(Offset(c.dx - half, y));
      pts.add(Offset(c.dx + half, y));
    }
    // Inner circular contour.
    final ir = r * .58;
    for (var i = 0; i < 420; i++) {
      final a = 2 * math.pi * i / 420.0;
      pts.add(Offset(c.dx + ir * math.cos(a), c.dy + ir * math.sin(a)));
    }
    return pts;
  }

  List<_Particle> _particles(Size size) {
    if (_cache != null && _cacheSize == size) return _cache!;
    final rng = math.Random(29071993);
    final c = _center(size);
    final targets = _targetPoints(size)..shuffle(rng);
    final count = math.min(1500, targets.length);
    final result = <_Particle>[];
    for (var i = 0; i < count; i++) {
      final target = targets[i];
      final a = rng.nextDouble() * math.pi * 2;
      final radius = size.width * (.25 + rng.nextDouble() * .43);
      result.add(_Particle(
        tx: target.dx,
        ty: target.dy,
        sx: c.dx + math.cos(a) * radius * (0.65 + rng.nextDouble() * .7),
        sy: c.dy + math.sin(a) * radius * (0.75 + rng.nextDouble() * .9),
        size: .7 + rng.nextDouble() * 2.0,
        phase: rng.nextDouble() * math.pi * 2,
        delay: rng.nextDouble() * .18,
      ));
    }
    _cache = result;
    _cacheSize = size;
    return result;
  }

  void _dot(Canvas canvas, Offset p, double radius, double alpha, {bool hot = false}) {
    if (alpha <= 0) return;
    final glow = Paint()
      ..color = gold.withValues(alpha: alpha * .24)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 4.5);
    canvas.drawCircle(p, radius * 1.7, glow);
    final dot = Paint()..color = (hot ? goldHot : gold).withValues(alpha: alpha);
    canvas.drawCircle(p, radius, dot);
  }

  void _drawPartialPath(Canvas canvas, Path path, double amount, Paint paint) {
    if (amount <= 0) return;
    final metrics = path.computeMetrics().toList(growable: false);
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var left = total * amount.clamp(0.0, 1.0);
    final partial = Path();
    for (final metric in metrics) {
      if (left <= 0) break;
      final take = math.min(left, metric.length);
      partial.addPath(metric.extractPath(0, take), Offset.zero);
      left -= take;
    }
    canvas.drawPath(partial, paint);
  }

  void _drawTarget(Canvas canvas, Offset center, double amount, double pulse) {
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..color = gold.withValues(alpha: .78 * amount)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = goldHot.withValues(alpha: .55 * amount);
    final scale = 1 + pulse;
    canvas.drawOval(Rect.fromCenter(center: center, width: 150 * scale, height: 40 * scale), outer);
    canvas.drawOval(Rect.fromCenter(center: center, width: 88 * scale, height: 24 * scale), inner);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(bg, BlendMode.srcOver);
    if (size.width <= 0 || size.height <= 0) return;

    final c = _center(size);
    final parts = _particles(size);
    final outer = _outerPath(size);
    final inner = _innerPath(size);

    // 0.00–1.15s: empty screen becomes a living cloud.
    final cloudIn = _easeOut((progress - .02) / .20);

    // Three long ribbons create the cinematic spiral seen before the logo exists.
    if (progress > .04 && progress < .72) {
      final a = math.sin(((progress - .04) / .68) * math.pi).clamp(0.0, 1.0);
      for (var band = 0; band < 3; band++) {
        final path = Path();
        for (var i = 0; i <= 120; i++) {
          final t = i / 120.0;
          final y = c.dy - size.height * .30 + t * size.height * .78;
          final x = c.dx + math.sin(t * math.pi * 3.5 + band * 2.05 + progress * 12.0) *
              (size.width * (.18 - .035 * t));
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 + band * .35
          ..color = gold.withValues(alpha: a * (.34 - band * .06))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
        canvas.drawPath(path, paint);
      }
    }

    // The particle cloud spirals inward, but never shows a completed logo early.
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      final local = ((progress - p.delay) / .60).clamp(0.0, 1.0);
      final q = _ease(local);
      final dx = p.sx - c.dx;
      final dy = p.sy - c.dy;
      final orbit = (1 - q) * (2.2 + p.delay * 5.0);
      final co = math.cos(orbit + p.phase);
      final si = math.sin(orbit + p.phase);
      final ox = dx * co - dy * si;
      final oy = dx * si + dy * co;
      var x = _lerp(p.sx, c.dx + ox * .35, q);
      var y = _lerp(p.sy, c.dy + oy * .35, q);
      if (progress > .18) {
        final tangent = math.sin(q * math.pi) * (34 + p.delay * 90);
        final len = math.sqrt(dx * dx + dy * dy) + 1;
        x += (-dy / len) * tangent;
        y += (dx / len) * tangent;
      }
      // After the cloud phase, particles lock onto their actual logo coordinates.
      final lock = _ease((progress - .31) / .42);
      x = _lerp(x, p.tx, lock);
      y = _lerp(y, p.ty, lock);
      final alpha = cloudIn * (0.18 + .82 * math.max(lock, .22));
      final pulse = .72 + .28 * math.sin(progress * 38 + p.phase);
      _dot(canvas, Offset(x, y), p.size * pulse, alpha, hot: lock > .78);
    }

    // 1.0–3.2s: draw the actual logo contour progressively. No instant full-logo pop.
    final contour = _ease((progress - .48) / .28);
    if (contour > 0) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = goldHot.withValues(alpha: .92 * contour)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      _drawPartialPath(canvas, outer, contour, stroke);
      _drawPartialPath(canvas, inner, (contour - .12) / .88, stroke);
    }

    // V169: the final logo is rendered from the official master asset above.
    // The particle contour remains as the formation stage, but no second hard-coded
    // pin body is painted here. This prevents the old location-pin look.

    // 3.6–4.8s: target ring appears and reacts to the landing.
    if (progress > .70) {
      final q = _ease((progress - .70) / .30);
      final ringCenter = Offset(c.dx, c.dy + 112);
      final pulse = progress > .90 ? math.sin((progress - .90) * 32) * .10 : 0.0;
      _drawTarget(canvas, ringCenter, q, pulse);
      final beam = Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx, c.dy + 20),
          ringCenter,
          [gold.withValues(alpha: 0), gold.withValues(alpha: .40 * q), gold.withValues(alpha: 0)],
        )
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(c.dx, c.dy + 28), ringCenter, beam);
    }

    if (progress > .91) {
      final q = ((progress - .91) / .09).clamp(0.0, 1.0);
      final ringCenter = Offset(c.dx, c.dy + 112);
      final shock = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1 - q)
        ..color = goldHot.withValues(alpha: .72 * (1 - q))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawOval(Rect.fromCenter(center: ringCenter, width: 95 + q * 220, height: 25 + q * 62), shock);
    }

    // Branding fades in only after the logo has landed.
    if (progress > .96) {
      final q = _ease((progress - .96) / .04);
      final text = TextPainter(
        text: TextSpan(
          text: 'B E N',
          style: TextStyle(color: Colors.white.withValues(alpha: q), fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 7),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(c.dx - text.width / 2, c.dy + 150));
      final sub = TextPainter(
        text: TextSpan(
          text: 'PAYLAŞ • KEŞFET • HİSSET',
          style: TextStyle(color: Colors.white.withValues(alpha: .65 * q), fontSize: 8.5, letterSpacing: 3.1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      sub.paint(canvas, Offset(c.dx - sub.width / 2, c.dy + 184));
    }
  }

  @override
  bool shouldRepaint(covariant _BENParticlePainter oldDelegate) => oldDelegate.progress != progress;
}
