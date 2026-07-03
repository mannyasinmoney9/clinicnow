import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/signature_widgets.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/connection_banner.dart';
import '../../shared/widgets/notification_bell.dart';
import '../auth/presentation/auth_providers.dart';
import '../queue/presentation/queue_providers.dart';
import 'animated_menu_button.dart';

const _demoClinicId = 1;

class StaffHomePage extends ConsumerWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final themeMode = ref.watch(themeModeProvider);
    final snapshotAsync = ref.watch(queueSnapshotProvider(_demoClinicId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Staff — ${user?.firstName ?? ''}'),
        actions: [
          ThemeToggle(
            isDark: themeMode == ThemeMode.dark,
            onChanged: (dark) => ref
                .read(themeModeProvider.notifier)
                .set(dark ? ThemeMode.dark : ThemeMode.light),
          ),
          const SizedBox(width: AppSpacing.sm),
          const NotificationBell(),
          const LivePill(),
          const SizedBox(width: AppSpacing.sm),
          AnimatedMenuButton(
            onSelected: (v) async {
              if (v == 'profile') context.go('/profile');
              if (v == 'system-status') context.go('/system-status');
              if (v == 'settings') context.go('/profile');
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectionBanner(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.trustTeal,
              onRefresh: () async =>
                  ref.invalidate(queueSnapshotProvider(_demoClinicId)),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    snapshotAsync.when(
                      loading: () => Row(
                        children: [
                          _StatCard(label: 'Waiting', value: '...', icon: Icons.people_outline_rounded, color: AppColors.waitAmber, index: 0),
                          const SizedBox(width: AppSpacing.md),
                          _StatCard(label: 'Called', value: '...', icon: Icons.campaign_rounded, color: AppColors.trustTeal, index: 1),
                          const SizedBox(width: AppSpacing.md),
                          _StatCard(label: 'Seen', value: '...', icon: Icons.check_circle_outline_rounded, color: AppColors.nairaGreen, index: 2),
                        ],
                      ),
                      error: (_, _) => Row(
                        children: [
                          _StatCard(label: 'Waiting', value: '0', icon: Icons.people_outline_rounded, color: AppColors.waitAmber, index: 0),
                          const SizedBox(width: AppSpacing.md),
                          _StatCard(label: 'Called', value: '0', icon: Icons.campaign_rounded, color: AppColors.trustTeal, index: 1),
                          const SizedBox(width: AppSpacing.md),
                          _StatCard(label: 'Seen', value: '0', icon: Icons.check_circle_outline_rounded, color: AppColors.nairaGreen, index: 2),
                        ],
                      ),
                      data: (snapshot) {
                        final waiting = snapshot.entries.where((e) => e.isWaiting).length;
                        final called = snapshot.entries.where((e) => e.isCalled).length;
                        final seen = snapshot.entries.where((e) => e.status == 'SEEN').length;
                        return Row(
                          children: [
                            _StatCard(label: 'Waiting', value: '$waiting', icon: Icons.people_outline_rounded, color: AppColors.waitAmber, index: 0),
                            const SizedBox(width: AppSpacing.md),
                            _StatCard(label: 'Called', value: '$called', icon: Icons.campaign_rounded, color: AppColors.trustTeal, index: 1),
                            const SizedBox(width: AppSpacing.md),
                            _StatCard(label: 'Seen', value: '$seen', icon: Icons.check_circle_outline_rounded, color: AppColors.nairaGreen, index: 2),
                          ],
                        );
                      },
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
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () => context.go(
                        '/teleconsult',
                        extra: {'asStaff': true},
                      ),
                      icon: const Icon(Icons.video_call_rounded),
                      label: const Text('Join Video Consult'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                    ).animate().fadeIn(delay: 380.ms, duration: 400.ms),
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
