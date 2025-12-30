import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/widgets/bulk_actions.dart';

void main() {
  group('BulkActions Widget Tests', () {
    testWidgets('Does not show selection count label or Clear button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BulkActions(),
            ),
          ),
        ),
      );

      // Verify selection count text is not present
      expect(find.textContaining('selected'), findsNothing);
      expect(find.textContaining('max 25'), findsNothing);

      // Verify Clear button is not present
      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('Shows Archive button initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BulkActions(),
            ),
          ),
        ),
      );

      expect(find.text('Archive'), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });

    testWidgets('Shows Cancel when activated', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BulkActions(),
            ),
          ),
        ),
      );

      // Tap to enter selection mode
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });
  });
}
