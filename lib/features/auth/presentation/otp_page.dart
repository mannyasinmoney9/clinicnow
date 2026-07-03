import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';
import 'auth_providers.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key, required this.email, this.demoOtpCode});
  final String email;
  final String? demoOtpCode;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage>
    with TickerProviderStateMixin {
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _controllers = List.generate(6, (_) => TextEditingController());
  bool _showDemoCode = false;
  bool _isVerifying = false;
  String? _errorMsg;

  late final AnimationController _bgCtrl;
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: 3000.ms)..repeat();
    _shakeCtrl = AnimationController(vsync: this, duration: 400.ms);
  }

  @override
  void dispose() {
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    _bgCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _enteredCode =>
      _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[math.min(5, digits.length - 1)].requestFocus();
      if (digits.length == 6) _verify();
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_enteredCode.length == 6) _verify();
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    if (_enteredCode.length != 6) return;
    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(widget.email, _enteredCode);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  Future<void> _resend() async {
    try {
      final result =
          await ref.read(authRepositoryProvider).resendOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'New OTP sent! Demo code: ${result ?? '------'}'),
          backgroundColor: AppColors.nairaGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend: $e'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (!context.mounted) return;
      if (next is AuthAuthenticated) {
        final role = next.user.role;
        if (role.name == 'admin') {
          context.go('/home/admin');
        } else if (next.user.isStaffOrAdmin) {
          context.go('/home/staff');
        } else {
          context.go('/home/patient');
        }
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, _) => CustomPaint(
                painter: _OtpBgPainter(_bgCtrl.value),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Back button overlay (top-left, styled for dark background)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: const AppBackButtonDark(),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 56), // extra space so content clears the back button

                    // Icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.trustTeal, AppColors.nairaGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.nairaGreen.withAlpha(80),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1.0, 1.0),
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 28),

                    Text(
                      'Verify your account',
                      style: context.text.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 500.ms),

                    const SizedBox(height: 10),

                    Text(
                      'Enter the 6-digit code for\n${widget.email}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(170),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms),

                    const SizedBox(height: 36),

                    // OTP boxes
                    AnimatedBuilder(
                      animation: _shakeCtrl,
                      builder: (_, child) {
                        final shake =
                            math.sin(_shakeCtrl.value * 4 * math.pi) * 8.0;
                        return Transform.translate(
                          offset: Offset(shake, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) => _OtpBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          onChanged: (v) => _onDigitChanged(i, v),
                          onKeyEvent: (e) => _onKeyEvent(i, e),
                          index: i,
                        )),
                      ),
                    ),

                    if (_errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.emergencyRed.withAlpha(80)),
                        ),
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(
                              color: Color(0xFFFFCDD2), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                    ],

                    const SizedBox(height: 28),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isVerifying || _enteredCode.length < 6
                            ? null
                            : _verify,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.nairaGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white),
                              )
                            : const Text('Verify Code',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: _resend,
                      child: Text(
                        'Resend code',
                        style: TextStyle(color: Colors.white.withAlpha(180)),
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                    // Demo code reveal
                    if (widget.demoOtpCode != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _showDemoCode = !_showDemoCode),
                        icon: Icon(
                          _showDemoCode
                              ? Icons.visibility_off_outlined
                              : Icons.bug_report_outlined,
                          size: 16,
                          color: AppColors.waitAmber,
                        ),
                        label: Text(
                          _showDemoCode
                              ? 'Hide demo code'
                              : 'Show demo code (dev only)',
                          style: const TextStyle(
                              color: AppColors.waitAmber, fontSize: 12),
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                      if (_showDemoCode)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.waitAmber.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.waitAmber.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_open_rounded,
                                  size: 16, color: AppColors.waitAmber),
                              const SizedBox(width: 8),
                              Text(
                                'Code: ${widget.demoOtpCode}',
                                style: const TextStyle(
                                  color: AppColors.waitAmber,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 8,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.0, 1.0),
                                duration: 300.ms,
                                curve: Curves.easeOutBack),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual OTP digit box
// ---------------------------------------------------------------------------

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
    required this.index,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;
  final int index;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: 48,
        height: 58,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white.withAlpha(20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.trustTeal.withAlpha(80)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.nairaGreen, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withAlpha(40)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 400 + index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ---------------------------------------------------------------------------
// Background painter
// ---------------------------------------------------------------------------

class _OtpBgPainter extends CustomPainter {
  const _OtpBgPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF040E0D), Color(0xFF0A2928)],
          ).createShader(Offset.zero & size));

    for (int i = 0; i < 3; i++) {
      final phase = (t + i * 0.33) % 1.0;
      final glow = Paint()
        ..color = AppColors.trustTeal
            .withAlpha((10 + 8 * math.sin(phase * 2 * math.pi)).toInt());
      canvas.drawCircle(
        Offset(size.width * [0.2, 0.8, 0.5][i],
            size.height * [0.3, 0.6, 0.15][i]),
        size.width * 0.4,
        glow,
      );
    }
  }

  @override
  bool shouldRepaint(_OtpBgPainter old) => old.t != t;
}