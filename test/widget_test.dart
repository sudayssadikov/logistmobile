import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/core/widgets/app_button.dart';
import 'package:logiflow_mobile/core/widgets/status_badge.dart';

void main() {
  testWidgets('LogiFlow Design System Core Widgets Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppButton(
                text: 'Test Button',
                onPressed: () {},
              ),
              const StatusBadge(
                label: 'Active',
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });
}
