import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/health_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/signature_widgets.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/connection_banner.dart';
import '../../shared/widgets/notification_bell.dart';
import '../auth/presentation/auth_providers.dart';
import 'animated_menu_button.dart';

class PatientHomePage extends ConsumerStatefulWidget {
  const PatientHomePage({super.key});

  @override
  ConsumerState<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends ConsumerState<PatientHomePage>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: 6000.ms)..repeat();
    _pulseCtrl = AnimationController(
            vsync: this, duration: 1600.ms)
        ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user =
        authState is AuthAuthenticated ? authState.user : null;


    return Scaffold(
      body: Stack(
        children: [
          // Animated background orbs
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_bgCtrl, _pulseCtrl]),
              builder: (_, _) => CustomPaint(
                painter: _HomeBgPainter(_bgCtrl.value, _pulseCtrl.value),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Connection status banner (slides in when backend unreachable)
                const ConnectionBanner(),

                // App bar
                _HomeAppBar(
                  name: user?.firstName ?? 'there',
                  onLogout: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  onProfile: () => context.go('/profile'),
                ),

                // Scrollable body
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.trustTeal,
                    onRefresh: () async {
                      await ref.read(healthProvider.notifier).check();
                      if (!context.mounted) return;
                      final ok = ref.read(healthProvider) == BackendStatus.ok;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? '✓ Connected to server'
                              : 'Still unreachable — is the backend running?'),
                          duration: const Duration(seconds: 2),
                          backgroundColor:
                              ok ? AppColors.nairaGreen : AppColors.emergencyRed,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner
                        _ClinicBanner(pulseCtrl: _pulseCtrl),
                        const SizedBox(height: 24),

                        // Health tip
                        _HealthTip()
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 500.ms)
                            .slideX(begin: 0.1, end: 0, delay: 300.ms, duration: 500.ms),
                        const SizedBox(height: 24),

                        Text('What do you need?',
                                style: context.text.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700))
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms),
                        const SizedBox(height: 14),

                        // Quick action grid
                        GridView.count(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.15,
                          children: [
                            _ActionCard(
                              icon: Icons.queue_rounded,
                              label: 'Join Queue',
                              subtitle: 'Skip the wait',
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
                              subtitle: 'Book a visit',
                              color: AppColors.nairaGreen,
                              onTap: () => context.go('/appointments'),
                              index: 1,
                            ),
                            _ActionCard(
                              icon: Icons.video_call_rounded,
                              label: 'Video Consult',
                              subtitle: 'See a doctor now',
                              color: const Color(0xFF7C3AED),
                              onTap: () => context.go('/payment', extra: {
                                'amountNaira': 2000,
                                'label': 'Dr. Oluwaseun Adeyemi · video consult',
                                'onSuccessRoute': '/teleconsult',
                              }),
                              index: 2,
                            ),
                            _ActionCard(
                              icon: Icons.chat_outlined,
                              label: 'Nurse Ada',
                              subtitle: 'AI health guide',
                              color: AppColors.waitAmber,
                              onTap: () => context.go('/assistant'),
                              index: 3,
                            ),
                            _ActionCard(
                              icon: Icons.health_and_safety_rounded,
                              label: 'Symptom Check',
                              subtitle: '7-question triage',
                              color: AppColors.emergencyRed,
                              onTap: () => context.go('/triage'),
                              index: 4,
                            ),
                            _ActionCard(
                              icon: Icons.person_outline_rounded,
                              label: 'Profile',
                              subtitle: 'Settings & theme',
                              color: AppColors.trustTeal,
                              onTap: () => context.go('/profile'),
                              index: 5,
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                        Text('Nearby Clinics',
                                style: context.text.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700))
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 400.ms),
                        const SizedBox(height: 14),
                        ..._clinics.asMap().entries.map(
                              (e) => _ClinicCard(
                                clinic: e.value,
                                index: e.key,
                              ).animate().fadeIn(
                                  delay: Duration(
                                      milliseconds: 750 + e.key * 80),
                                  duration: 400.ms),
                            ),
                      ],
                    ),
                  ),
                  ),  // RefreshIndicator
                ),    // Expanded
              ],
            ),
          ),
        ],
      ),

      // Floating Ada button
      floatingActionButton: _AdaFAB()
          .animate()
          .fadeIn(delay: 900.ms, duration: 600.ms)
          .slideY(begin: 0.5, end: 0, delay: 900.ms, duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  static const _clinics = [
    ('Ikorodu General Hospital', 'Ayangburen Road', '4.4★', '14 waiting'),
    ('Choba Community Clinic', 'University of PH Road', '4.7★', '3 waiting'),
    ('Rumuokoro Medical Centre', 'Iwofe Road', '4.3★', '11 waiting'),
  ];
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _HomeAppBar extends ConsumerWidget {
  const _HomeAppBar({required this.name, required this.onLogout, required this.onProfile});
  final String name;
  final VoidCallback onLogout;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $name 👋',
                  style: context.text.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ).animate().fadeIn(duration: 400.ms),
                Text(
                  'How are you feeling today?',
                  style: context.text.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              ],
            ),
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
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clinic banner
// ---------------------------------------------------------------------------

