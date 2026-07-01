import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class SuccessOverlay extends StatelessWidget {
  const SuccessOverlay({
    super.key,
    required this.message,
    this.subtitle,
  });

  final String message;
  final String? subtitle;

  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    Duration duration = const Duration(seconds: 2),
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => SuccessOverlay(message: message, subtitle: subtitle),
    );
    Future.delayed(duration, () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xxl),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppRadii.rXl,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.appColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 40, color: context.appColors.success),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.2, 0.2),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 250.ms),
              const SizedBox(height: AppSpacing.lg),
              Text(message,
                  style: context.text.titleMedium,
                  textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 300.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 200.ms,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle!,
                    style: context.text.bodySmall,
                    textAlign: TextAlign.center)
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 300.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
