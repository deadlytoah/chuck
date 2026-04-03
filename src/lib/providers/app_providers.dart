import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/folder.dart';
import '../models/upload_progress.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/image_service.dart';
import '../services/upload_service.dart';
import '../services/camera_upload_service.dart';
import '../services/folder_storage_service.dart';

// Configuration
final apiBaseUrlProvider = Provider<String>((ref) {
  return 'https://aanonry4iszhp75mjpq33jfzxe0vzpdz.lambda-url.ap-southeast-2.on.aws/';
});

// Services
final apiServiceProvider = Provider<ApiService>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiService(baseUrl: baseUrl);
});

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

final uploadServiceProvider = Provider<UploadService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final imageService = ref.watch(imageServiceProvider);
  return UploadService(apiService: apiService, imageService: imageService);
});

final cameraUploadServiceProvider = Provider<CameraUploadService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final imageService = ref.watch(imageServiceProvider);
  return CameraUploadService(
    apiService: apiService,
    imageService: imageService,
  );
});

final folderStorageServiceProvider = Provider<FolderStorageService>((ref) {
  return FolderStorageService();
});

// Folder state
class FoldersState {
  final List<Folder> folders;
  final String? currentFolderId;
  final bool isLoading;

  FoldersState({
    required this.folders,
    this.currentFolderId,
    this.isLoading = false,
  });

  Folder? get currentFolder {
    if (currentFolderId == null) return null;
    return folders.where((f) => f.folderId == currentFolderId).firstOrNull;
  }

  FoldersState copyWith({
    List<Folder>? folders,
    String? currentFolderId,
    bool? isLoading,
  }) {
    return FoldersState(
      folders: folders ?? this.folders,
      currentFolderId: currentFolderId ?? this.currentFolderId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FoldersNotifier extends StateNotifier<FoldersState> {
  final ApiService apiService;
  final FolderStorageService storageService;

  FoldersNotifier(this.apiService, this.storageService)
      : super(FoldersState(folders: [], isLoading: false));

  /// Select "Inbox" folder if exists, otherwise first alphabetically
  String? _selectDefaultFolder(List<Folder> folders) {
    if (folders.isEmpty) return null;

    final inbox = folders.where((f) => f.name == 'Inbox').firstOrNull;
    if (inbox != null) {
      return inbox.folderId;
    }

    final sortedFolders = List<Folder>.from(folders)
      ..sort((a, b) => a.name.compareTo(b.name));
    return sortedFolders.first.folderId;
  }

  Future<void> loadFolders() async {
    state = state.copyWith(isLoading: true);

    final folders = await apiService.getFolders();

    // Restore last-selected folder from storage
    String? selectedId = await storageService.getSelectedFolderId();

    // Validate stored folder still exists
    if (selectedId != null &&
        !folders.any((f) => f.folderId == selectedId)) {
      selectedId = null;
    }

    // Fallback: select "Inbox" or first folder alphabetically
    selectedId ??= _selectDefaultFolder(folders);

    state = FoldersState(
      folders: folders,
      currentFolderId: selectedId,
      isLoading: false,
    );

    // Persist selection
    if (selectedId != null) {
      await storageService.setSelectedFolderId(selectedId);
    }
  }

  Future<void> selectFolder(String folderId) async {
    state = state.copyWith(currentFolderId: folderId);
    await storageService.setSelectedFolderId(folderId);
  }

  Future<void> createFolder({
    required String folderId,
    required String name,
  }) async {
    final folder = await apiService.createFolder(
      folderId: folderId,
      name: name,
    );

    state = state.copyWith(
      folders: [...state.folders, folder],
    );
  }

  Future<void> updateFolder({
    required String folderId,
    required String name,
  }) async {
    final updatedFolder = await apiService.updateFolder(folderId, name: name);

    final index = state.folders.indexWhere((f) => f.folderId == folderId);
    if (index != -1) {
      final newFolders = List<Folder>.from(state.folders);
      newFolders[index] = updatedFolder;
      state = state.copyWith(folders: newFolders);
    }
  }

  Future<void> deleteFolder(String folderId) async {
    await apiService.deleteFolder(folderId);

    final newFolders =
        state.folders.where((f) => f.folderId != folderId).toList();

    // If deleted folder was selected, select "Inbox" or first alphabetically
    String? newSelection = state.currentFolderId;
    if (state.currentFolderId == folderId) {
      newSelection = _selectDefaultFolder(newFolders);

      // Persist new selection
      if (newSelection != null) {
        await storageService.setSelectedFolderId(newSelection);
      } else {
        await storageService.clearSelectedFolderId();
      }
    }

    state = FoldersState(
      folders: newFolders,
      currentFolderId: newSelection,
      isLoading: false,
    );
  }
}

final foldersProvider =
    StateNotifierProvider<FoldersNotifier, FoldersState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(folderStorageServiceProvider);
  return FoldersNotifier(apiService, storageService);
});

// Items state
class ItemsState {
  final List<Item> items;
  final String? nextToken;
  final bool isLoading;

