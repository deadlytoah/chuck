# Plan 032: Folder UI Components

## Original Context
Complete the UI components for folder organization (Plan 031 backend completed). Backend already has folder endpoints, FoldersNotifier provider, and updated API service. This plan adds the user-facing UI widgets.

## Prerequisites (Already Complete)
- Backend: Folder CRUD endpoints operational
- Models: Folder model exists (`src/lib/models/folder.dart`)
- API: `api_service.dart` has folder methods
- Providers: `FoldersNotifier` in `app_providers.dart`
- Items: Updated to include `folderId` field

## Overview
Add UI components for folder selection and management. Users need to:
1. See current folder at top of home screen
2. Switch between folders via dropdown
3. Create/rename/delete folders
4. Manage folders from hamburger menu

## UI Layout (Home Screen)
```
┌────────────────────────────┐
│ Hamburger  [Folder▾] Camera│  ← Folder selector added here
├────────────────────────────┤
│ [All][Chuck][Keep][Sell]   │  ← Existing filter bar
├────────────────────────────┤
│                            │
│   [Item Grid]              │  ← Existing items grid
│                            │
└────────────────────────────┘
```

## Components to Build

### 1. Folder Selector Widget
**File:** `src/lib/widgets/folder_selector.dart`

**Location:** Top center of home screen, between hamburger and camera
**Appearance:**
- Icon (📁 or folder icon)
- Current folder name
- Dropdown indicator (▾)
- Styled like a button/chip

**Behavior:**
- Tap: Show folder bottom sheet
- Display: Watch `foldersProvider.currentFolder`

**Example:**
```dart
class FolderSelector extends ConsumerWidget {
  const FolderSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersState = ref.watch(foldersProvider);
    final currentFolder = foldersState.currentFolder;

    return InkWell(
      onTap: () => _showFolderBottomSheet(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder, size: 20),
            SizedBox(width: 8),
            Text(currentFolder?.name ?? 'No Folder'),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFolderBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FolderBottomSheet(),
    );
  }
}
```

### 2. Folder Bottom Sheet
**File:** `src/lib/widgets/folder_bottom_sheet.dart`

**Content:**
- List of all folders (scrollable)
- "+ New Folder" button at bottom
- Long-press folder: Show rename/delete menu

**Interactions:**
- Tap folder: Switch to that folder, reload items, close sheet
- Tap "+ New Folder": Show dialog to create folder
- Long-press folder: Show context menu (Rename/Delete)

**Example Structure:**
```dart
class FolderBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersState = ref.watch(foldersProvider);

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Folders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: foldersState.folders.length,
              itemBuilder: (context, index) {
                final folder = foldersState.folders[index];
                return ListTile(
                  leading: Icon(Icons.folder),
                  title: Text(folder.name),
                  selected: folder.folderId == foldersState.currentFolderId,
                  onTap: () => _selectFolder(context, ref, folder.folderId),
                  onLongPress: () => _showFolderMenu(context, ref, folder),
                );
              },
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('New Folder'),
            onPressed: () => _showCreateFolderDialog(context, ref),
          ),
        ],
      ),
    );
  }
}
```

**Create Folder Dialog:**
- Text field for folder name
- Auto-generate folderId from name (lowercase, replace spaces with `-`)
- Validation: Name required, folderId unique
- Call `ref.read(foldersProvider.notifier).createFolder(...)`

**Folder Context Menu:**
- Rename: Show dialog, call `updateFolder`
- Delete: Confirm, call `deleteFolder` (API validates empty)

### 3. Update Home Page
**File:** `src/lib/screens/home_page.dart`

**Changes:**
1. Add `FolderSelector` to app bar or above filter bar
2. Load folders on mount: `ref.read(foldersProvider.notifier).loadFolders()`
3. Pass `currentFolderId` to items query
4. Reload items when folder changes

**Example Integration:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Load folders first
    ref.read(foldersProvider.notifier).loadFolders().then((_) {
      // Then load items for selected folder
      final currentFolder = ref.read(foldersProvider).currentFolderId;
      if (currentFolder != null) {
        ref.read(itemsProvider.notifier).loadItems(folderId: currentFolder);
      }
    });
  });
}

