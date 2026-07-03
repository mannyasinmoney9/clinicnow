import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/signature_widgets.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/coming_soon_sheet.dart';
import '../../shared/widgets/notification_bell.dart';
import '../auth/presentation/auth_providers.dart';
import '../queue/presentation/queue_providers.dart';
import 'animated_menu_button.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: 3000.ms)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final themeMode = ref.watch(themeModeProvider);
    final snapshotAsync = ref.watch(queueSnapshotProvider(1));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(user?.email ?? '',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, child) {
              final glow = 0.2 + 0.15 * _glowCtrl.value;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.emergencyRed.withAlpha(60)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergencyRed.withAlpha((glow * 255).toInt()),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 12, color: AppColors.emergencyRed),
                    SizedBox(width: 4),
                    Text('Admin',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.emergencyRed,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            },
          ),
          ThemeToggle(
            isDark: themeMode == ThemeMode.dark,
            onChanged: (dark) => ref
                .read(themeModeProvider.notifier)
                .set(dark ? ThemeMode.dark : ThemeMode.light),
          ),
          const SizedBox(width: 4),
          const NotificationBell(),
          AnimatedMenuButton(
            onSelected: (v) async {
              if (v == 'profile') context.go('/profile');
              if (v == 'system-status') context.go('/system-status');
              if (v == 'settings') context.go('/profile');
              if (v == 'about') {
                ComingSoonSheet.show(
                  context,
                  title: 'About ClinicNow',
                  subtitle: 'ClinicNow v1.0.0-alpha — Real-time queue management for Nigerian clinics.',
                  icon: Icons.info_outline_rounded,
                );
              }
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(queueSnapshotProvider(1)),
        color: AppColors.trustTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Live Overview',
                      style: context.text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 14),
              snapshotAsync.when(
                loading: () => Row(
                  children: [
                    _StatCard(label: 'Waiting', value: '...', icon: Icons.people_outline_rounded, color: AppColors.waitAmber, index: 0),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Called', value: '...', icon: Icons.campaign_rounded, color: AppColors.trustTeal, index: 1),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Seen', value: '...', icon: Icons.check_circle_outline_rounded, color: AppColors.nairaGreen, index: 2),
                  ],
                ),
                error: (_, _) => Row(
                  children: [
                    _StatCard(label: 'Waiting', value: '0', icon: Icons.people_outline_rounded, color: AppColors.waitAmber, index: 0),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Called', value: '0', icon: Icons.campaign_rounded, color: AppColors.trustTeal, index: 1),
                    const SizedBox(width: 12),
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
                      const SizedBox(width: 12),
                      _StatCard(label: 'Called', value: '$called', icon: Icons.campaign_rounded, color: AppColors.trustTeal, index: 1),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Seen', value: '$seen', icon: Icons.check_circle_outline_rounded, color: AppColors.nairaGreen, index: 2),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              Text('Quick Actions',
                      style: context.text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _ActionTile(
                    icon: Icons.queue_rounded,
                    label: 'Live Queue',
                    subtitle: 'Real-time board',
                    color: AppColors.trustTeal,
                    onTap: () => context.go('/queue/staff'),
                    index: 0,
                  ),
                  _ActionTile(
                    icon: Icons.system_update_rounded,
                    label: 'System Status',
                    subtitle: 'Health & diagnostics',
                    color: AppColors.nairaGreen,
                    onTap: () => context.go('/system-status'),
                    index: 1,
                  ),
                  _ActionTile(
                    icon: Icons.people_rounded,
                    label: 'Staff',
                    subtitle: 'Manage team',
                    color: const Color(0xFF7C3AED),
                    onTap: () => ComingSoonSheet.show(
                      context,
                      title: 'Staff management',
                      subtitle: 'Add, assign, and manage staff accounts from here once the backend is connected.',
                      icon: Icons.people_rounded,
                    ),
                    index: 2,
                  ),
                  _ActionTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    subtitle: 'Patient analytics',
                    color: AppColors.waitAmber,
                    onTap: () => ComingSoonSheet.show(
                      context,
                      title: 'Reports & analytics',
                      subtitle: 'Hourly throughput, symptom mix, and trend charts are on the roadmap.',
                      icon: Icons.bar_chart_rounded,
                    ),
                    index: 3,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text('Demo Accounts',
                      style: context.text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms),
              const SizedBox(height: 12),
              ..._demoAccounts.asMap().entries.map(
                (e) => _AccountRow(
                  email: e.value.$1,
                  role: e.value.$2,
                  password: e.value.$3,
                ).animate().fadeIn(
                    delay: Duration(milliseconds: 400 + e.key * 60),
                    duration: 400.ms),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static const _demoAccounts = [
    ('manniboh@gmail.com', 'ADMIN', 'Password123'),
    ('patient@demo.com', 'PATIENT', 'DemoPass123'),
    ('staff@demo.com', 'STAFF', 'DemoPass123'),
  ];
}

// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.index});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: context.text.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 80))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, duration: 400.ms),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap,
      required this.index});
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: context.text.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: context.text.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 250 + index * 70))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow(
      {required this.email,
      required this.role,
      required this.password});
  final String email;
  final String role;
  final String password;

  @override
  Widget build(BuildContext context) {
    final roleColor = role == 'ADMIN'
        ? AppColors.emergencyRed
        : role == 'STAFF'
            ? AppColors.trustTeal
            : AppColors.nairaGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(role,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: roleColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text(password,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
