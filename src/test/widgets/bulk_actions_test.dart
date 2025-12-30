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

    testWidgets('Shows Bulk Archive button initially',
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

      expect(find.text('Bulk Archive'), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });

    testWidgets('Shows Exit Selection Mode when activated',
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

      // Tap to enter selection mode
      await tester.tap(find.text('Bulk Archive'));
      await tester.pumpAndSettle();

      expect(find.text('Exit Selection Mode'), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });
  });
}