// Watch for folder changes and reload items
ref.listen(foldersProvider.select((s) => s.currentFolderId), (prev, next) {
  if (next != null && next != prev) {
    ref.read(itemsProvider.notifier).loadItems(folderId: next);
  }
});
```

**Layout:**
```dart
Column(
  children: [
    FolderSelector(),      // Add this
    FilterBar(),           // Existing
    Expanded(
      child: ItemsGrid(),  // Existing
    ),
  ],
)
```

### 4. Update Hamburger Menu
**File:** `src/lib/widgets/hamburger_menu.dart`

**Add Option:** "Manage Folders"
- Opens full-screen folder management page OR
- Opens folder bottom sheet (reuse component)

**Placement:** After existing admin/settings options

### 5. Provider Registration
**File:** `src/lib/main.dart`

**Verify:** `foldersProvider` is accessible (already defined in `app_providers.dart`)
- No additional registration needed since using `StateNotifierProvider`

### 6. Update Upload Services
**Files:**
- `src/lib/services/upload_service.dart`
- `src/lib/services/camera_upload_service.dart`

**Changes:**
Both services call `apiService.createItem()` which now requires `folderId`.

**Update:**
```dart
// Get current folder from provider
final currentFolderId = ref.read(foldersProvider).currentFolderId;
if (currentFolderId == null) {
  throw Exception('No folder selected');
}

// Pass to createItem
final item = await apiService.createItem(
  folderId: currentFolderId,
  imageUrl: imageUrl,
  state: 'Unanswered',
);
```

## Implementation Steps

1. **Create `folder_selector.dart`**
   - Import providers
   - Build selector UI
   - Handle tap → show bottom sheet

2. **Create `folder_bottom_sheet.dart`**
   - List folders with ListTile
   - Add "New Folder" button
   - Implement create dialog
   - Implement rename/delete menu
   - Handle folder selection

3. **Update `home_page.dart`**
   - Add FolderSelector to layout
   - Load folders on mount
   - Watch folder changes
   - Reload items when folder changes
   - Pass folderId to loadItems calls

4. **Update `hamburger_menu.dart`**
   - Add "Manage Folders" option
   - Open folder bottom sheet on tap

5. **Update upload services**
   - Get currentFolderId from provider
   - Pass to createItem API calls
   - Handle no folder selected error

6. **Test manually**
   - Create folders
   - Switch between folders
   - Upload items to folder
   - Rename/delete folders
   - Verify items stay in correct folder

## Error Handling

**No Folder Selected:**
- Show message: "Please select a folder first"
- Disable camera/upload buttons until folder selected

**Empty Folder List:**
- Auto-create default folders on first launch:
  - "Clothes", "Blankets", "Books"
  - Or prompt user to create first folder

**Delete Non-Empty Folder:**
- API returns error
- Show user-friendly message: "Folder contains items. Archive or move them first."

## Validation Rules

**Folder Name:**
- Required
- Max 50 characters
- No special characters except spaces and hyphens

**Folder ID:**
- Auto-generated from name
- Lowercase, spaces → hyphens
- Must be unique (validated by API)

**Example:** "My Clothes" → folderId: "my-clothes"

## UI/UX Notes

- Keep folder selector compact (doesn't dominate screen)
- Use consistent icons throughout (folder icon)
- Animate folder bottom sheet slide-in
- Show loading indicator during folder operations
- Optimistic UI updates (update local state before API response)
- Gray out camera button if no folder selected

## Dependencies
All dependencies already in place from Plan 031:
- `flutter_riverpod` for state management
- `http` for API calls
- Folder model and API methods
- FoldersNotifier provider

## Testing Checklist
- [ ] Folder selector displays current folder
- [ ] Bottom sheet shows all folders
- [ ] Can create new folder
- [ ] Can rename folder
- [ ] Can delete empty folder
- [ ] Cannot delete folder with items
- [ ] Switching folders reloads items correctly
- [ ] Uploading items goes to current folder
- [ ] Folder management from hamburger menu works
- [ ] No folder selected shows appropriate message
