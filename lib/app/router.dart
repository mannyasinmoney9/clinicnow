import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/home/patient_home_page.dart';
import '../features/home/staff_home_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/assistant/presentation/assistant_page.dart';
import '../features/queue/presentation/patient_queue_page.dart';
import '../features/queue/presentation/staff_board_page.dart';
import '../features/splash/splash_page.dart';

// ---------------------------------------------------------------------------
// Auth-aware notifier — bridges Riverpod state changes to GoRouter
// ---------------------------------------------------------------------------

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    final location = state.matchedLocation;

    // These routes never need a redirect — splash + onboarding handle themselves.
    const publicPaths = {'/splash', '/onboarding', '/login', '/register'};

    if (auth is AuthLoading) return null;

    if (auth is AuthUnauthenticated || auth is AuthError) {
      // Block access to protected routes; public routes are fine.
      return publicPaths.contains(location) ? null : '/login';
    }

    if (auth is AuthAuthenticated) {
      final home = auth.user.isStaffOrAdmin ? '/home/staff' : '/home/patient';

      // Already on the correct home — nothing to do.
      if (location.startsWith('/home/')) return null;

      // Trying to reach login/register while already authenticated.
      if (location == '/login' || location == '/register') return home;
    }

    return null;
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home/patient',
        builder: (_, _) => const PatientHomePage(),
      ),
      GoRoute(
        path: '/home/staff',
        builder: (_, _) => const StaffHomePage(),
      ),
      GoRoute(
        path: '/queue/patient',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PatientQueuePage(
            clinicId: extra['clinicId'] as int? ?? 1,
            clinicName: extra['clinicName'] as String? ?? 'Clinic',
          );
        },
      ),
      GoRoute(
        path: '/queue/staff',
        builder: (_, _) => const StaffBoardPage(),
      ),
      GoRoute(
        path: '/assistant',
        builder: (_, _) => const AssistantPage(),
      ),
    ],
  );
});
