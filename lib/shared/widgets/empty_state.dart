import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_theme.dart';
import 'primary_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.lottieAsset,
    this.icon = Icons.inbox_outlined,
    this.ctaLabel,
    this.onCta,
  });

  final String title;
  final String? subtitle;
  final String? lottieAsset;
  final IconData icon;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lottieAsset != null)
            Lottie.asset(lottieAsset!, width: 160, height: 160)
          else
            Icon(
              icon,
              size: 64,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.35),
            )
                .animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),
          const SizedBox(height: AppSpacing.lg),
          Text(title,
              style: context.text.titleMedium,
              textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle!,
                style: context.text.bodyMedium,
                textAlign: TextAlign.center),
          ],
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: ctaLabel!,
              onPressed: onCta,
              fullWidth: false,
            ),
          ],
        ],
      ).animate().fadeIn(duration: 350.ms),
    );
  }
}
