import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/widgets/folder_bottom_sheet.dart';
import 'package:chuck/models/folder.dart';
import 'package:chuck/providers/app_providers.dart';
import 'package:chuck/services/api_service.dart';
import 'package:chuck/services/folder_storage_service.dart';

// Mock API Service
class _MockApiService extends ApiService {
  bool shouldFailCreate = false;
  bool shouldFailUpdate = false;
  bool shouldFailDelete = false;

  int createFolderCallCount = 0;
  int updateFolderCallCount = 0;
  int deleteFolderCallCount = 0;

  String? lastCreatedFolderId;
  String? lastCreatedName;

  _MockApiService() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Folder> createFolder({
    required String folderId,
    required String name,
  }) async {
    createFolderCallCount++;
    lastCreatedFolderId = folderId;
    lastCreatedName = name;
    if (shouldFailCreate) {
      throw Exception('Failed to create folder');
    }
    return Folder(folderId: folderId, name: name);
  }

  @override
  Future<Folder> updateFolder(
    String folderId, {
    required String name,
  }) async {
    updateFolderCallCount++;
    if (shouldFailUpdate) {
      throw Exception('Failed to update folder');
    }
    return Folder(folderId: folderId, name: name);
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    deleteFolderCallCount++;
    if (shouldFailDelete) {
      throw Exception('Folder not empty');
    }
  }
}

// Mock Folders Notifier for testing
// Mock Storage Service
class _MockStorageService extends FolderStorageService {
  @override
  Future<String?> getSelectedFolderId() async => null;

  @override
  Future<void> setSelectedFolderId(String folderId) async {}

  @override
  Future<void> clearSelectedFolderId() async {}
}

class MockFoldersNotifier extends FoldersNotifier {
  MockFoldersNotifier({
    required List<Folder> mockFolders,
    String? mockCurrentFolderId,
    ApiService? apiService,
  }) : super(apiService ?? _MockApiService(), _MockStorageService()) {
    state = FoldersState(
      folders: mockFolders,
      currentFolderId: mockCurrentFolderId,
    );
  }
}

void main() {
  testWidgets('FolderBottomSheet displays list of folders',
      (WidgetTester tester) async {
    final mockFolders = [
      Folder(folderId: 'folder-1', name: 'Clothes'),
      Folder(folderId: 'folder-2', name: 'Books'),
      Folder(folderId: 'folder-3', name: 'Blankets'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith(
            (ref) => MockFoldersNotifier(
              mockFolders: mockFolders,
              mockCurrentFolderId: 'folder-1',
            ),
          ),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: FolderBottomSheet(),
          ),
        ),
      ),
    );

    expect(find.text('Folders'), findsOneWidget);
    expect(find.text('Clothes'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('Blankets'), findsOneWidget);
    expect(find.text('New Folder'), findsOneWidget);
  });

  testWidgets('FolderBottomSheet highlights selected folder',
      (WidgetTester tester) async {
    final mockFolders = [
      Folder(folderId: 'folder-1', name: 'Clothes'),
      Folder(folderId: 'folder-2', name: 'Books'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith(
            (ref) => MockFoldersNotifier(
              mockFolders: mockFolders,
              mockCurrentFolderId: 'folder-1',
            ),
          ),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: FolderBottomSheet(),
          ),
        ),
      ),
    );

    // Verify selected folder shows checkmark
    expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);

    // Verify the checkmark is near the 'Clothes' text (selected folder)
    final clothesRow = find.ancestor(
      of: find.text('Clothes'),
      matching: find.byType(Row),
    );
    expect(clothesRow, findsOneWidget);
  });

  testWidgets('FolderBottomSheet shows create dialog on New Folder tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith(
            (ref) => MockFoldersNotifier(
              mockFolders: [],
              mockCurrentFolderId: null,
            ),
          ),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: FolderBottomSheet(),
          ),
        ),
      ),
    );

    // Tap New Folder button
    await tester.tap(find.text('New Folder'));
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Create Folder'), findsOneWidget);
    expect(find.text('Folder Name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('FolderBottomSheet creates folder with valid name',
      (WidgetTester tester) async {
    final mockApiService = _MockApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith(
            (ref) => MockFoldersNotifier(
              mockFolders: [],
              mockCurrentFolderId: null,
              apiService: mockApiService,
            ),
          ),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: FolderBottomSheet(),
          ),
        ),
      ),
    );

    // Tap New Folder button
    await tester.tap(find.text('New Folder'));
    await tester.pumpAndSettle();

    // Enter folder name
    await tester.enterText(find.byType(CupertinoTextField), 'My Clothes');
    await tester.pumpAndSettle();

    // Tap Create
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify API was called
    expect(mockApiService.createFolderCallCount, 1);
    expect(mockApiService.lastCreatedName, 'My Clothes');
    expect(mockApiService.lastCreatedFolderId, 'my-clothes');
  });

  testWidgets('FolderBottomSheet shows error for empty folder name',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith(
            (ref) => MockFoldersNotifier(
              mockFolders: [],
              mockCurrentFolderId: null,
            ),
          ),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: FolderBottomSheet(),
          ),
        ),
      ),
    );

    // Tap New Folder button
    await tester.tap(find.text('New Folder'));
    await tester.pumpAndSettle();

    // Tap Create without entering name
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify error message
    expect(find.text('Folder name is required'), findsOneWidget);
  });

  testWidgets('FolderBottomSheet shows context menu on long press',
      (WidgetTester tester) async {
    final mockFolders = [
      Folder(folderId: 'folder-1', name: 'Clothes'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith(
            (ref) => MockFoldersNotifier(
              mockFolders: mockFolders,
              mockCurrentFolderId: 'folder-1',
            ),
          ),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: FolderBottomSheet(),
          ),
        ),
      ),
    );

    // Long press on folder
    await tester.longPress(find.text('Clothes'));
    await tester.pumpAndSettle();

    // Verify context menu appeared
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('FolderBottomSheet shows rename dialog',
      (WidgetTester tester) async {
    final mockFolders = [
      Folder(folderId: 'folder-1', name: 'Clothes'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith(
            (ref) => MockFoldersNotifier(
              mockFolders: mockFolders,
              mockCurrentFolderId: 'folder-1',
            ),
          ),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: FolderBottomSheet(),
          ),
        ),
      ),
    );

    // Long press on folder
    await tester.longPress(find.text('Clothes'));
    await tester.pumpAndSettle();

    // Tap Rename
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    // Verify rename dialog opened
    expect(find.text('Rename Folder'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('FolderBottomSheet shows delete confirmation',
      (WidgetTester tester) async {
    final mockFolders = [
      Folder(folderId: 'folder-1', name: 'Clothes'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith(
            (ref) => MockFoldersNotifier(
              mockFolders: mockFolders,
              mockCurrentFolderId: 'folder-1',
            ),
          ),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: FolderBottomSheet(),
          ),
        ),
      ),
    );

    // Long press on folder
    await tester.longPress(find.text('Clothes'));
    await tester.pumpAndSettle();

    // Tap Delete
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog opened
    expect(find.text('Delete Folder'), findsOneWidget);
    expect(find.text('Are you sure you want to delete "Clothes"?'),
        findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
