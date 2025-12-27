# Plan 020: Refactor CameraQueueService to StreamController

## Prompt

"Yup, but first please generate a plan."

Context: User wants to refactor CameraQueueService from implicit async
pattern to explicit mpsc-style queue handler using StreamController.

## Current Implementation Issues

Current code at `camera_queue_service.dart:30-39`:
- `addPhoto()` calls `processQueue()` without await
- Relies on `_isProcessing` flag to prevent concurrent execution
- Harder to reason about execution flow
- Implicit async behavior on event loop

## Proposed StreamController Pattern

Replace fire-and-forget `processQueue()` with stream-based queue:
- StreamController<String> for incoming photo paths
- Stream listener processes photos one at a time
- Natural serialization via stream subscription
- Explicit queue semantics

## Implementation Steps

1. **Add StreamController to CameraQueueService**
   - Declare `StreamController<String> _photoStreamController`
   - Initialize in `build()` method
   - Set up stream listener for photo processing
   - Add disposal in `dispose()` if needed

2. **Refactor addPhoto() method**
   - Keep queue-full check
   - Add photo to state (QueuedPhoto list)
   - Send path to stream: `_photoStreamController.add(path)`
   - Remove `processQueue()` call

3. **Create stream handler method**
   - `_handlePhotoStream(String path)` async method
   - Check network status (WiFi only)
   - Find matching QueuedPhoto by path
   - Update to uploading state
   - Call upload service
   - Remove on success / mark failed on error
   - Automatically serialized by stream

4. **Remove _isProcessing flag**
   - No longer needed (stream handles serialization)
   - Simplifies concurrency model

5. **Update retryFailed() method**
   - Keep state update to pending
   - Send path to stream instead of calling `processQueue()`

6. **Handle network changes**
   - Keep existing `networkMonitorProvider` listener
   - On WiFi reconnect, iterate pending/failed photos
   - Send each to stream for processing

7. **Update tests**
   - Verify stream-based processing works
   - Test sequential processing via stream
   - Update concurrent processing test (should queue naturally)
   - Ensure network change behavior still works

## Files Modified

- `src/lib/services/camera_queue_service.dart` (main refactor)
- `src/test/camera_queue_service_test.dart` (update tests)

## Key Code Excerpts

From `camera_queue_service.dart:30-39` (current addPhoto):
```dart
bool addPhoto(String path) {
  if (isQueueFull) {
    return false;
  } else {
    final photo = QueuedPhoto(path: path);
    state = [...state, photo];
    processQueue();  // <- Remove this
    return true;
  }
}
```

From `camera_queue_service.dart:67-73` (_isProcessing flag):
```dart
bool _isProcessing = false;

Future<void> processQueue() async {
  if (_isProcessing) return;  // <- No longer needed
  ...
  _isProcessing = true;
```

## Benefits

- Explicit queue semantics (easier to reason about)
- Natural serialization (no manual locking)
- Clearer execution flow
- Matches user's mental model (mpsc queue)
