import 'package:flutter_test/flutter_test.dart';
import 'package:chuck/providers/app_providers.dart';
import 'package:chuck/services/api_service.dart';
import 'package:chuck/models/item.dart';

// Mock API Service
class MockApiService extends ApiService {
  MockApiService() : super(baseUrl: 'https://test.example.com');

  List<Item> _mockItems = [];
  String? _mockNextToken;

  void setMockResponse(List<Item> items, {String? nextToken}) {
    _mockItems = items;
    _mockNextToken = nextToken;
  }

  @override
  Future<ItemsResponse> getItems({
    String? nextToken,
    int limit = 20,
    String? sort,
    String? filter,
  }) async {
    return ItemsResponse(items: _mockItems, nextToken: _mockNextToken);
  }
}

void main() {
  late MockApiService mockApiService;
  late ItemsNotifier itemsNotifier;

  setUp(() {
    mockApiService = MockApiService();
    itemsNotifier = ItemsNotifier(mockApiService);
  });

  group('ItemsNotifier.addItem', () {
    test('adds non-archived item to beginning of list', () {
      final existingItem = Item(
        itemId: 'item-1',
        imageUrl: 'images/1/full.jpg',
        state: 'Unanswered',
        archived: false,
        createdAt: DateTime(2025, 1, 1),
      );

      final newItem = Item(
        itemId: 'item-2',
        imageUrl: 'images/2/full.jpg',
        state: 'Unanswered',
        archived: false,
        createdAt: DateTime(2025, 1, 2),
      );

      // Set initial state
      itemsNotifier.state = ItemsState(items: [existingItem]);

      // Add new item
      itemsNotifier.addItem(newItem);

      // Verify new item is at beginning
      expect(itemsNotifier.state.items.length, 2);
      expect(itemsNotifier.state.items[0].itemId, 'item-2');
      expect(itemsNotifier.state.items[1].itemId, 'item-1');
    });

    test('does not add archived item to list', () {
      final existingItem = Item(
        itemId: 'item-1',
        imageUrl: 'images/1/full.jpg',
        state: 'Unanswered',
        archived: false,
        createdAt: DateTime(2025, 1, 1),
      );

      final archivedItem = Item(
        itemId: 'item-2',
        imageUrl: 'images/2/full.jpg',
        state: 'Chuck',
        archived: true,
        createdAt: DateTime(2025, 1, 2),
      );

      // Set initial state
      itemsNotifier.state = ItemsState(items: [existingItem]);

      // Try to add archived item
      itemsNotifier.addItem(archivedItem);

      // Verify list unchanged
      expect(itemsNotifier.state.items.length, 1);
      expect(itemsNotifier.state.items[0].itemId, 'item-1');
    });

    test('adds item to empty list', () {
      final newItem = Item(
        itemId: 'item-1',
        imageUrl: 'images/1/full.jpg',
        state: 'Unanswered',
        archived: false,
        createdAt: DateTime(2025, 1, 1),
      );

      // Add to empty list
      itemsNotifier.addItem(newItem);

      expect(itemsNotifier.state.items.length, 1);
      expect(itemsNotifier.state.items[0].itemId, 'item-1');
    });
  });

  group('ItemsNotifier.loadItems filter behavior', () {
    test('preserves local-only items when filter is null', () async {
      final localItem = Item(
        itemId: 'local-1',
        imageUrl: 'images/local/full.jpg',
        state: 'Unanswered',
        archived: false,
        createdAt: DateTime(2025, 1, 1),
      );

      final backendItem = Item(
        itemId: 'backend-1',
        imageUrl: 'images/backend/full.jpg',
        state: 'Chuck',
        archived: false,
        createdAt: DateTime(2025, 1, 2),
      );

      // Set initial state with local item
      itemsNotifier.state = ItemsState(items: [localItem]);

      // Mock backend returns different item
      mockApiService.setMockResponse([backendItem]);

      // Load items with no filter
      await itemsNotifier.loadItems(filter: null);

      // Both items should be present
      expect(itemsNotifier.state.items.length, 2);
      expect(itemsNotifier.state.items[0].itemId, 'local-1'); // Local first
      expect(itemsNotifier.state.items[1].itemId, 'backend-1');
    });

    test('preserves local-only items when filter is "all"', () async {
      final localItem = Item(
        itemId: 'local-1',
        imageUrl: 'images/local/full.jpg',
        state: 'Unanswered',
        archived: false,
        createdAt: DateTime(2025, 1, 1),
      );

      final backendItem = Item(
        itemId: 'backend-1',
        imageUrl: 'images/backend/full.jpg',
        state: 'Keep',
        archived: false,
        createdAt: DateTime(2025, 1, 2),
      );

      // Set initial state with local item
      itemsNotifier.state = ItemsState(items: [localItem]);

      // Mock backend returns different item
      mockApiService.setMockResponse([backendItem]);

      // Load items with "all" filter
      await itemsNotifier.loadItems(filter: 'all');

      // Both items should be present
      expect(itemsNotifier.state.items.length, 2);
      expect(itemsNotifier.state.items[0].itemId, 'local-1'); // Local first
      expect(itemsNotifier.state.items[1].itemId, 'backend-1');
    });

    test('does NOT preserve local-only items when specific filter is active', () async {
      final localChuckItem = Item(
        itemId: 'local-1',
        imageUrl: 'images/local/full.jpg',
        state: 'Chuck',
        archived: false,
        createdAt: DateTime(2025, 1, 1),
      );

      final localKeepItem = Item(
        itemId: 'local-2',
        imageUrl: 'images/local2/full.jpg',
        state: 'Keep',
        archived: false,
        createdAt: DateTime(2025, 1, 2),
      );

      final backendChuckItem = Item(
        itemId: 'backend-1',
        imageUrl: 'images/backend/full.jpg',
        state: 'Chuck',
        archived: false,
        createdAt: DateTime(2025, 1, 3),
      );

      // Set initial state with mixed items
      itemsNotifier.state = ItemsState(items: [localChuckItem, localKeepItem]);

      // Mock backend returns only Chuck items
      mockApiService.setMockResponse([backendChuckItem]);

      // Load items with "Chuck" filter
      await itemsNotifier.loadItems(filter: 'Chuck');

      // Only backend item should be present (local items not preserved with filter)
      expect(itemsNotifier.state.items.length, 1);
      expect(itemsNotifier.state.items[0].itemId, 'backend-1');
    });

    test('does NOT preserve local-only items when "Keep" filter is active', () async {
      final localUnansweredItem = Item(
        itemId: 'local-1',
        imageUrl: 'images/local/full.jpg',
        state: 'Unanswered',
        archived: false,
        createdAt: DateTime(2025, 1, 1),
      );

      final backendKeepItem = Item(
        itemId: 'backend-1',
        imageUrl: 'images/backend/full.jpg',
        state: 'Keep',
        archived: false,
        createdAt: DateTime(2025, 1, 2),
      );

      // Set initial state with unanswered item
      itemsNotifier.state = ItemsState(items: [localUnansweredItem]);

      // Mock backend returns only Keep items
      mockApiService.setMockResponse([backendKeepItem]);

      // Load items with "Keep" filter
      await itemsNotifier.loadItems(filter: 'Keep');

      // Only backend Keep item should be present
      expect(itemsNotifier.state.items.length, 1);
      expect(itemsNotifier.state.items[0].itemId, 'backend-1');
      expect(itemsNotifier.state.items[0].state, 'Keep');
    });

    test('does NOT preserve archived items even with null filter', () async {
      final localActiveItem = Item(
        itemId: 'local-1',
        imageUrl: 'images/local/full.jpg',
        state: 'Chuck',
        archived: false,
        createdAt: DateTime(2025, 1, 1),
      );

      final localArchivedItem = Item(
        itemId: 'local-2',
        imageUrl: 'images/local2/full.jpg',
        state: 'Keep',
        archived: true,
        createdAt: DateTime(2025, 1, 2),
      );

      final backendItem = Item(
        itemId: 'backend-1',
        imageUrl: 'images/backend/full.jpg',
        state: 'Sell',
        archived: false,
        createdAt: DateTime(2025, 1, 3),
      );

      // Set initial state with both archived and non-archived items
      itemsNotifier.state = ItemsState(items: [localActiveItem, localArchivedItem]);

      // Mock backend returns different item
      mockApiService.setMockResponse([backendItem]);

      // Load items with null filter
      await itemsNotifier.loadItems(filter: null);

      // Only local active and backend items should be present
      expect(itemsNotifier.state.items.length, 2);
      expect(itemsNotifier.state.items[0].itemId, 'local-1'); // Active local item
      expect(itemsNotifier.state.items[1].itemId, 'backend-1');
      // Archived local item should NOT be present
      expect(itemsNotifier.state.items.any((item) => item.itemId == 'local-2'), false);
    });
  });
}
