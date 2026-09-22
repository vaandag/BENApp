import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class BENSplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const BENSplashScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<BENSplashScreen> createState() => _BENSplashScreenState();
}

class _BENSplashScreenState extends State<BENSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _turns;
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _turns = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _controller.addListener(() {
      if (!mounted) return;
      setState(() => _progress = _controller.value);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });

    _finish();
  }

  Future<void> _finish() async {
    await Future<void>.delayed(const Duration(milliseconds: 2400));
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
      backgroundColor: AppTheme.ink,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 680;
            final logoSize = compact ? 150.0 : 185.0;

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: logoSize + 50,
                      height: logoSize + 80,
                      child: AnimatedBuilder(
                        animation: _turns,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _turns.value * math.pi * 2,
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                        child: Image.asset(
                          'assets/branding/ben_master_logo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'BEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 39,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: compact ? 42 : 58),
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: SizedBox(
                            height: 8,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const ColoredBox(color: Color(0xFF303640)),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progress.clamp(0.0, 1.0),
                                  child: const ColoredBox(color: AppTheme.gold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          _progress >= .98 ? 'Hazır' : 'Yükleniyor...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .68),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
