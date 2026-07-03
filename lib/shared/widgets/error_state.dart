import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import 'primary_button.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: context.colors.error.withValues(alpha: 0.7),
            ).animate().shake(hz: 2, offset: const Offset(4, 0), duration: 500.ms),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Something went wrong',
              style: context.text.titleMedium
                  ?.copyWith(color: context.colors.error),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: context.text.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: retryLabel,
              onPressed: onRetry,
              fullWidth: false,
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}
