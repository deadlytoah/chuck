import 'package:flutter_test/flutter_test.dart';
import 'package:chuck/providers/app_providers.dart';
import 'package:chuck/services/api_service.dart';
import 'package:chuck/models/item.dart';

// Mock API Service
class MockApiService extends ApiService {
  MockApiService() : super(baseUrl: 'https://test.example.com');

  @override
  Future<ItemsResponse> getItems({
    String? nextToken,
    int limit = 20,
    String? sort,
    String? filter,
  }) async {
    return ItemsResponse(items: [], nextToken: null);
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
}