class _ClinicBanner extends StatelessWidget {
  const _ClinicBanner({required this.pulseCtrl});
  final AnimationController pulseCtrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, _) {
        final glowOpacity = 0.15 + 0.08 * pulseCtrl.value;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0BA5A4), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.trustTeal.withAlpha((glowOpacity * 255).toInt()),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_hospital_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Demo Clinic',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const Text(
                      'Ikorodu General Hospital',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF86EFAC),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text('Open 24 hrs',
                            style: TextStyle(
                                color: Color(0xFF86EFAC),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white70),
            ],
          ),
        );
      },
    )
        .animate()
        .fadeIn(delay: 150.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0, delay: 150.ms, duration: 500.ms);
  }
}

// ---------------------------------------------------------------------------
// Health tip banner
// ---------------------------------------------------------------------------

const _tips = [
  '💧 Drink at least 8 glasses of water daily',
  '🍎 Eat more fruits and vegetables',
  '🚶 30 minutes of walking daily keeps your heart healthy',
  '😴 Get 7–9 hours of sleep every night',
  '🩺 Regular check-ups catch problems early',
];

class _HealthTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().day % _tips.length];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.nairaGreen.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.nairaGreen.withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_rounded,
              color: AppColors.nairaGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.nairaGreen, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action card
// ---------------------------------------------------------------------------

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.index,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int index;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale =
        Tween<double>(begin: 1.0, end: 0.94).animate(
            CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withAlpha(12),
                  widget.color.withAlpha(5),
                ],
              ),
              border: Border.all(color: widget.color.withAlpha(30)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
                const Spacer(),
                Text(widget.label,
                    style: context.text.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(widget.subtitle,
                    style: context.text.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 450 + widget.index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(
            begin: 0.15,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOut);
  }
}

// ---------------------------------------------------------------------------
// Clinic card
// ---------------------------------------------------------------------------

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({required this.clinic, required this.index});
  final (String, String, String, String) clinic;
  final int index;

  @override
  Widget build(BuildContext context) {
    final (name, address, rating, queue) = clinic;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/queue/patient',
            extra: {'clinicId': index + 1, 'clinicName': name}),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.trustTeal.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital_outlined,
                    color: AppColors.trustTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                    Text(address,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rating,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.waitAmber)),
                  Text(queue,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.nairaGreen,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating Ada button
// ---------------------------------------------------------------------------

class _AdaFAB extends StatefulWidget {
  @override
  State<_AdaFAB> createState() => _AdaFABState();
}

class _AdaFABState extends State<_AdaFAB> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 2000.ms)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final glow = 0.3 + 0.25 * _ctrl.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.trustTeal.withAlpha((glow * 255).toInt()),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        onPressed: () => context.go('/assistant'),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Nurse Ada',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.trustTeal,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background painter — floating orbs
// ---------------------------------------------------------------------------

class _HomeBgPainter extends CustomPainter {
  const _HomeBgPainter(this.phase, this.pulse);
  final double phase;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 4; i++) {
      final t = (phase + i * 0.25) % 1.0;
      final x = size.width * [0.85, 0.1, 0.7, 0.25][i];
      final y = size.height *
              [0.05, 0.15, 0.55, 0.75][i] +
          math.sin(t * 2 * math.pi) * 15;
      final r = size.width * [0.3, 0.25, 0.2, 0.28][i];
      canvas.drawCircle(
        Offset(x, y),
        r * (1 + 0.03 * pulse),
        Paint()
          ..color = [
            AppColors.trustTeal,
            AppColors.nairaGreen,
            AppColors.waitAmber,
            AppColors.trustTeal,
          ][i]
              .withAlpha(7),
      );
    }
  }

  @override
  bool shouldRepaint(_HomeBgPainter old) =>
      old.phase != phase || old.pulse != pulse;
}