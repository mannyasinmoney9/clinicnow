import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/appointments/presentation/appointments_page.dart';
import '../features/assistant/presentation/assistant_page.dart';
import '../features/teleconsult/presentation/teleconsult_page.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/otp_page.dart';
import '../features/home/admin_home_page.dart';
import '../features/home/patient_home_page.dart';
import '../features/home/staff_home_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/onboarding/presentation/thankyou_page.dart';
import '../features/payment/presentation/payment_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/queue/presentation/patient_queue_page.dart';
import '../features/queue/presentation/staff_board_page.dart';
import '../features/splash/splash_page.dart';
import '../features/triage/presentation/triage_page.dart';
import '../features/home/system_status_page.dart';

// ---------------------------------------------------------------------------
// Auth-aware notifier
// ---------------------------------------------------------------------------

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    final loc = state.matchedLocation;

    const publicPaths = {
      '/splash',
      '/onboarding',
      '/thankyou',
      '/login',
      '/register',
      '/otp',
    };

    if (auth is AuthLoading) return null;

    if (auth is AuthUnauthenticated || auth is AuthError) {
      return publicPaths.contains(loc) ? null : '/login';
    }

    if (auth is AuthRegistered) {
      // Must complete OTP — block everything else
      if (loc == '/otp') return null;
      return null; // let the page listener handle navigation
    }

    if (auth is AuthAuthenticated) {
      final home = _homeFor(auth);
      if (loc.startsWith('/home/')) return null;
      if (loc == '/login' || loc == '/register' || loc == '/otp') return home;
    }

    return null;
  }

  String _homeFor(AuthAuthenticated auth) {
    if (auth.user.role.name == 'admin') return '/home/admin';
    if (auth.user.isStaffOrAdmin) return '/home/staff';
    return '/home/patient';
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/onboarding'),
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/thankyou', builder: (_, _) => const ThankYouPage()),
      GoRoute(
        path: '/login',
        builder: (_, state) {
          final mode = (state.extra as Map<String, dynamic>?)?['mode'];
          return LoginPage(
            initialMode: mode == 'signup' ? AuthMode.signup : AuthMode.login,
          );
        },
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const LoginPage(initialMode: AuthMode.signup),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpPage(
            email: extra['email'] as String? ?? '',
            demoOtpCode: extra['otpCode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/home/patient',
        builder: (_, _) => const PatientHomePage(),
      ),
      GoRoute(path: '/home/staff', builder: (_, _) => const StaffHomePage()),
      GoRoute(path: '/home/admin', builder: (_, _) => const AdminHomePage()),
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
      GoRoute(path: '/queue/staff', builder: (_, _) => const StaffBoardPage()),
      GoRoute(path: '/assistant', builder: (_, _) => const AssistantPage()),
      GoRoute(
        path: '/teleconsult',
        builder: (_, state) {
          final asStaff =
              (state.extra as Map<String, dynamic>?)?['asStaff'] as bool? ??
              false;
          return TeleconsultPage(asStaff: asStaff);
        },
      ),
      GoRoute(path: '/triage', builder: (_, _) => const TriagePage()),
      GoRoute(
        path: '/appointments',
        builder: (_, _) => const AppointmentsPage(),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: '/system-status',
        builder: (_, _) => const SystemStatusPage(),
      ),
      GoRoute(
        path: '/payment',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PaymentPage(
            amountNaira: extra['amountNaira'] as int? ?? 2000,
            label: extra['label'] as String? ?? 'Dr. Bello · video consult',
            onSuccessRoute: extra['onSuccessRoute'] as String?,
          );
        },
      ),
    ],
  );
});
