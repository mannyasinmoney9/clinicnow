import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// A polished "not wired up yet" affordance so no button in the app is ever
/// dead — every tap does *something* real, even if that something is an
/// honest "here's what this will do."
class ComingSoonSheet {
  static void show(
    BuildContext context, {
    required String title,
    String subtitle = 'This is coming in a future update.',
    IconData icon = Icons.rocket_launch_rounded,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(title: title, subtitle: subtitle, icon: icon),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: context.appColors.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ).animate().scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
                duration: 350.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 16),
          Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: context.text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0, duration: 250.ms);
  }
}