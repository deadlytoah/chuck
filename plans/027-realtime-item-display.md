# Plan 027: Realtime Item Display After Upload

## Prompt
"After I take a photo, I want the new item to eventually appear as it
becomes available. What are some options with your recommendation"

User selected Option 3: Show after backend confirms (POST /items
completes).

## Code Context

camera_upload_service.dart:42
- `createItem()` returns Item but `uploadPhoto()` returns void

camera_queue_service.dart:103-105
- Upload succeeds, removes photo from queue, no item list update

app_providers.dart:69-135
- `ItemsNotifier` has methods to load/update/archive items
- No method to add single new item to beginning of list

## Implementation Plan

1. **Update CameraUploadService return type**
   - Change `uploadPhoto()` from `Future<void>` to `Future<Item>`
   - Return the Item created by `apiService.createItem()`
   - File: `src/lib/services/camera_upload_service.dart:13,42`

2. **Add method to ItemsNotifier for adding new items**
   - Create `addItem(Item item)` method in ItemsNotifier
   - Insert item at beginning of list (newest first)
   - Respect current filter (only add if item matches)
   - File: `src/lib/providers/app_providers.dart:69-135`

3. **Wire CameraQueueService to ItemsNotifier**
   - Import itemsProvider in camera_queue_service.dart
   - Capture returned Item from uploadPhoto()
   - Call itemsNotifier.addItem() on success
   - File: `src/lib/services/camera_queue_service.dart:103`

4. **Update CameraUploadService tests**
   - Mock apiService.createItem() to return test Item
   - Verify uploadPhoto() returns the created Item
   - File: `src/test/camera_upload_service_test.dart`

5. **Add test for ItemsNotifier.addItem()**
   - Test item added to beginning of list
   - Test item not added when filter doesn't match (archived filter)
   - File: `src/test/items_notifier_test.dart` (new file)

6. **Add integration test for realtime display**
   - Test camera upload triggers item list update
   - Verify new item appears without manual refresh
   - File: `src/test/camera_queue_service_test.dart`

## Files to Modify

- `src/lib/services/camera_upload_service.dart`
- `src/lib/providers/app_providers.dart`
- `src/lib/services/camera_queue_service.dart`
- `src/test/camera_upload_service_test.dart` (update)
- `src/test/items_notifier_test.dart` (create)
- `src/test/camera_queue_service_test.dart` (update)

## Expected Behavior

After upload completes successfully:
1. Backend confirms creation via POST /items response
2. CameraUploadService returns the new Item
3. CameraQueueService adds Item to ItemsNotifier
4. Item appears at top of Main View grid immediately
5. No manual refresh required
