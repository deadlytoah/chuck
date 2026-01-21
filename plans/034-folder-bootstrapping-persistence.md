# Plan 034: Folder Selection Persistence

## Original Prompt
Can you create a new plan that details the steps to implement the
default folder bootstrapping and folder selection persistence?

## Context
Plan 032 implemented folder UI components but omitted folder
selection persistence from design.md and technical.md.

## Implementation Status

**IMPLEMENTED:**
- Folder selection persistence to local storage

**SKIPPED:**
- Auto-create default folders on first launch
- Reason: Race condition concerns with multiple clients starting
  simultaneously; user will create folders manually instead

## Requirements from Specs

**technical.md:57-62** (partially implemented)
- Subsequent launches: use last-selected folder from local storage,
  fallback to first alphabetically if not found ✓

## Overview
Persist selected folder to local storage and restore on app launch.

## Implementation Steps

### 1. Add Dependencies
**File:** `pubspec.yaml`

Add `shared_preferences` package for local storage:
```yaml
dependencies:
  shared_preferences: ^2.2.2
```

Run `flutter pub get` after adding.

### 2. Create Storage Service
**File:** `src/lib/services/folder_storage_service.dart` (new)

Create service to handle folder selection persistence:
```dart
import 'package:shared_preferences/shared_preferences.dart';

class FolderStorageService {
  static const String _selectedFolderKey = 'selected_folder_id';

  Future<String?> getSelectedFolderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedFolderKey);
  }

  Future<void> setSelectedFolderId(String folderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedFolderKey, folderId);
  }

  Future<void> clearSelectedFolderId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedFolderKey);
  }
}
```

### 3. Register Storage Service
**File:** `src/lib/providers/app_providers.dart`

Add provider for storage service:
```dart
// Add import
import '../services/folder_storage_service.dart';

// Add provider (after other service providers)
final folderStorageServiceProvider = Provider<FolderStorageService>(
  (ref) => FolderStorageService(),
);
```

### 4. Update FoldersNotifier for Bootstrapping
**File:** `src/lib/providers/app_providers.dart`

Update `FoldersNotifier` class:

**Add storage service to constructor:**
```dart
class FoldersNotifier extends StateNotifier<FoldersState> {
  final ApiService apiService;
  final FolderStorageService storageService;

  FoldersNotifier(this.apiService, this.storageService)
      : super(FoldersState(folders: [], isLoading: false));
```

**Update loadFolders method:**
```dart
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

  // Fallback: select first folder alphabetically
  if (selectedId == null && folders.isNotEmpty) {
    final sortedFolders = List<Folder>.from(folders)
      ..sort((a, b) => a.name.compareTo(b.name));
    selectedId = sortedFolders.first.folderId;
  }

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
```

**Update selectFolder method:**
```dart
Future<void> selectFolder(String folderId) async {
  state = state.copyWith(currentFolderId: folderId);
  await storageService.setSelectedFolderId(folderId);
}
```

**Update deleteFolder method:**
```dart
Future<void> deleteFolder(String folderId) async {
  await apiService.deleteFolder(folderId);

  final newFolders =
      state.folders.where((f) => f.folderId != folderId).toList();

  // If deleted folder was selected, select first alphabetically
  String? newSelection = state.currentFolderId;
  if (state.currentFolderId == folderId) {
    if (newFolders.isNotEmpty) {
      final sortedFolders = List<Folder>.from(newFolders)
        ..sort((a, b) => a.name.compareTo(b.name));
      newSelection = sortedFolders.first.folderId;
    } else {
      newSelection = null;
    }

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
```

### 5. Update Provider Registration
**File:** `src/lib/providers/app_providers.dart`

Update `foldersProvider` to inject storage service:
```dart
final foldersProvider =
    StateNotifierProvider<FoldersNotifier, FoldersState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(folderStorageServiceProvider);
  return FoldersNotifier(apiService, storageService);
});
```

### 6. Update FolderBottomSheet
**File:** `src/lib/widgets/folder_bottom_sheet.dart`

Update `_selectFolder` to be async:
```dart
Future<void> _selectFolder(
  BuildContext context,
  WidgetRef ref,
  String folderId,
) async {
  await ref.read(foldersProvider.notifier).selectFolder(folderId);
  if (context.mounted) {
    Navigator.pop(context);
  }
}
```

Change the onTap handler:
```dart
onTap: () async {
  await _selectFolder(context, ref, folder.folderId);
}
```

## Error Handling

**Storage Failures:**
- If SharedPreferences fails to read/write, log error and continue
- Fallback to in-memory selection (works for current session)
- Don't block app functionality

**Stale Storage:**
- If stored folder no longer exists, fallback to first alphabetically
- Clear invalid selection from storage

## Testing Checklist

**App Launch (With Folders):**
- [ ] Last-selected folder is restored from storage
- [ ] If stored folder deleted, fallback to first alphabetically
- [ ] Folder selector shows correct folder on app launch

**Folder Selection Persistence:**
- [ ] Selecting folder saves to local storage
- [ ] Close and reopen app - selected folder is restored
- [ ] Switch folders - new selection persisted
- [ ] Delete selected folder - new selection persisted

**Folder Deletion:**
- [ ] Deleting selected folder switches to first alphabetically
- [ ] Deleting last folder clears storage
- [ ] New selection persisted correctly

**Edge Cases:**
- [ ] Storage read/write failures don't crash app
- [ ] Concurrent folder operations don't corrupt state

## Files Modified

1. `pubspec.yaml` - Add shared_preferences dependency
2. `src/lib/services/folder_storage_service.dart` - New file
3. `src/lib/providers/app_providers.dart` - Add storage service,
   update FoldersNotifier with persistence logic
4. `src/lib/widgets/folder_bottom_sheet.dart` - Make selectFolder async
5. Test files - Update all mocks to include FolderStorageService
6. `design.md` - Update to reflect manual folder creation
7. `technical.md` - Update to reflect manual folder creation

## Dependencies

**New Package:**
- `shared_preferences: ^2.2.2` - Local key-value storage

## Notes

**Why Bootstrapping Was Skipped:**
- Race condition concerns with multiple clients starting simultaneously
- Backend PutItem would overwrite without conditions
- User will manually create folders instead

**Alphabetical Fallback:**
- Per technical.md, fallback is "first alphabetically if not found"
- Ensures consistent, predictable selection
- Matches user expectation of sorted lists

**Storage Key:**
- Use simple key: "selected_folder_id"
- No versioning needed (single string value)
- Can be extended later if needed
