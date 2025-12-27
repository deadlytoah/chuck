# In-App Camera Edge Cases and Learnings

## Edge Cases Discovered During Implementation

### 1. Stream-Based Queue Processing
**Issue**: Multiple photos added rapidly could cause race conditions.
**Solution**: Used StreamController to serialize all upload processing.
Stream naturally handles concurrent additions and processes them
sequentially one at a time.

**Implementation**: `camera_queue_service.dart:10-15`
- StreamController handles photo path events
- Stream subscription processes photos serially
- Prevents concurrent upload attempts

### 2. Network State Changes Mid-Upload
**Issue**: Network could switch from WiFi to cellular during upload.
**Solution**: Check network status before each photo in stream, skip
processing if not on WiFi.

**Implementation**: `camera_queue_service.dart:78-81`
- Each stream handler checks current network type
- Skip processing if not WiFi
- Photo remains in pending state for later retry

### 3. Camera Lifecycle Management
**Issue**: Camera resources must be disposed when app backgrounds.
**Solution**: Implement WidgetsBindingObserver to track app lifecycle.

**Implementation**: `camera_screen.dart:35-46`
- Dispose camera on inactive/paused states
- Re-initialize on resumed state
- Prevents camera resource leaks

### 4. Permission Handling Edge Cases
**Issue**: Users may permanently deny camera permission.
**Solution**: Detect permanent denial and show Settings button.

**Implementation**: `camera_screen.dart:115-137`
- Request permission on first screen access
- Check for permanent denial status
- Provide button to open iOS Settings app via `openAppSettings()`

### 5. Queue Badge Count Accuracy
**Issue**: Badge should show pending + failed count, not total queue.
**Solution**: Custom getter that filters by state.

**Implementation**: `camera_queue_service.dart:35-41`
- pendingCount getter filters for pending OR failed states
- Badge shows total items needing processing
- Completed items removed from queue immediately

### 6. Flash Timing and Visual Feedback
**Issue**: Flash must appear before capture completes.
**Solution**: Pre-delay flash, then capture, then post-delay for
visibility.

**Implementation**: `camera_screen.dart:84-100`
- 100ms pre-delay before capture
- White overlay at 80% opacity
- Capture during flash visibility
- Haptic feedback on capture start

### 7. Retry Logic for Failed Uploads
**Issue**: Failed items should retry without duplicating.
**Solution**: Update state to pending and re-add path to stream.

**Implementation**: `camera_queue_service.dart:66-74`
- Change photo state from failed to pending
- Re-add photo path to stream controller
- Stream processes it again serially

### 8. Queue Full Behavior
**Issue**: UI must clearly indicate when queue is full.
**Solution**: Disable capture button and reduce opacity.

**Implementation**: `camera_screen.dart:181-201`
- Check isQueueFull before enabling button
- Opacity 0.5 when disabled
- Visual indicator prevents user confusion

## Testing Insights

### Camera Permission Testing
**Challenge**: Physical camera access required on device.
**Solution**: Mock permission handler for automated tests.
**Location**: `test/mocks/mock_permission_handler.dart`

### Stream Processing Testing
**Challenge**: Async stream behavior hard to test.
**Solution**: Use pump and settle with delays in tests.
**Location**: `test/camera_queue_service_test.dart:245-289`

### Network Switching Testing
**Challenge**: Simulating network changes during processing.
**Solution**: Mock NetworkMonitor that allows manual state changes.
**Location**: `test/camera_queue_service_test.dart:291-339`

## Performance Considerations

### Memory Management
- Maximum 12 photos in queue prevents unbounded memory growth
- Each photo ~1-2MB in memory before processing
- Queue cleared on successful upload
- No persistent storage = queue lost on app restart (by design)

### Network Efficiency
- Serial processing prevents simultaneous uploads consuming bandwidth
- WiFi-only processing respects user data plans
- Retry logic avoids infinite retry loops

## Known Limitations

### 1. Queue Persistence
Queue intentionally lost on app restart per requirements. Users may
lose pending uploads if app crashes or is force-quit.

### 2. iOS Only
Implementation uses iOS-specific camera package. Android support
would require platform-specific code or different package.

### 3. No Upload Progress
Individual photo upload progress not shown. Users see only
pending/uploading/failed states via badge count.

### 4. Single Camera Only
Back camera hardcoded. No front camera or camera selection option.

### 5. No Photo Preview
Photos captured directly without review. User cannot delete unwanted
photos before upload starts.

## Future Enhancement Opportunities

### Potential Improvements Not Implemented
1. Queue persistence using local storage (SQLite or Hive)
2. Individual photo upload progress indicators
3. Camera selection (front vs back)
4. Photo preview with delete option before queue
5. Cellular upload with user confirmation
6. Batch upload optimization (multiple photos in parallel)
7. Upload analytics (success rate, average time)

## Documentation References

- Design spec: `design.md:59-76`
- Technical spec: `technical.md:107-145`
- Implementation plan: `plans/018-in-app-camera.md`
- Test suite: `src/test/camera_*_test.dart`
