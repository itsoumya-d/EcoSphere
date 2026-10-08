import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/features/dashboard/presentation/widgets/activity_entry_form.dart';
import 'package:ecosphare/features/auth/presentation/providers/auth_controller.dart';

void main() {
  Future<void> showForm(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var authReads = 0;
    addTearDown(
      () => expect(
        authReads,
        0,
        reason:
            'Invalid input must stop before auth or persistence is accessed',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) {
            authReads++;
            throw StateError('Unexpected authentication access');
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: ActivityEntryForm())),
      ),
    );
  }

  testWidgets('invalid numbers show errors without submitting an activity', (
    tester,
  ) async {
    await showForm(tester);
    final quantity = find.byType(TextFormField).first;
    for (final value in ['NaN', 'Infinity', '1e309']) {
      await tester.enterText(quantity, value);
      await tester.tap(find.widgetWithText(FilledButton, 'Log Activity'));
      await tester.pump();
      expect(find.text('Please enter a finite number'), findsOneWidget);
      expect(find.text('Carbon Impact'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('preview and field errors recover after invalid input', (
    tester,
  ) async {
    await showForm(tester);
    final quantity = find.byType(TextFormField).first;
    await tester.enterText(quantity, '10');
    await tester.pump();
    expect(find.text('4.04 kg CO₂'), findsOneWidget);
    await tester.enterText(quantity, 'NaN');
    await tester.pump();
    expect(find.text('Carbon Impact'), findsNothing);
    expect(find.text('Please enter a finite number'), findsOneWidget);
    await tester.enterText(quantity, '5');
    await tester.pump();
    expect(find.text('2.02 kg CO₂'), findsOneWidget);
    expect(find.text('Please enter a finite number'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'overflowing diet impact stays out of the preview and save path',
    (tester) async {
      await showForm(tester);
      await tester.tap(find.text('Diet'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, '1e308');
      await tester.tap(find.widgetWithText(FilledButton, 'Log Activity'));
      await tester.pump();
      expect(find.text('Value is too large'), findsOneWidget);
      expect(find.text('Carbon Impact'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shopping rejects fractional quantities before preview or save', (
    tester,
  ) async {
    await showForm(tester);
    await tester.tap(find.text('Shopping'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, '1.5');
    await tester.tap(find.widgetWithText(FilledButton, 'Log Activity'));
    await tester.pump();
    expect(find.text('Please enter a whole number of items'), findsOneWidget);
    expect(find.text('Carbon Impact'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
