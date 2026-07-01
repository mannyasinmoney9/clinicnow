import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class ThankYouPage extends StatefulWidget {
  const ThankYouPage({super.key});

  @override
  State<ThankYouPage> createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _starCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: 4000.ms)..repeat();
    _starCtrl =
        AnimationController(vsync: this, duration: 3000.ms)..repeat();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_bgCtrl, _starCtrl]),
          builder: (context, _) {
            return Stack(
              children: [
                // ---- Animated background ----
                CustomPaint(
                  painter: _ThankYouBgPainter(
                    bgPhase: _bgCtrl.value,
                    starPhase: _starCtrl.value,
                  ),
                  child: const SizedBox.expand(),
                ),

                // ---- Central content ----
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glowing medical cross
                        _GlowingCross(phase: _bgCtrl.value)
                            .animate()
                            .scale(
                              begin: const Offset(0.0, 0.0),
                              end: const Offset(1.0, 1.0),
                              duration: 900.ms,
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn(duration: 600.ms),

                        const SizedBox(height: 48),

                        // "THANK YOU"
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [
                              Color(0xFF06D6A0),
                              Color(0xFF0BA5A4),
                              Color(0xFF10B981),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'THANK YOU',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                              height: 1.1,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 700.ms)
                            .slideY(
                                begin: 0.4,
                                end: 0,
                                delay: 400.ms,
                                duration: 700.ms,
                                curve: Curves.easeOutCubic),

                        const SizedBox(height: 8),

                        Text(
                          'FOR CHOOSING',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withAlpha(180),
                            letterSpacing: 8,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 600.ms)
                            .slideY(
                                begin: 0.3, end: 0, delay: 700.ms, duration: 600.ms),

                        const SizedBox(height: 4),

                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [
                              Color(0xFFF59E0B),
                              Color(0xFFFC8B21),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'CLINICNOW',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 6,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 900.ms, duration: 700.ms)
                            .scale(
                              begin: const Offset(0.7, 0.7),
                              end: const Offset(1.0, 1.0),
                              delay: 900.ms,
                              duration: 700.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 48),

                        Text(
                          'Your health journey starts now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withAlpha(140),
                            letterSpacing: 0.5,
                            height: 1.6,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 1200.ms, duration: 600.ms),

                        const SizedBox(height: 32),

                        // Progress indicator
                        SizedBox(
                          width: size.width * 0.5,
                          child: LinearProgressIndicator(
                            value: _bgCtrl.value,
                            backgroundColor: Colors.white.withAlpha(30),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.nairaGreen),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ).animate().fadeIn(delay: 1400.ms, duration: 400.ms),
                      ],
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

// ---------------------------------------------------------------------------
// Glowing cross widget
// ---------------------------------------------------------------------------

class _GlowingCross extends StatelessWidget {
  const _GlowingCross({required this.phase});
  final double phase;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + 0.06 * math.sin(phase * 2 * math.pi);
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 80,
        height: 80,
        child: CustomPaint(painter: _CrossPainter(phase)),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final t = size.width / 3.5;

    final glowPaint = Paint()
      ..color = AppColors.nairaGreen.withAlpha(
          (120 + 80 * math.sin(phase * 2 * math.pi)).toInt())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF06D6A0), Color(0xFF0BA5A4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy),
              width: size.width,
              height: t),
          const Radius.circular(8)))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy),
              width: t,
              height: size.height),
          const Radius.circular(8)));

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.phase != phase;
}

// ---------------------------------------------------------------------------
// Animated background
// ---------------------------------------------------------------------------

class _ThankYouBgPainter extends CustomPainter {
  const _ThankYouBgPainter(
      {required this.bgPhase, required this.starPhase});
  final double bgPhase;
  final double starPhase;

  static const _stars = [
    (0.10, 0.10), (0.85, 0.08), (0.55, 0.18), (0.25, 0.30),
    (0.90, 0.35), (0.05, 0.55), (0.70, 0.60), (0.40, 0.72),
    (0.15, 0.82), (0.80, 0.85), (0.50, 0.95), (0.95, 0.70),
    (0.30, 0.92), (0.65, 0.42), (0.45, 0.55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF040E0D), Color(0xFF0A1F1E), Color(0xFF071412)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Animated glow orbs
    for (int i = 0; i < 3; i++) {
      final phase = (bgPhase + i / 3) % 1.0;
      final x = size.width * [0.2, 0.7, 0.5][i];
      final y = size.height * [0.3, 0.6, 0.15][i];
      final r = size.width * 0.35;
      final glow = Paint()
        ..color = [
          AppColors.trustTeal,
          AppColors.nairaGreen,
          AppColors.waitAmber,
        ][i]
            .withAlpha((12 + 8 * math.sin(phase * 2 * math.pi)).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(Offset(x, y), r, glow);
    }

    // Twinkling stars
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _stars.length; i++) {
      final (nx, ny) = _stars[i];
      final twinkle =
          math.sin((starPhase + i * 0.17) * 2 * math.pi).abs();
      final r = 2.0 + twinkle * 2.0;
      starPaint.color = Colors.white.withAlpha((80 + 120 * twinkle).toInt());
      canvas.drawCircle(
          Offset(nx * size.width, ny * size.height), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(_ThankYouBgPainter old) =>
      old.bgPhase != bgPhase || old.starPhase != starPhase;
}