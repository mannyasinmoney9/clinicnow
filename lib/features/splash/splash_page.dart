import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../auth/presentation/auth_providers.dart';

// ---------------------------------------------------------------------------
// Splash — 10-second spinning needle
// ---------------------------------------------------------------------------

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _ecgCtrl;
  late final AnimationController _appearCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _ecgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _appearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _appearCtrl.forward();
    });

    _navigate();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _ecgCtrl.dispose();
    _glowCtrl.dispose();
    _appearCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 10));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;
    if (!mounted) return;

    if (!seenOnboarding) {
      context.go('/onboarding');
      return;
    }

    if (ref.read(authProvider) is AuthLoading) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
    }

    final auth = ref.read(authProvider);
    if (!mounted) return;
    if (auth is AuthAuthenticated) {
      if (auth.user.role.name == 'admin') {
        context.go('/home/admin');
      } else if (auth.user.isStaffOrAdmin) {
        context.go('/home/staff');
      } else {
        context.go('/home/patient');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040E0D),
      body: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _spinCtrl,
            _pulseCtrl,
            _ecgCtrl,
            _appearCtrl,
            _glowCtrl,
          ]),
          builder: (context, _) {
            return Stack(
              children: [
                // Background + needle + rings
                CustomPaint(
                  painter: _SplashPainter(
                    rotation: _spinCtrl.value * 2 * math.pi,
                    pulse: _pulseCtrl.value,
                    ecgProgress: _ecgCtrl.value,
                    glowIntensity: _glowCtrl.value,
                  ),
                  child: const SizedBox.expand(),
                ),

                // Logo + tagline (appears at 1.8s)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _appearCtrl.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _appearCtrl.value)),
                      child: Column(
                        children: [
                          Text(
                            'ClinicNow',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: AppColors.nairaGreen.withAlpha(180),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your health, your queue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withAlpha(160),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Version / loading dots at bottom
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _appearCtrl.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final phase = ((_spinCtrl.value * 3) - i * 0.3) % 1.0;
                        final t = math.sin(phase * math.pi).clamp(0.0, 1.0);
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.nairaGreen.withAlpha(
                              (80 + 175 * t).toInt(),
                            ),
                          ),
                        );
                      }),
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
// Master canvas — needle + rings + particles + ECG
// ---------------------------------------------------------------------------

class _SplashPainter extends CustomPainter {
  const _SplashPainter({
    required this.rotation,
    required this.pulse,
    required this.ecgProgress,
    required this.glowIntensity,
  });

  final double rotation;
  final double pulse;
  final double ecgProgress;
  final double glowIntensity;

  // Pre-seeded particle positions (deterministic so no jitter)
  static const _particleSeeds = [
    (0.12, 0.22, 1.0),
    (0.88, 0.15, 0.8),
    (0.25, 0.65, 0.6),
    (0.75, 0.72, 0.9),
    (0.05, 0.50, 0.7),
    (0.92, 0.44, 0.5),
    (0.40, 0.10, 1.0),
    (0.60, 0.88, 0.6),
    (0.18, 0.85, 0.8),
    (0.82, 0.30, 0.7),
    (0.50, 0.05, 0.5),
    (0.35, 0.75, 0.9),
    (0.70, 0.50, 0.4),
    (0.15, 0.40, 0.6),
    (0.85, 0.78, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    _drawBackground(canvas, size, center);
    _drawOrbitRings(canvas, size, center);
    _drawParticles(canvas, size, center);
    _drawNeedle(canvas, size, center);
    _drawEcg(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        colors: [const Color(0xFF0A2E2D), const Color(0xFF040E0D)],
        stops: const [0.0, 1.0],
        radius: 0.85,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawOrbitRings(Canvas canvas, Size size, Offset center) {
    for (int i = 1; i <= 5; i++) {
      final base = size.shortestSide * 0.12 * i;
      final r = base + base * 0.04 * pulse;
      final opacity = (0.18 - i * 0.025).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = AppColors.trustTeal.withAlpha(
          ((opacity + opacity * 0.5 * glowIntensity) * 255).toInt().clamp(
            0,
            255,
          ),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(center, r, paint);
    }

    // Bright innermost glow circle
    final glowPaint = Paint()
      ..color = AppColors.nairaGreen.withAlpha(
        (40 + 30 * glowIntensity).toInt(),
      );
    canvas.drawCircle(
      center,
      size.shortestSide * 0.22 * (1 + 0.03 * pulse),
      glowPaint,
    );
  }

  void _drawParticles(Canvas canvas, Size size, Offset center) {
    for (final (normX, normY, speed) in _particleSeeds) {
      // Drift upward over time, wrap around
      final y =
          ((normY - rotation / (2 * math.pi) * speed * 0.3) % 1.0) *
          size.height;
      final x = normX * size.width;
      final dist = (Offset(x, y) - center).distance;
      // Fade out near center and far edges
      final fade = (1.0 - (dist / (size.shortestSide * 0.55)).clamp(0.0, 1.0))
          .clamp(0.0, 1.0);
      if (fade < 0.05) continue;

      final crossPaint = Paint()
        ..color = AppColors.nairaGreen.withAlpha((80 * fade).toInt())
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      const s = 4.0;
      canvas.drawLine(Offset(x - s, y), Offset(x + s, y), crossPaint);
      canvas.drawLine(Offset(x, y - s), Offset(x, y + s), crossPaint);
    }
  }

  void _drawNeedle(Canvas canvas, Size size, Offset center) {
    final r = size.shortestSide * 0.30;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // ---- outer glow ----
    final glowPaint = Paint()
      ..color = AppColors.nairaGreen.withAlpha(
        (55 + 40 * glowIntensity).toInt(),
      );

    final needlePath = _buildNeedlePath(r);
    canvas.drawPath(needlePath, glowPaint);
    canvas.drawPath(_buildPlungerPath(r), glowPaint);

    // ---- barrel body ----
    final barrelPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF06D6A0),
          AppColors.nairaGreen,
          const Color(0xFF059669),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-r * 0.15, -6, r * 0.85, 12));
    canvas.drawPath(needlePath, barrelPaint);

    // ---- barrel fluid fill ----
    final fluidPaint = Paint()
      ..color = AppColors.trustTeal.withAlpha(140)
      ..style = PaintingStyle.fill;
    final fluidPath = Path()
      ..moveTo(-r * 0.05, -5)
      ..lineTo(-r * 0.05, 5)
      ..lineTo(r * 0.40, 5)
      ..lineTo(r * 0.40, -5)
      ..close();
    canvas.drawPath(fluidPath, fluidPaint);

    // ---- graduation marks ----
    final markPaint = Paint()
      ..color = Colors.white.withAlpha(80)
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 5; i++) {
      final x = -r * 0.05 + (r * 0.75 - (-r * 0.05)) * i / 6;
      canvas.drawLine(Offset(x, -5), Offset(x, 5), markPaint);
    }

    // ---- plunger ----
    final plungerPaint = Paint()..color = Colors.white.withAlpha(220);
    canvas.drawPath(_buildPlungerPath(r), plungerPaint);

    canvas.restore();

    // ---- center pivot ----
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = AppColors.nairaGreen.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF1A3A38));
    canvas.drawCircle(center, 6, Paint()..color = AppColors.nairaGreen);
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  Path _buildNeedlePath(double r) {
    return Path()
      ..moveTo(-r * 0.15, -6)
      ..lineTo(-r * 0.15, 6)
      ..lineTo(r * 0.72, 5)
      ..lineTo(r * 0.72, -5)
      ..lineTo(r * 0.88, -2)
      ..lineTo(r * 1.02, 0) // needle tip
      ..lineTo(r * 0.88, 2)
      ..lineTo(r * 0.72, 5)
      ..close();
  }

  Path _buildPlungerPath(double r) {
    final path = Path();
    // Rod
    path.addRect(Rect.fromLTWH(-r * 0.15 - 22, -2.5, 22, 5));
    // T-handle top bar
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-r * 0.15 - 30, -10, 8, 20),
        const Radius.circular(3),
      ),
    );
    return path;
  }

  void _drawEcg(Canvas canvas, Size size) {
    final ecgPaint = Paint()
      ..color = AppColors.nairaGreen.withAlpha(180)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final baseY = size.height * 0.88;
    final amp = size.height * 0.06;

    // PQRST normalized points
    const pts = [
      (0.00, 0.00),
      (0.06, 0.00),
      (0.10, -0.08),
      (0.14, 0.00),
      (0.22, 0.00),
      (0.26, -0.12),
      (0.28, -0.85),
      (0.30, -1.00),
      (0.32, 0.40),
      (0.34, 0.00),
      (0.40, 0.00),
      (0.46, -0.18),
      (0.52, 0.00),
      (0.65, 0.00),
      (1.00, 0.00),
    ];

    // Two scrolling copies side by side
    for (int copy = -1; copy <= 1; copy++) {
      final offset = (ecgProgress + copy) * w;
      final path = Path();
      path.moveTo(offset + pts[0].$1 * w, baseY + pts[0].$2 * amp);
      for (final (x, y) in pts.skip(1)) {
        path.lineTo(offset + x * w, baseY + y * amp);
      }
      canvas.drawPath(path, ecgPaint);
    }

    // Gradient fade mask for the edges
    final fadePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF040E0D),
          Colors.transparent,
          Colors.transparent,
          const Color(0xFF040E0D),
        ],
        stops: const [0.0, 0.08, 0.92, 1.0],
      ).createShader(Rect.fromLTWH(0, baseY - amp * 1.5, w, amp * 3));
    canvas.drawRect(Rect.fromLTWH(0, baseY - amp * 1.5, w, amp * 3), fadePaint);
  }

  @override
  bool shouldRepaint(_SplashPainter old) =>
      old.rotation != rotation ||
      old.pulse != pulse ||
      old.ecgProgress != ecgProgress ||
      old.glowIntensity != glowIntensity;
}
