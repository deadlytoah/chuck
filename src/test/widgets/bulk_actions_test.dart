import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/widgets/bulk_actions.dart';

void main() {
  group('BulkActions Widget Tests', () {
    testWidgets('Shows Bulk Archive button initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: BulkActions(),
            ),
          ),
        ),
      );

      expect(find.text('Bulk Archive'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.check_mark_circled), findsOneWidget);
    });

    testWidgets('Hides Bulk Archive and shows Cancel/Archive Selected when activated',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: BulkActions(),
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
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);

      // Archive Selected should appear but be disabled (grayed out)
      expect(find.text('Archive Selected'), findsOneWidget);

      // Verify the button with archive icon is disabled
      final archiveIconButtons = find.byIcon(CupertinoIcons.archivebox);
      expect(archiveIconButtons, findsOneWidget);

      final archiveButtonFinder = find.ancestor(
        of: archiveIconButtons,
        matching: find.byWidgetPredicate((w) => w is CupertinoButton),
      );
      expect(archiveButtonFinder, findsOneWidget);

      final archiveButton = tester.widget<CupertinoButton>(archiveButtonFinder);
      expect(archiveButton.onPressed, isNull); // Disabled when no items selected
    });
  });
}
