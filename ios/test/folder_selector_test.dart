import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/widgets/folder_selector.dart';
import 'package:chuck/models/folder.dart';
import 'package:chuck/providers/app_providers.dart';
import 'package:chuck/services/api_service.dart';
import 'package:chuck/services/folder_storage_service.dart';

// Mock API Service
class _MockApiService extends ApiService {
  _MockApiService() : super(baseUrl: 'https://test.example.com');
}

// Mock Storage Service
class _MockStorageService extends FolderStorageService {
  @override
  Future<String?> getSelectedFolderId() async => null;

  @override
  Future<void> setSelectedFolderId(String folderId) async {}

  @override
  Future<void> clearSelectedFolderId() async {}
}

// Mock Folders Notifier for testing
class MockFoldersNotifier extends FoldersNotifier {
  MockFoldersNotifier({
    required List<Folder> mockFolders,
    String? mockCurrentFolderId,
  }) : super(_MockApiService(), _MockStorageService()) {
    state = FoldersState(
      folders: mockFolders,
      currentFolderId: mockCurrentFolderId,
    );
  }
}

void main() {
  testWidgets('FolderSelector displays current folder name',
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
            child: FolderSelector(),
          ),
        ),
      ),
    );

    expect(find.text('Clothes'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.folder), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_down), findsOneWidget);
  });

  testWidgets('FolderSelector displays "No Folder" when no folder selected',
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
            child: FolderSelector(),
          ),
        ),
      ),
    );

    expect(find.text('No Folder'), findsOneWidget);
  });

  testWidgets('FolderSelector opens bottom sheet on tap',
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
            child: FolderSelector(),
          ),
        ),
      ),
    );

    // Tap the folder selector
    await tester.tap(find.byType(FolderSelector));
    await tester.pumpAndSettle();

    // Verify bottom sheet opened
    expect(find.text('Folders'), findsOneWidget);
  });

  testWidgets('FolderSelector has correct styling',
      (WidgetTester tester) async {
    final mockFolders = [
      Folder(folderId: 'folder-1', name: 'Test Folder'),
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
            child: FolderSelector(),
          ),
        ),
      ),
    );

    // Find the container with border
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(GestureDetector),
        matching: find.byType(Container),
      ),
    );

    // Verify padding
    expect(container.padding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
  });
}
