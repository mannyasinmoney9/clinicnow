import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinic_now/app/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClinicNowApp()));
    await tester.pumpAndSettle();
    // Splash page renders — just check it didn't throw
    expect(find.byType(ClinicNowApp), findsOneWidget);
  });
}
