# In-App Camera Implementation Plan

## Prompt

Record your plan for implementing in-app camera. Referenced:
- technical.md:L107-L145
- design.md:L59-L76

## Referenced Documentation

### technical.md:L107-L145
Camera package: `camera` (official Flutter plugin); back camera
only; no preview mode; continuous capture without leaving screen;
max 12 photos in in-memory queue (lost on restart); capture button
disabled when queue full; queue processes on OS-defined unmetered
network (via `connectivity_plus`); apply existing ImageService
scaling (400x300px thumb, 1200x900px full, 85% JPEG quality);
serial upload processing; existing POST /items/upload and POST
/items flow; retry button for failed items only (placed at queue
end); persistent banner with retry button; white flash (#FFFFFF
80% opacity) with Timer; mediumImpact haptic; network monitoring on
status change and app foreground (no polling); no exit confirmation
dialog; camera permission request on first use with Settings button
if denied; FAB in bottom right with badge showing total queued
count (pending + failed).

### design.md:L59-L76
Camera button in bottom right corner of Main View; badge displays
numeric count; continuous capture mode; photos immediately queued
(no cancellation); max 12 photos for memory/processing management;
white flash overlay with haptic feedback; queue processes
immediately on non-metered network regardless of app state; back
button only for exit; clear error for denied permission; persistent
notification banner with single retry button; badge remains until
queue clears.

## Implementation Plan

### 1. Dependencies
- Add `camera` package to pubspec.yaml
- Add `connectivity_plus` package to pubspec.yaml
- Update iOS permissions in Info.plist for camera access

### 2. Queue Management Service
- Create `CameraQueueService` with Riverpod provider
- In-memory queue with max 12 photos
- Track photo states: pending, uploading, failed
- Expose queue count (pending + failed) for badge
- Implement queue clearing on successful upload
- Implement failed item retry logic (move to end of queue)

### 3. Network Monitoring
- Create `NetworkMonitor` service using `connectivity_plus`
- Detect unmetered network (WiFi)
- Listen to connectivity changes
- Listen to app lifecycle (foreground return)
- Trigger queue processing on unmetered network availability
- No polling implementation

### 4. Camera Screen UI
- Create `CameraScreen` StatefulWidget
- Initialize back camera only
- Full-screen camera preview
- Capture button (disabled when queue full)
- Back button navigation to Main View
- No preview mode after capture
- Permission denied error with Settings button

