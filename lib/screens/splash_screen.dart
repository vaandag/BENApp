import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scale = Tween<double>(
      begin: .94,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
    _runLoading();
  }

  Future<void> _runLoading() async {
    const steps = 44;

    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 38));
      if (!mounted) return;
      setState(() => _progress = i / steps);
    }

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1014),
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final spin = Curves.easeOutCubic.transform(_controller.value.clamp(0.0, 1.0));
              return Opacity(
                opacity: _fade.value,
                child: Transform.rotate(
                  angle: (1.0 - spin) * math.pi * 2,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/branding/benapp_wordmark_clean.png',
                    width: 280,
                    height: 280,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 42),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xFF303640)),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progress,
                            child: const ColoredBox(
                              color: Color(0xFFFFD200),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    _progress >= .995 ? 'Hazır' : 'Yükleniyor...',
                    style: const TextStyle(
                      color: Color(0xFFD5D9E0),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
