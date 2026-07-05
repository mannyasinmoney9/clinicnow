import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/env.dart';
import '../../core/network/health_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import '../queue/presentation/queue_providers.dart';

class SystemStatusPage extends ConsumerStatefulWidget {
  const SystemStatusPage({super.key});

  @override
  ConsumerState<SystemStatusPage> createState() => _SystemStatusPageState();
}

class _SystemStatusPageState extends ConsumerState<SystemStatusPage> {
  Timer? _refreshTimer;
  int _uptimeSeconds = 0;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _uptimeSeconds += 5);
      ref.read(healthProvider.notifier).check();
    });
    ref.read(healthProvider.notifier).check();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String get _uptime {
    final h = _uptimeSeconds ~/ 3600;
    final m = (_uptimeSeconds % 3600) ~/ 60;
    final s = _uptimeSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);
    final isStompConnected = ref.watch(stompConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('System Status'),
      ),
      body: RefreshIndicator(
        color: AppColors.trustTeal,
        onRefresh: () async => ref.read(healthProvider.notifier).check(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: health == BackendStatus.ok
                      ? [AppColors.nairaGreen.withAlpha(20), AppColors.nairaGreen.withAlpha(8)]
                      : [AppColors.emergencyRed.withAlpha(20), AppColors.emergencyRed.withAlpha(8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: health == BackendStatus.ok
                      ? AppColors.nairaGreen.withAlpha(60)
                      : AppColors.emergencyRed.withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: health == BackendStatus.ok
                          ? AppColors.nairaGreen.withAlpha(30)
                          : AppColors.emergencyRed.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      health == BackendStatus.ok
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: health == BackendStatus.ok
                          ? AppColors.nairaGreen
                          : AppColors.emergencyRed,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          health == BackendStatus.ok ? 'All Systems Operational' : 'System Degraded',
                          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last checked: just now',
                          style: context.text.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            Text('Services', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700))
                .animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 12),

            _StatusCard(
              label: 'Backend API',
              status: AppConfig.demoMode ? 'Demo mode (local)' : (health == BackendStatus.ok ? 'Connected' : 'Unreachable'),
              ok: AppConfig.demoMode ? true : health == BackendStatus.ok,
              icon: Icons.dns_rounded,
              index: 0,
            ),
            _StatusCard(
              label: 'Live Queue Engine',
              status: AppConfig.demoMode
                  ? (isStompConnected ? 'Ticking locally (STOMP)' : 'Ticking locally (REST)')
                  : (isStompConnected ? 'Connected (STOMP)' : 'Polling (REST fallback)'),
              ok: true,
              icon: Icons.queue_rounded,
              index: 1,
            ),
            _StatusCard(
              label: 'Account Store',
              status: AppConfig.demoMode ? 'On-device (SharedPreferences)' : 'H2 File Database',
              ok: true,
              icon: Icons.people_rounded,
              index: 2,
            ),
            _StatusCard(
              label: 'Nurse Ada (AI)',
              status: AppConfig.demoMode ? 'Offline scripted engine' : 'Check GEMINI_API_KEY',
              ok: true,
              icon: Icons.smart_toy_rounded,
              index: 3,
            ),
            _StatusCard(
              label: 'Push Notifications',
              status: AppConfig.demoMode ? 'Simulated (local stream)' : 'FCM configured',
              ok: true,
              icon: Icons.notifications_active_rounded,
              index: 4,
            ),

            const SizedBox(height: 24),

            Text('Device Info', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700))
                .animate().fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 12),

            _InfoRow(label: 'App Version', value: '1.0.0-alpha'),
            _InfoRow(label: 'Flutter Channel', value: 'stable'),
            _InfoRow(label: 'Session Uptime', value: _uptime),
            _InfoRow(label: 'Demo Mode', value: AppConfig.demoMode ? 'ON' : 'OFF'),
            _InfoRow(label: 'Data Persistence', value: 'SharedPreferences + Demo Engine'),

            const SizedBox(height: 24),

            Text('Connectivity', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700))
                .animate().fadeIn(delay: 400.ms, duration: 400.ms),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ConnectivityRow(
                    label: 'Backend URL',
                    value: AppConfig.demoMode ? 'N/A (demo)' : apiBaseUrl,
                    ok: health == BackendStatus.ok || AppConfig.demoMode,
                  ),
                  const Divider(height: 20),
                  _ConnectivityRow(
                    label: 'WebSocket (STOMP)',
                    value: isStompConnected ? 'Connected' : 'Disconnected',
                    ok: isStompConnected || AppConfig.demoMode,
                  ),
                  const Divider(height: 20),
                  _ConnectivityRow(
                    label: 'REST Fallback',
                    value: 'Active (3s polling)',
                    ok: true,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.status,
    required this.ok,
    required this.icon,
    required this.index,
  });
  final String label;
  final String status;
  final bool ok;
  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (ok ? AppColors.nairaGreen : AppColors.emergencyRed).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ok ? AppColors.nairaGreen : AppColors.emergencyRed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(status, style: context.text.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? AppColors.nairaGreen : AppColors.emergencyRed,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0, duration: 350.ms);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.text.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
          Text(value, style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ConnectivityRow extends StatelessWidget {
  const _ConnectivityRow({required this.label, required this.value, required this.ok});
  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.error_rounded,
          size: 16,
          color: ok ? AppColors.nairaGreen : AppColors.emergencyRed,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Text(value, style: TextStyle(
          fontSize: 11,
          color: ok ? AppColors.nairaGreen : AppColors.emergencyRed,
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}
