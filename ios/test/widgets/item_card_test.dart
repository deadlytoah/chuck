import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/widgets/item_card.dart';
import 'package:chuck/models/item.dart';

void main() {
  group('ItemCard Widget Tests', () {
    testWidgets('Comment displays with maxLines set to 3',
        (WidgetTester tester) async {
      final testItem = Item(
        itemId: 'test-123',
        folderId: 'test-folder',
        imageUrl: 'https://example.com/image.jpg',
        state: 'Keep',
        notes: 'This is a long comment that should wrap to multiple lines. '
            'Line two of the comment text. '
            'Line three of the comment text. '
            'Line four should be cut off with ellipsis.',
        archived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                height: 400,
                child: ItemCard(item: testItem),
              ),
            ),
          ),
        ),
      );

      // Find the Text widget displaying notes
      final textFinder = find.text(testItem.notes!);
      expect(textFinder, findsOneWidget);

      // Verify the Text widget has maxLines set to 3
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.maxLines, equals(3));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('Comment does not display when notes are empty',
        (WidgetTester tester) async {
      final testItem = Item(
        itemId: 'test-456',
        folderId: 'test-folder',
        imageUrl: 'https://example.com/image.jpg',
        state: 'Chuck',
        notes: '',
        archived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                height: 400,
                child: ItemCard(item: testItem),
              ),
            ),
          ),
        ),
      );

      // Verify no text widget is rendered for empty notes
      final textFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == testItem.notes &&
            widget.maxLines == 3,
      );
      expect(textFinder, findsNothing);
    });

    testWidgets('Comment does not display when notes are null',
        (WidgetTester tester) async {
      final testItem = Item(
        itemId: 'test-789',
        folderId: 'test-folder',
        imageUrl: 'https://example.com/image.jpg',
        state: 'Sell',
        notes: null,
        archived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                height: 400,
                child: ItemCard(item: testItem),
              ),
            ),
          ),
        ),
      );

      // Verify no text widget with maxLines is rendered
      final textFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.maxLines == 3,
      );
      expect(textFinder, findsNothing);
    });
  });
}
