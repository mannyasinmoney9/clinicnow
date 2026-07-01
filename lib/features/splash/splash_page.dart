import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../auth/presentation/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;

    if (!mounted) return;
    if (!seenOnboarding) {
      context.go('/onboarding');
      return;
    }

    // Allow a brief extra window if auth hasn't resolved from storage yet.
    if (ref.read(authProvider) is AuthLoading) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
    }

    final auth = ref.read(authProvider);
    if (!mounted) return;
    if (auth is AuthAuthenticated) {
      context.go(auth.user.isStaffOrAdmin ? '/home/staff' : '/home/patient');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.trustTeal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 56,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1.0, 1.0),
                  duration: 700.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 500.ms),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'ClinicNow',
              style: context.text.displayMedium?.copyWith(color: Colors.white),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(
                    begin: 0.2,
                    end: 0,
                    delay: 300.ms,
                    duration: 500.ms,
                    curve: Curves.easeOut),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your health, your queue',
              style: context.text.bodyLarge
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
