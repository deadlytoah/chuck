import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/models/item.dart';
import 'package:chuck/providers/app_providers.dart';
import 'package:chuck/services/api_service.dart';
import 'package:chuck/widgets/items_grid.dart';

class MockApiService extends ApiService {
  MockApiService() : super(baseUrl: 'http://test');

  bool shouldFail = false;
  int loadItemsCallCount = 0;

  @override
  Future<ItemsResponse> getItems({
    String? filter,
    String? sort,
    int limit = 20,
    String? nextToken,
  }) async {
    loadItemsCallCount++;

    if (shouldFail) {
      throw Exception('Failed to load items: 400');
    }

    return ItemsResponse(items: [], nextToken: null);
  }

  @override
  Future<void> archiveItem(String itemId) async {
    if (shouldFail) {
      throw Exception('Failed to archive');
    }
  }
}

void main() {
  group('ItemsGrid Error Dialog Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    testWidgets('OK button dismisses dialog with single tap',
        (WidgetTester tester) async {
      mockApiService.shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ItemsGrid(),
            ),
          ),
        ),
      );

      // Trigger error by loading items
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ItemsGrid)),
      );
      await container.read(itemsProvider.notifier).loadItems();
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Unable to load items'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Tap OK once
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed after single tap
      expect(find.byType(AlertDialog), findsNothing,
          reason: 'Dialog should be dismissed after single OK tap');
    });

    testWidgets('Only one dialog shown even when error occurs multiple times',
        (WidgetTester tester) async {
      mockApiService.shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ItemsGrid(),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ItemsGrid)),
      );

      // Trigger error multiple times
      await container.read(itemsProvider.notifier).loadItems();
      await tester.pump(); // Don't settle, trigger again quickly
      await container.read(itemsProvider.notifier).loadItems();
      await tester.pumpAndSettle();

      // Should only show one dialog
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'Only one dialog should be shown even with multiple errors');
    });

    testWidgets('Same error after dismissal does not auto-show dialog',
        (WidgetTester tester) async {
      mockApiService.shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ItemsGrid(),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ItemsGrid)),
      );

      // First error
      await container.read(itemsProvider.notifier).loadItems();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Unable to load items'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // Trigger same error again
      await container.read(itemsProvider.notifier).loadItems();
      await tester.pumpAndSettle();

      // Should NOT show dialog again (same error message, user already dismissed it)
      expect(find.byType(AlertDialog), findsNothing,
          reason: 'Should not auto-show dialog for same error after dismissal');
    });

    testWidgets('Multiple rebuilds before postFrameCallback only show one dialog',
        (WidgetTester tester) async {
      mockApiService.shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ItemsGrid(),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ItemsGrid)),
      );

      // Trigger error and multiple rebuilds quickly
      await container.read(itemsProvider.notifier).loadItems();
      await tester.pump(); // First build with error

      // Force multiple rebuilds with same error before postFrameCallback executes
      container.read(itemsProvider.notifier).state =
        container.read(itemsProvider.notifier).state.copyWith();
      await tester.pump(); // Second build with same error

      container.read(itemsProvider.notifier).state =
        container.read(itemsProvider.notifier).state.copyWith();
      await tester.pump(); // Third build with same error

      await tester.pumpAndSettle(); // Let all postFrameCallbacks execute

      // Should only show ONE dialog, not three
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'Multiple rebuilds should not create multiple dialogs');

      // Verify we can dismiss with one tap
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing,
          reason: 'Single tap should dismiss the dialog');
    });

    testWidgets('Different error message shows new dialog',
        (WidgetTester tester) async {
      mockApiService.shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ItemsGrid(),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ItemsGrid)),
      );

      // First error
      await container.read(itemsProvider.notifier).loadItems();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Unable to load items'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // Different error message
      final notifier = container.read(itemsProvider.notifier);
      notifier.state = notifier.state.copyWith(error: 'Network connection lost');
      await tester.pumpAndSettle();

      // Should show dialog for different error
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'Should show dialog when error message changes');
      expect(find.text('Network connection lost'), findsOneWidget);
    });
  });
}