  ItemsState({
    required this.items,
    this.nextToken,
    this.isLoading = false,
  });

  ItemsState copyWith({
    List<Item>? items,
    String? nextToken,
    bool? isLoading,
  }) {
    return ItemsState(
      items: items ?? this.items,
      nextToken: nextToken ?? this.nextToken,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ItemsNotifier extends StateNotifier<ItemsState> {
  final ApiService apiService;

  ItemsNotifier(this.apiService)
    : super(ItemsState(items: [], isLoading: false));

  Future<void> loadItems({
    required String folderId,
    String? filter,
    String? sort,
    int limit = 20,
  }) async {
    final currentItems = state.items;
    state = state.copyWith(isLoading: true);

    final response = await apiService.getItems(
      folderId: folderId,
      filter: filter,
      sort: sort,
      limit: limit,
    );

    // Preserve items that were added locally but aren't in backend response yet
    // Only preserve non-archived items and only when showing "all" items (no filter)
    // When a filter is active, don't preserve items as they may not match the filter
    final backendItemIds = response.items.map((item) => item.itemId).toSet();
    final localOnlyItems = (filter == null || filter == 'all')
        ? currentItems
            .where((item) =>
                !backendItemIds.contains(item.itemId) &&
                !item.archived &&
                item.folderId == folderId)
            .toList()
        : <Item>[];

    // Merge: local-only items first, then backend items
    final mergedItems = [...localOnlyItems, ...response.items];

    state = state.copyWith(
      items: mergedItems,
      nextToken: response.nextToken,
      isLoading: false,
    );
  }

  Future<void> loadMore({
    required String folderId,
    String? filter,
    String? sort,
  }) async {
    if (state.nextToken == null || state.isLoading) return;

    state = state.copyWith(isLoading: true);

    final response = await apiService.getItems(
      folderId: folderId,
      nextToken: state.nextToken,
      filter: filter,
      sort: sort,
    );

    state = ItemsState(
      items: [...state.items, ...response.items],
      nextToken: response.nextToken,
      isLoading: false,
    );
  }

  Future<void> updateItem(String itemId, {String? state, String? notes}) async {
    final updatedItem = await apiService.updateItem(
      itemId,
      state: state,
      notes: notes,
    );

    final index = this.state.items.indexWhere((i) => i.itemId == itemId);
    if (index != -1) {
      final newItems = List<Item>.from(this.state.items);
      newItems[index] = updatedItem;
      this.state = this.state.copyWith(items: newItems);
    }
  }

  Future<void> archiveItem(String itemId) async {
    await apiService.archiveItem(itemId);
    final newItems = state.items.where((i) => i.itemId != itemId).toList();
    state = state.copyWith(items: newItems);
  }

  Future<void> unarchiveItem(String itemId) async {
    await apiService.updateItem(itemId, archived: false);
    final newItems = state.items.where((i) => i.itemId != itemId).toList();
    state = state.copyWith(items: newItems);
  }

  void addItem(Item item) {
    // Only add item if not archived (camera uploads are always non-archived)
    if (!item.archived) {
      state = state.copyWith(items: [item, ...state.items]);
    }
  }
}

final itemsProvider = StateNotifierProvider<ItemsNotifier, ItemsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ItemsNotifier(apiService);
});

// Upload state
final uploadProgressProvider = StateProvider<Map<String, UploadProgress>>(
  (ref) => {},
);

// Filter and sort state
final filterProvider = StateProvider<String?>((ref) => null);
final sortProvider = StateProvider<String?>((ref) => null);

// Selection state for bulk archive
class SelectionState {
  final bool isSelectionMode;
  final Set<String> selectedIds;

  SelectionState({this.isSelectionMode = false, this.selectedIds = const {}});

  SelectionState copyWith({bool? isSelectionMode, Set<String>? selectedIds}) {
    return SelectionState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(SelectionState());

  void toggleSelectionMode() {
    state = SelectionState(
      isSelectionMode: !state.isSelectionMode,
      selectedIds: {},
    );
  }

  void toggleItem(String itemId) {
    final newSelection = Set<String>.from(state.selectedIds);
    if (newSelection.contains(itemId)) {
      newSelection.remove(itemId);
    } else {
      if (newSelection.length < 25) {
        newSelection.add(itemId);
      }
    }
    state = state.copyWith(selectedIds: newSelection);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }
}

final selectionProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>((ref) {
      return SelectionNotifier();
    });
