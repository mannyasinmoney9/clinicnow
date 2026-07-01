import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_strings.dart';
import '../auth/presentation/auth_providers.dart';

class PatientHomePage extends ConsumerWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final s = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.firstName ?? 'there'} 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
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
            // Clinic status banner
            _ClinicBanner(),
            const SizedBox(height: AppSpacing.xl),
            Text('What do you need?', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            // Quick action grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.2,
              children: [
                _ActionCard(
                  icon: Icons.queue_rounded,
                  label: 'Join Queue',
                  color: AppColors.trustTeal,
                  onTap: () => context.go('/queue/patient', extra: {
                    'clinicId': 1,
                    'clinicName': 'Ikorodu General Hospital',
                  }),
                  index: 0,
                ),
                _ActionCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Appointments',
                  color: AppColors.nairaGreen,
                  onTap: () {},
                  index: 1,
                ),
                _ActionCard(
                  icon: Icons.video_call_rounded,
                  label: 'Video Consult',
                  color: const Color(0xFF7C3AED),
                  onTap: () {},
                  index: 2,
                ),
                _ActionCard(
                  icon: Icons.chat_outlined,
                  label: 'Nurse Ada',
                  color: AppColors.waitAmber,
                  onTap: () => context.go('/assistant'),
                  index: 3,
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/assistant'),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Nurse Ada'),
        backgroundColor: AppColors.trustTeal,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ClinicBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: context.appColors.brandGradient,
        borderRadius: AppRadii.rLg,
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital_rounded,
              color: Colors.white, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demo Clinic',
                    style: context.text.titleSmall
                        ?.copyWith(color: Colors.white)),
                Text('Ikorodu General Hospital',
                    style: context.text.bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.index,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(label,
                  style: context.text.labelMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + index * 80))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}
