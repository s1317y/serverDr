import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serverkit/app/theme/app_theme.dart';

void main() {
  testWidgets('ServerKit dark theme renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: Text('ServerKit')),
      ),
    );

    expect(find.text('ServerKit'), findsOneWidget);
  });
}
