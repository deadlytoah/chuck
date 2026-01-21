import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/screens/admin_page.dart';
import 'package:chuck/providers/app_providers.dart';
import 'package:chuck/models/item.dart';
import 'package:chuck/models/folder.dart';
import 'package:chuck/services/api_service.dart';
import 'package:chuck/services/folder_storage_service.dart';
import 'package:chuck/widgets/upload_zone.dart';
import 'package:chuck/widgets/filter_bar.dart';
import 'package:chuck/widgets/bulk_actions.dart';
import 'package:chuck/widgets/items_grid.dart';

// Mock ItemsNotifier for testing
class MockItemsNotifier extends ItemsNotifier {
  bool loadItemsCalled = false;

  MockItemsNotifier(super.apiService);

  @override
  Future<void> loadItems({required String folderId, String? filter, String? sort, int limit = 20}) async {
    loadItemsCalled = true;
    state = ItemsState(items: [], isLoading: false);
  }
}

// Mock StorageService for testing
class MockStorageService extends FolderStorageService {
  @override
  Future<String?> getSelectedFolderId() async => null;

  @override
  Future<void> setSelectedFolderId(String folderId) async {}

  @override
  Future<void> clearSelectedFolderId() async {}
}

// Mock FoldersNotifier for testing
class MockFoldersNotifier extends FoldersNotifier {
  MockFoldersNotifier(ApiService apiService)
      : super(apiService, MockStorageService()) {
    state = FoldersState(
      folders: [Folder(folderId: 'test-folder', name: 'Test Folder', createdAt: DateTime.now())],
      currentFolderId: 'test-folder',
    );
  }
}

// Mock ApiService for testing
class MockApiService extends ApiService {
  MockApiService() : super(baseUrl: 'http://mock.test');

  @override
  Future<ItemsResponse> getItems({
    required String? folderId,
    String? nextToken,
    int limit = 20,
    String? sort,
    String? filter,
  }) async {
    return ItemsResponse(items: [], nextToken: null);
  }
}

void main() {
  group('AdminPage Widget Tests', () {
    late MockItemsNotifier mockItemsNotifier;
    late MockFoldersNotifier mockFoldersNotifier;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      mockItemsNotifier = MockItemsNotifier(mockApiService);
      mockFoldersNotifier = MockFoldersNotifier(mockApiService);
    });

    testWidgets('AdminPage renders without errors', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemsProvider.overrideWith((ref) => mockItemsNotifier),
            foldersProvider.overrideWith((ref) => mockFoldersNotifier),
          ],
          child: const CupertinoApp(home: AdminPage()),
        ),
      );

      expect(find.byType(AdminPage), findsOneWidget);

      addTearDown(tester.view.reset);
    });

    testWidgets('AdminPage calls loadItems on initialization', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemsProvider.overrideWith((ref) => mockItemsNotifier),
            foldersProvider.overrideWith((ref) => mockFoldersNotifier),
          ],
          child: const CupertinoApp(home: AdminPage()),
        ),
      );

      // Wait for post-frame callback
      await tester.pumpAndSettle();

      expect(mockItemsNotifier.loadItemsCalled, isTrue);

      addTearDown(tester.view.reset);
    });
  });
}
