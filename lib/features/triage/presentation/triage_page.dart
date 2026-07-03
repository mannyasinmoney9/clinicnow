import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/demo/offline_ada_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/primary_button.dart';

const _questionIcons = [
  Icons.bedtime_rounded,
  Icons.air_rounded,
  Icons.water_drop_rounded,
  Icons.flash_on_rounded,
  Icons.favorite_rounded,
  Icons.thermostat_rounded,
  Icons.local_drink_rounded,
];

class TriagePage extends StatefulWidget {
  const TriagePage({super.key});

  @override
  State<TriagePage> createState() => _TriagePageState();
}

class _TriagePageState extends State<TriagePage> {
  final _answers = <bool>[];
  int _index = 0;
  TriageResult? _result;

  void _answer(bool yes) {
    setState(() {
      _answers.add(yes);
      if (_index < OfflineAdaEngine.triageQuestions.length - 1) {
        _index++;
      } else {
        _result = OfflineAdaEngine.scoreTriage(_answers);
      }
    });
  }

  void _restart() {
    setState(() {
      _answers.clear();
      _index = 0;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(_result == null
            ? '${_index + 1} / ${OfflineAdaEngine.triageQuestions.length}'
            : 'Result'),
      ),
      body: _result == null ? _questionView(context) : _resultView(context, _result!),
    );
  }

  Widget _questionView(BuildContext context) {
    final progress = (_index) / OfflineAdaEngine.triageQuestions.length;
    return Column(
      key: const ValueKey('questions'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: 300.ms,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: context.colors.surfaceContainerHighest,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              key: ValueKey(_index),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.waitAmber.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _questionIcons[_index % _questionIcons.length],
                    size: 44,
                    color: AppColors.waitAmber,
                  ),
                )
                    .animate(key: ValueKey('icon_$_index'))
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  OfflineAdaEngine.triageQuestions[_index],
                  style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                )
                    .animate(key: ValueKey('q_$_index'))
                    .fadeIn(delay: 100.ms, duration: 350.ms)
                    .slideY(begin: 0.15, end: 0, delay: 100.ms, duration: 350.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Answer for how the person dey feel right now.',
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _answer(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('No'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(label: 'Yes', onPressed: () => _answer(true)),
              ),
            ],
          ),
        ),
        if (_index >= 4) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: _EmergencyBanner(),
          ),
        ],
      ],
    );
  }

  Widget _resultView(BuildContext context, TriageResult result) {
    final (color, label, advice, icon) = switch (result) {
      TriageResult.red => (
          AppColors.emergencyRed,
          '🔴 Emergency',
          'This need attention now now. Call 112 or Lagos 767, or go the nearest emergency department immediately.',
          Icons.emergency_rounded,
        ),
      TriageResult.yellow => (
          AppColors.waitAmber,
          '🟡 Urgent today',
          'Please see a doctor today. You fit join the clinic queue now so you no go wait too long.',
          Icons.warning_amber_rounded,
        ),
      TriageResult.green => (
          AppColors.nairaGreen,
          '🟢 Routine',
          'No serious danger sign right now. Rest, drink plenty water, and monitor. Book a routine appointment if e no improve.',
          Icons.check_circle_rounded,
        ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, size: 56, color: color),
          )
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 350.ms),
          const SizedBox(height: AppSpacing.xl),
          Text(label,
                  style: context.text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: color))
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.md),
          Text(advice, style: context.text.bodyLarge, textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 250.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This na guide. If you no sure, go hospital.',
            style: context.text.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.xxl),
          if (result == TriageResult.red) _EmergencyBanner(),
          const SizedBox(height: AppSpacing.md),
          if (result != TriageResult.green)
            PrimaryButton(
              label: 'Join queue now',
              icon: Icons.queue_rounded,
              onPressed: () => context.go('/queue/patient', extra: {
                'clinicId': 1,
                'clinicName': 'Ikorodu General Outpatient',
              }),
            ),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: _restart, child: const Text('Start over')),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:112');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.emergencyRed,
          borderRadius: AppRadii.rMd,
        ),
        child: const Row(
          children: [
            Icon(Icons.emergency_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tap to call 112 (Emergency)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.phone_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.02, duration: 900.ms, curve: Curves.easeInOut);
  }
}