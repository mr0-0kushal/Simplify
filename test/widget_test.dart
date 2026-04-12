import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplify/features/tasks/widgets/empty_state.dart';

void main() {
  testWidgets('empty state renders CTA', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            title: 'No tasks yet',
            subtitle: 'Add one to keep your day in motion.',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Create task'), findsOneWidget);

    await tester.tap(find.text('Create task'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
