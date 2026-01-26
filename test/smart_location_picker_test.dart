import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigmatch/widgets/smart_location_picker.dart';

void main() {
  testWidgets('SmartLocationPicker builds correctly manual entry', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SmartLocationPicker(autoDetect: false),
      ),
    ));

    // Pump to settle state
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Enter your location'), findsOneWidget);
    expect(find.text('Auto-detect my location'), findsOneWidget);
  });
}
