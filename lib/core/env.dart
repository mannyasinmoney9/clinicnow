// Injected at build time:
//   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   (emulator)
//   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080 (physical phone)
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);
