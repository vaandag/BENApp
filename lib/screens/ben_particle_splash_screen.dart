import 'package:flutter/material.dart';

/// Minimal BEN startup screen: a white progress bar on a pure black canvas.
class BENParticleSplashScreen extends StatefulWidget {
  const BENParticleSplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<BENParticleSplashScreen> createState() =>
      _BENParticleSplashScreenState();
}

class _BENParticleSplashScreenState extends State<BENParticleSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1850);

  late final AnimationController _controller;
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
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = MediaQuery.sizeOf(context).width * .74;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: barWidth.clamp(180.0, 380.0).toDouble(),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final percent = (_controller.value * 100).round();
                return Semantics(
                  label: 'BEN yükleniyor',
                  value: '$percent%',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _controller.value,
                      minHeight: 4,
                      backgroundColor: const Color(0xFF3A3A3A),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
