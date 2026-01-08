// ✅ Smoke test for current GigMatch app
//
// The splash screen runs looping animations (pulse/loading) and uses delayed
// timers for its animation sequence. In widget tests, `pumpAndSettle()` can
// hang forever because the widget tree never becomes fully "settled" due to
// those infinite animations.
//
// This test avoids `pumpAndSettle()` and instead pumps a fixed amount of time
// to ensure the app can build frames without throwing.

import 'package:flutter_test/flutter_test.dart';
import 'package:gigmatch/main.dart';

void main() {
  testWidgets('GigMatch app boots (smoke test)', (WidgetTester tester) async {
    // Build the app.
    await tester.pumpWidget(const GigMatchApp());

    // Render initial frame.
    await tester.pump();

    // SplashScreenV2 delayed sequence totals ~4300ms:
    // 400ms + 800ms + 300ms + 400ms + 200ms + 2200ms = 4300ms
    // Pump a bit more to advance beyond the delayed navigation trigger.
    await tester.pump(const Duration(milliseconds: 5000));

    // Pump one more frame to ensure rendering continues without throwing.
    await tester.pump(const Duration(milliseconds: 16));

    // No strict UI assertions: routing can change (splash/onboarding/auth).
    // If the app throws during build/layout, the test will fail automatically.
    expect(tester.binding.renderViewElement, isNotNull);
  });
}
