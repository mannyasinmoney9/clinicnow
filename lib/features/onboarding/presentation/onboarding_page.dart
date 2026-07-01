import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;
  static const _count = 4;
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: 6000.ms)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    context.go('/thankyou');
  }

  void _next() {
    if (_page < _count - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final isLast = _page == _count - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Subtle animated background
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, _) => CustomPaint(
              painter: _OnboardingBgPainter(_bgCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Progress indicator — no skip button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      // Step counter chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.trustTeal.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.trustTeal.withAlpha(60)),
                        ),
                        child: Text(
                          '${_page + 1} / $_count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.trustTeal,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _Step(
                        icon: Icons.local_hospital_rounded,
                        color: AppColors.trustTeal,
                        title: s.ob1Title,
                        subtitle: s.ob1Sub,
                        index: 0,
                      ),
                      _Step(
                        icon: Icons.format_list_numbered_rounded,
                        color: AppColors.nairaGreen,
                        title: s.ob2Title,
                        subtitle: s.ob2Sub,
                        index: 1,
                      ),
                      _Step(
                        icon: Icons.video_call_rounded,
                        color: const Color(0xFF7C3AED),
                        title: s.ob3Title,
                        subtitle: s.ob3Sub,
                        index: 2,
                      ),
                      _LanguagePicker(onGetStarted: _finish),
                    ],
                  ),
                ),

                // Bottom nav
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      _AnimatedDots(count: _count, current: _page),
                      const SizedBox(height: 24),
                      if (!isLast)
                        PrimaryButton(
                          label: s.next,
                          onPressed: _next,
                        ).animate().fadeIn(duration: 300.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onboarding step — animated icon + text
// ---------------------------------------------------------------------------

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.index,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withAlpha(40),
                  color.withAlpha(10),
                ],
              ),
              border: Border.all(color: color.withAlpha(60), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing ring
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withAlpha(40), width: 1.5),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.95, end: 1.05, duration: 1800.ms),
                Icon(icon, size: 64, color: color),
              ],
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 40),
          Text(
            title,
            style: context.text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 500.ms)
              .slideY(
                  begin: 0.2, end: 0, delay: 150.ms, duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: context.text.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 280.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language picker — last page with "Get Started" CTA
// ---------------------------------------------------------------------------

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = ref.watch(localeProvider).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.waitAmber.withAlpha(40),
                  AppColors.waitAmber.withAlpha(10),
                ],
              ),
              border: Border.all(
                  color: AppColors.waitAmber.withAlpha(60), width: 2),
            ),
            child: const Icon(Icons.language_rounded,
                size: 64, color: AppColors.waitAmber),
          )
              .animate()
              .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 32),
          Text(
            'Pick your language',
            style: context.text.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
          const SizedBox(height: 8),
          Text(
            'You fit change am anytime for settings.',
            style: context.text.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LangChip(
                label: '🇬🇧  English',
                selected: currentCode == 'en',
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en')),
              ),
              const SizedBox(width: 12),
              _LangChip(
                label: '🇳🇬  Pidgin',
                selected: currentCode == 'pcm',
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('pcm')),
              ),
            ],
          ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGetStarted,
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Get Started'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.trustTeal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 450.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0, delay: 450.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.trustTeal
                  : AppColors.trustTeal.withAlpha(15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.trustTeal
                    .withAlpha(selected ? 0 : 80),
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.trustTeal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated progress dots
// ---------------------------------------------------------------------------

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [
                    AppColors.trustTeal,
                    AppColors.nairaGreen,
                  ])
                : null,
            color: active ? null : AppColors.trustTeal.withAlpha(40),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Subtle background painter
// ---------------------------------------------------------------------------

class _OnboardingBgPainter extends CustomPainter {
  const _OnboardingBgPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final x = size.width * (0.15 + i * 0.35);
      final y = size.height * 0.7 - math.sin(phase * 2 * math.pi) * 40;
      final r = size.width * (0.25 + i * 0.05);
      paint.color = AppColors.trustTeal
          .withAlpha((8 + 4 * math.sin(phase * 2 * math.pi)).toInt());
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_OnboardingBgPainter old) => old.t != t;
}