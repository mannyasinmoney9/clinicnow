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

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  static const _count = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_page < _count - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
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
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(s.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Step(
                    icon: Icons.local_hospital_rounded,
                    title: s.ob1Title,
                    subtitle: s.ob1Sub,
                  ),
                  _Step(
                    icon: Icons.format_list_numbered_rounded,
                    title: s.ob2Title,
                    subtitle: s.ob2Sub,
                  ),
                  _Step(
                    icon: Icons.video_call_rounded,
                    title: s.ob3Title,
                    subtitle: s.ob3Sub,
                  ),
                  _LanguagePicker(onDone: _finish),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                children: [
                  _Dots(count: _count, current: _page),
                  const SizedBox(height: AppSpacing.xl),
                  if (!isLast)
                    PrimaryButton(label: s.next, onPressed: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onboarding step
// ---------------------------------------------------------------------------

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.trustTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: AppColors.trustTeal),
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.xxl),
          Text(title,
                  style: context.text.headlineMedium,
                  textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(
                  begin: 0.15,
                  end: 0,
                  delay: 150.ms,
                  duration: 400.ms,
                  curve: Curves.easeOut),
          const SizedBox(height: AppSpacing.md),
          Text(subtitle,
                  style: context.text.bodyLarge,
                  textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 250.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language picker (page 4)
// ---------------------------------------------------------------------------

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = ref.watch(localeProvider).languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.language_rounded, size: 64, color: AppColors.trustTeal)
              .animate()
              .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                  curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.xxl),
          Text('Pick your language',
                  style: context.text.headlineMedium,
                  textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.sm),
          Text('You fit change am anytime for settings.',
                  style: context.text.bodyMedium,
                  textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 250.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LangButton(
                label: 'English',
                selected: currentCode == 'en',
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en')),
              ),
              const SizedBox(width: AppSpacing.md),
              _LangButton(
                label: 'Pidgin',
                selected: currentCode == 'pcm',
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('pcm')),
              ),
            ],
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.base,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? context.colors.primary : Colors.transparent,
          foregroundColor:
              selected ? context.colors.onPrimary : context.colors.primary,
          side: BorderSide(
            color: context.colors.primary,
            width: selected ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
        child: Text(label, style: context.text.labelLarge),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dot progress indicator
// ---------------------------------------------------------------------------

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: AppDurations.base,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? context.colors.primary
                : context.colors.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
