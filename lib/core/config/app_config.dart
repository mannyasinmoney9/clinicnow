/// Global demo-mode switch.
///
/// Default ON so the app is fully self-contained on a phone with no reachable
/// backend — every repository serves local seed data instead of calling
/// Spring Boot. Flip off for the real backend:
///   flutter run --dart-define=DEMO_MODE=false
abstract final class AppConfig {
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );
}