### 5. Capture Feedback
- White flash overlay (#FFFFFF at 80% opacity)
- Timer-based flash duration (immediate after capture)
- HapticFeedback.mediumImpact() on capture
- Immediate queue addition (no cancellation option)

### 6. Upload Processing
- Serial processing (one photo at a time)
- Reuse existing ImageService scaling logic
- Reuse existing POST /items/upload flow
- Reuse existing POST /items flow
- Update queue item state on success/failure
- Remove from queue on success
- Mark as failed on error (keep in queue)

### 7. Main View Integration
- Add FAB in bottom right corner of Main View
- Badge showing total count (pending + failed)
- Navigate to CameraScreen on FAB tap
- Hide FAB when queue empty (optional: always show)

### 8. Error Handling UI
- Persistent banner below status bar
- Display when failed items exist
- Single retry button for all failed items
- Banner dismisses when all failed items retry or succeed
- Badge remains until queue fully clears

### 9. Permission Handling
- Request camera permission on first CameraScreen access
- Show error message if denied
- Provide button to open iOS Settings app
- Use permission_handler package if needed

### 10. Testing Considerations
- Test queue full behavior (12 photos)
- Test network switching (metered to unmetered)
- Test app backgrounding/foregrounding
- Test permission denial flow
- Test retry logic for failed uploads
- Test queue persistence (verify it's lost on restart)
- Test serial upload processing
- Test back button navigation

## Step-by-Step Tasks

### Phase 1: Setup and Dependencies
- [x] Add `camera` package to pubspec.yaml
- [x] Add `connectivity_plus` package to pubspec.yaml
- [x] Run `flutter pub get` to install dependencies
- [x] Update iOS Info.plist with camera permission description
- [x] Verify camera package compatibility with iOS target version

### Phase 2: Data Models and State
- [x] Create `QueuedPhoto` model class (photo data, state, timestamp)
- [x] Define photo states enum (pending, uploading, failed)
- [x] Create `CameraQueueService` class skeleton
- [x] Add Riverpod provider for `CameraQueueService`
- [x] Implement in-memory queue (List<QueuedPhoto>, max 12)
- [x] Add queue count getter (pending + failed)
- [x] Add methods: addPhoto, removePhoto, markFailed, retryFailed
- [x] Implement queue full check logic

### Phase 3: Network Monitoring
- [x] Create `NetworkMonitor` service class
- [x] Add Riverpod provider for `NetworkMonitor`
- [x] Implement connectivity_plus stream listener
- [x] Add unmetered network detection (WiFi check)
- [x] Implement app lifecycle listener (WidgetsBindingObserver)
- [x] Add callback for network status changes
- [x] Connect NetworkMonitor to CameraQueueService
- [x] Trigger queue processing on unmetered network available

### Phase 4: Upload Processing
- [x] Create `CameraUploadService` class
- [x] Implement serial upload processor (process one at a time)
- [x] Integrate with existing ImageService for scaling
- [x] Implement POST /items/upload call for presigned URLs
- [x] Implement S3 upload using presigned URLs
- [x] Implement POST /items call to create DynamoDB record
- [x] Add success handler (remove from queue)
- [x] Add failure handler (mark as failed, keep in queue)
- [x] Add queue state change notifications

### Phase 5: Camera Screen UI
- [x] Create `CameraScreen` StatefulWidget
- [x] Request camera permission on screen init
- [x] Handle permission denied (show error + Settings button)
- [x] Initialize CameraController (back camera only)
- [x] Build full-screen camera preview
- [x] Add capture button UI
- [x] Implement capture button disabled state (queue full)
- [x] Add back button navigation to Main View
- [x] Dispose camera controller properly

### Phase 6: Capture Feedback
- [x] Create white flash overlay widget (#FFFFFF 80% opacity)
- [x] Implement Timer-based flash animation
- [x] Add HapticFeedback.mediumImpact() on capture
- [x] Trigger flash immediately after photo capture
- [x] Add photo to queue immediately (no preview/cancellation)
- [x] Update capture button state based on queue count

### Phase 7: Main View Integration
- [x] Add FAB to Main View (bottom right corner)
- [x] Implement badge widget for FAB
- [x] Connect badge to queue count (pending + failed)
- [x] Add navigation to CameraScreen on FAB tap
- [x] Update badge reactively when queue changes
- [x] Position FAB correctly with SafeArea

### Phase 8: Error Handling UI
- [x] Create persistent banner widget
- [x] Position banner below status bar
- [x] Show banner when failed items exist
- [x] Add retry button to banner
- [x] Implement retry logic (move failed to end of queue)
- [x] Hide banner when no failed items
- [x] Ensure badge remains until queue fully clears

### Phase 9: Testing and Validation
- [x] Test camera permission request flow
- [x] Test permission denied error + Settings button
- [x] Test continuous capture (multiple photos)
- [x] Test queue full behavior (12 photos, button disabled)
- [x] Test queue badge count accuracy
- [x] Test network switching (cellular to WiFi)
- [x] Test app backgrounding/foregrounding
- [x] Test upload processing (serial, one at a time)
- [x] Test failed upload retry logic
- [x] Test queue persistence (verify lost on restart)
- [x] Test back button navigation
- [x] Test flash feedback timing and appearance
- [x] Test haptic feedback on capture
- [x] Verify image scaling (400x300 thumb, 1200x900 full)
- [x] Verify JPEG quality (85%)

### Phase 10: Polish and Documentation
- [x] Review all error messages for clarity
- [x] Verify UI matches design specifications
- [x] Test on physical iOS device
- [x] Update technical.md if implementation differs
- [x] Document any edge cases discovered
- [x] Code review and cleanup
