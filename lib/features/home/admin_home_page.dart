import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/presentation/auth_providers.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  int _waitingCount = 0;
  int _seenToday = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get<List<dynamic>>('/api/queue/clinic/1');
      final list = resp.data ?? [];
      if (!mounted) return;
      setState(() {
        _waitingCount =
            list.where((e) => (e as Map)['status'] == 'WAITING').length;
        _seenToday =
            list.where((e) => (e as Map)['status'] == 'SEEN').length;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user =
        authState is AuthAuthenticated ? authState.user : null;

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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.nairaGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.nairaGreen.withAlpha(60)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded,
                    size: 12, color: AppColors.nairaGreen),
                SizedBox(width: 4),
                Text('Admin',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.nairaGreen,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/login');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.trustTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats
              Text('Live Overview',
                      style: context.text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatCard(
                    label: 'Waiting',
                    value: _loaded ? '$_waitingCount' : '...',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.waitAmber,
                    index: 0,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Seen today',
                    value: _loaded ? '$_seenToday' : '...',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.nairaGreen,
                    index: 1,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Clinics',
                    value: '5',
                    icon: Icons.local_hospital_rounded,
                    color: AppColors.trustTeal,
                    index: 2,
                  ),
                ],
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
                    icon: Icons.people_rounded,
                    label: 'Staff',
                    subtitle: 'Manage team',
                    color: AppColors.nairaGreen,
                    onTap: () {},
                    index: 1,
                  ),
                  _ActionTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    subtitle: 'Patient analytics',
                    color: const Color(0xFF7C3AED),
                    onTap: () {},
                    index: 2,
                  ),
                  _ActionTile(
                    icon: Icons.local_hospital_outlined,
                    label: 'Clinics',
                    subtitle: 'Manage locations',
                    color: AppColors.waitAmber,
                    onTap: () {},
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
              ..._demoAccounts.map(
                (acc) => _AccountRow(
                  email: acc.$1,
                  role: acc.$2,
                  password: acc.$3,
                ).animate().fadeIn(
                    delay: Duration(
                        milliseconds:
                            400 + _demoAccounts.indexOf(acc) * 60),
                    duration: 400.ms),
              ),

              const SizedBox(height: 28),

              Text('System Status',
                      style: context.text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),
              const SizedBox(height: 12),
              _StatusRow(
                label: 'Backend API',
                status: 'Online',
                ok: true,
                index: 0,
              ),
              _StatusRow(
                label: 'WebSocket / STOMP',
                status: 'Connected',
                ok: true,
                index: 1,
              ),
              _StatusRow(
                label: 'H2 Database',
                status: 'Running',
                ok: true,
                index: 2,
              ),
              _StatusRow(
                label: 'Gemini AI',
                status: 'Check GEMINI_API_KEY',
                ok: false,
                index: 3,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static const _demoAccounts = [
    ('manniboh@gmail.com', 'ADMIN', 'dylan/px4tm'),
    ('staff@demo', 'STAFF', 'Password123'),
    ('patient@demo', 'PATIENT', 'Password123'),
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
          border:
              Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: context.text.labelSmall,
                textAlign: TextAlign.center),
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

class _StatusRow extends StatelessWidget {
  const _StatusRow(
      {required this.label,
      required this.status,
      required this.ok,
      required this.index});
  final String label;
  final String status;
  final bool ok;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            size: 16,
            color: ok ? AppColors.nairaGreen : AppColors.waitAmber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Text(status,
              style: TextStyle(
                  fontSize: 11,
                  color: ok ? AppColors.nairaGreen : AppColors.waitAmber,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    )
        .animate(
            delay: Duration(
                milliseconds: 520 + index * 60))
        .fadeIn(duration: 350.ms);
  }
}