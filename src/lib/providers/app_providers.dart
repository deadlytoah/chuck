import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/upload_progress.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/image_service.dart';
import '../services/upload_service.dart';
import '../services/camera_upload_service.dart';

// Configuration
final apiBaseUrlProvider = Provider<String>((ref) {
  return 'https://a7wchfs3es3rxo6luxbl7j7pv40skdur.lambda-url.us-east-1.on.aws/';
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

  Future<void> loadItems({String? filter, String? sort, int limit = 20}) async {
    state = state.copyWith(isLoading: true);

    final response = await apiService.getItems(
      filter: filter,
      sort: sort,
      limit: limit,
    );

    state = ItemsState(
      items: response.items,
      nextToken: response.nextToken,
      isLoading: false,
    );
  }

  Future<void> loadMore({String? filter, String? sort}) async {
    if (state.nextToken == null || state.isLoading) return;

    state = state.copyWith(isLoading: true);

    final response = await apiService.getItems(
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
