import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// BEN branded entrance animation.
///
/// The particles are generated from the real BEN master-logo alpha mask, so the
/// logo is not approximated by a location pin or a generic shape. The sequence
/// is: dark field -> loose particle cloud -> BEN logo formation -> glow/flash ->
/// logo locks in -> app.
class BENParticleSplashScreen extends StatefulWidget {
  const BENParticleSplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<BENParticleSplashScreen> createState() => _BENParticleSplashScreenState();
}

class _BENParticleSplashScreenState extends State<BENParticleSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2450);

  late final AnimationController _controller;
  List<Offset> _maskPoints = const <Offset>[];
  bool _ready = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_finished) {
          _finished = true;
          widget.onFinished();
        }
      });
    _loadLogoMask();
  }

  Future<void> _loadLogoMask() async {
    try {
      final data = await rootBundle.load('assets/branding/ben_master_logo.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null || !mounted) return;

      final points = _sampleMask(
        byteData.buffer.asUint8List(),
        image.width,
        image.height,
      );
      image.dispose();
      if (!mounted) return;

      setState(() {
        _maskPoints = points;
        _ready = true;
      });
      _controller.forward();
    } catch (_) {
      // If the asset cannot be decoded, still show a short branded fallback.
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.forward();
    }
  }

  List<Offset> _sampleMask(Uint8List rgba, int width, int height) {
    final raw = <Offset>[];
    const stride = 7;
    for (var y = 0; y < height; y += stride) {
      for (var x = 0; x < width; x += stride) {
        final i = (y * width + x) * 4;
        final alpha = rgba[i + 3];
        if (alpha < 80) continue;
        // Keep the real opaque logo silhouette, including glossy transparent
        // edges, while avoiding huge numbers of almost-transparent pixels.
        final luminance =
            (rgba[i] * .299 + rgba[i + 1] * .587 + rgba[i + 2] * .114);
        if (alpha > 150 || luminance > 115) {
          raw.add(Offset(x / width, y / height));
        }
      }
    }

    // Deterministic down-sampling keeps animation cost stable on Redmi 8 and
    // still gives enough particles for a recognisable BEN logo.
    const maxParticles = 1150;
    if (raw.length <= maxParticles) return raw;
    final result = <Offset>[];
    final step = raw.length / maxParticles;
    for (var i = 0; i < maxParticles; i++) {
      result.add(raw[(i * step).floor()]);
    }
    return result;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(backgroundColor: Color(0xFF05070A));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      body: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final size = MediaQuery.sizeOf(context);
            final t = _controller.value;
            final settle = Curves.easeOutBack.transform(
              ((t - .58) / .18).clamp(0.0, 1.0),
            );
            final flash = Curves.easeOut.transform(
              ((t - .70) / .10).clamp(0.0, 1.0),
            );
            final logoOpacity = Curves.easeOutCubic.transform(
              ((t - .74) / .16).clamp(0.0, 1.0),
            );
            final logoScale = .92 + .08 * settle;

            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _BENLogoParticlePainter(
                    progress: t,
                    maskPoints: _maskPoints,
                  ),
                  size: Size.infinite,
                ),
                if (flash > 0 && flash < 1)
                  IgnorePointer(
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: .11 * (1 - flash)),
                    ),
                  ),
                if (logoOpacity > 0)
                  Center(
                    child: Transform.scale(
                      scale: logoScale,
                      child: Opacity(
                        opacity: logoOpacity,
                        child: Image.asset(
                          'assets/branding/ben_master_logo.png',
                          width: math.min(size.width * .42, 250),
                          fit: BoxFit.contain,
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

class _BENLogoParticlePainter extends CustomPainter {
  _BENLogoParticlePainter({
    required this.progress,
    required this.maskPoints,
  });

  final double progress;
  final List<Offset> maskPoints;

  static const _bg = Color(0xFF05070A);
  static const _gold = Color(0xFFFFD21A);
  static const _hot = Color(0xFFFFF3A0);

  List<Offset>? _starts;
  Size? _startsSize;

  List<Offset> _startPoints(Size size) {
    if (_starts != null && _startsSize == size) return _starts!;
    final rng = math.Random(29071993);
    final points = <Offset>[];
    for (var i = 0; i < maskPoints.length; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final radius = size.shortestSide * (.30 + rng.nextDouble() * .46);
      points.add(Offset(
        size.width / 2 + math.cos(angle) * radius,
        size.height * .43 + math.sin(angle) * radius,
      ));
    }
    _starts = points;
    _startsSize = size;
    return points;
  }

  Offset _logoTopLeft(Size size) {
    final width = math.min(size.width * .42, 250.0);
    final height = width * (1262 / 1139);
    return Offset((size.width - width) / 2, (size.height - height) / 2 - size.height * .035);
  }

  Offset _target(Size size, Offset normalized) {
    final topLeft = _logoTopLeft(size);
    final width = math.min(size.width * .42, 250.0);
    final height = width * (1262 / 1139);
    return Offset(
      topLeft.dx + normalized.dx * width,
      topLeft.dy + normalized.dy * height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(_bg, BlendMode.srcOver);
    if (maskPoints.isEmpty || size.width <= 0 || size.height <= 0) return;

    final starts = _startPoints(size);
    final formation = Curves.easeOutCubic.transform(
      ((progress - .08) / .58).clamp(0.0, 1.0),
    );
    final settle = Curves.easeOutBack.transform(
      ((progress - .58) / .18).clamp(0.0, 1.0),
    );
    final visibility = Curves.easeIn.transform(
      ((progress - .02) / .16).clamp(0.0, 1.0),
    );
    final locked = ((progress - .74) / .18).clamp(0.0, 1.0);
    final pulse = math.sin((progress - .70) * math.pi * 14).abs() *
        ((progress - .68) / .16).clamp(0.0, 1.0);

    final center = Offset(size.width / 2, size.height * .43);
    final ambient = Paint()
      ..color = _gold.withValues(alpha: .035 + .055 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.shortestSide * .11);
    canvas.drawCircle(center, size.shortestSide * (.16 + .05 * pulse), ambient);

    final dot = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(771993);
    for (var i = 0; i < maskPoints.length; i++) {
      final target = _target(size, maskPoints[i]);
      final start = starts[i];
      var p = Offset(
        start.dx + (target.dx - start.dx) * formation,
        start.dy + (target.dy - start.dy) * formation,
      );

      // Tiny settle overshoot makes the particle cloud feel alive instead of
      // simply interpolating from A to B.
      final wobble = (1 - formation) * .7 + settle * .3;
      p += Offset(
        math.sin(i * .73 + progress * 17) * wobble,
        math.cos(i * .51 + progress * 15) * wobble,
      );

      final alpha = (visibility * (1 - locked * .96)).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      final hot = rng.nextDouble() > .88;
      dot.color = (hot ? _hot : _gold).withValues(alpha: alpha);
      canvas.drawCircle(p, hot ? 1.45 : 1.0, dot);
    }

    if (progress >= .62) {
      final ringT = Curves.easeOut.transform(((progress - .62) / .22).clamp(0.0, 1.0));
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + pulse * 2.5
        ..color = _gold.withValues(alpha: .18 * (1 - locked) + .12 * pulse);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * .43),
          width: 230 * (1 + .18 * ringT),
          height: 230 * (1 + .18 * ringT),
        ),
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BENLogoParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.maskPoints != maskPoints;
}
