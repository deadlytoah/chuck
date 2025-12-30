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

    testWidgets('Hides Bulk Archive and shows Cancel/Archive Selected when activated',
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

      // Bulk Archive button should be hidden
      expect(find.text('Bulk Archive'), findsNothing);

      // Cancel button should appear
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Archive Selected should appear but be disabled (grayed out)
      expect(find.text('Archive Selected'), findsOneWidget);

      // Verify the button with archive icon is disabled
      final archiveIconButtons = find.byIcon(Icons.archive);
      expect(archiveIconButtons, findsOneWidget);

      final archiveButtonFinder = find.ancestor(
        of: archiveIconButtons,
        matching: find.byWidgetPredicate((w) => w is ElevatedButton),
      );
      expect(archiveButtonFinder, findsOneWidget);

      final archiveButton = tester.widget<ElevatedButton>(archiveButtonFinder);
      expect(archiveButton.onPressed, isNull); // Disabled when no items selected
    });
  });
}
