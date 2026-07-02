import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Beautiful back button that integrates with go_router.
/// Use as AppBar `leading:` or as a Positioned overlay on full-screen pages.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.color,
    this.onPressed,
    this.tooltip = 'Go back',
  });

  final Color? color;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.trustTeal;
    return Tooltip(
      message: tooltip,
      child: _GlowBackButton(
        color: effectiveColor,
        onPressed: onPressed ?? () => _goBack(context),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.3, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // Fallback: go to root if there's nothing to pop
      context.go('/');
    }
  }
}

class _GlowBackButton extends StatefulWidget {
  const _GlowBackButton({required this.color, required this.onPressed});
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_GlowBackButton> createState() => _GlowBackButtonState();
}

class _GlowBackButtonState extends State<_GlowBackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withAlpha(18),
            border: Border.all(color: widget.color.withAlpha(60), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(40),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

/// A back button styled for dark/overlay backgrounds (e.g. OTP page).
class AppBackButtonDark extends StatelessWidget {
  const AppBackButtonDark({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppBackButton(
      color: Colors.white,
      onPressed: onPressed,
    );
  }
}