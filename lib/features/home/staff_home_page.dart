import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/widgets/signature_widgets.dart';
import '../auth/presentation/auth_providers.dart';

class StaffHomePage extends ConsumerWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final s = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text('Staff — ${user?.firstName ?? ''}'),
        actions: [
          const LivePill(),
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/login');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'logout', child: Text(s.logout)),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                _StatCard(
                  label: 'Waiting',
                  value: '0',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.waitAmber,
                  index: 0,
                ),
                const SizedBox(width: AppSpacing.md),
                _StatCard(
                  label: 'Seen today',
                  value: '0',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.nairaGreen,
                  index: 1,
                ),
                const SizedBox(width: AppSpacing.md),
                _StatCard(
                  label: 'Urgent',
                  value: '0',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.emergencyRed,
                  index: 2,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Text('Live Queue', style: context.text.titleMedium),
                const SizedBox(width: AppSpacing.sm),
                const LivePulseDot(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.go('/queue/staff'),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Live Queue Board'),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadii.rMd,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: AppType.numeric(context, size: 28)
                    .copyWith(color: color)),
            Text(label, style: context.text.labelSmall),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 80))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.1, end: 0, duration: 350.ms),
    );
  }
}
