import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplify/core/constants/app_constants.dart';
import 'package:simplify/features/tasks/screens/privacy_policy_screen.dart';

void main() {
  testWidgets('privacy policy screen renders key policy details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Privacy Policy for Simplify'), findsOneWidget);
    expect(
      find.text('Effective date: ${AppConstants.privacyPolicyEffectiveDate}'),
      findsOneWidget,
    );
    expect(find.text('No data collection'), findsOneWidget);
    expect(find.text(AppConstants.privacyPolicyUrl), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('By using Simplify, you agree to this Privacy Policy.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('By using Simplify, you agree to this Privacy Policy.'),
      findsOneWidget,
    );
  });
}
