# Automated Test Implementation for In-App Camera Feature

## User Prompt

"what tests exist in the list and what are missing?" (referring to
plans/018-in-app-camera.md Phase 9 testing checklist)

## Overview

Implement comprehensive automated tests for camera functionality
covering services (queue, upload, image processing) and UI
components (screen, badge). Total: 49 automatable tests across 5
files.

## Test Strategy

### Automatable (49 tests)
- Unit tests: Services, image processing, state management
- Widget tests: UI components, button states, badge visibility
- Mock strategy: Manual class extension (existing pattern)
- Provider testing: ProviderScope overrides with ProviderContainer

### Manual Testing Required
- Physical camera hardware capture
- Actual permission dialogs
- Real network handoffs
- App lifecycle on device
- Haptic feedback perception

## Implementation Plan

### Phase 1: Expand CameraQueueService Tests (8 new tests)

**File:** `src/test/camera_queue_service_test.dart`

**Existing:** 7 tests (basic queue operations)

**Add:**
- addPhoto returns false when queue full
- processQueue only runs on WiFi (skips cellular)
- processQueue processes items sequentially
- processQueue removes item on upload success
- processQueue marks failed on upload exception
- Concurrent processQueue blocked by _isProcessing flag
- Network change WiFi→cellular stops processing mid-queue
- State transitions: pending→uploading→removed (success path)

**Mocks:**
- networkMonitorProvider: Override with test states (WiFi/cellular)
- cameraUploadServiceProvider: Mock class with success/failure modes

### Phase 2: Create ImageService Tests (12 tests)

**File:** `src/test/image_service_test.dart` (new)

**Tests:**
- processImage with valid JPEG returns ProcessedImages
- processImage with valid PNG returns ProcessedImages
- processImage throws on file > 10MB
- processImage throws on corrupted image data
- Thumbnail resized to fit 400x300 (aspect preserved)
- Full image resized to fit 1200x900 (aspect preserved)
- Portrait image: width bounded, height scaled
- Landscape image: height bounded, width scaled
- Square image scales to bounds
- JPEG quality = 85 for both outputs
- createDataUrl produces valid data URL format
- Uint8ListBase64.toBase64() handles padding edge cases

**Test Data:**
- Create minimal valid JPEG/PNG byte arrays
- Create 10MB+ byte array for size limit test
- Create corrupted image bytes

**No external dependencies; pure unit tests**

### Phase 3: Create CameraUploadService Tests (10 tests)

**File:** `src/test/camera_upload_service_test.dart` (new)

**Tests:**
- uploadPhoto success path (all steps complete)
- uploadPhoto throws FileNotFoundException for missing file
- uploadPhoto calls imageService.processImage with file bytes
- uploadPhoto calls apiService.getUploadUrls
- uploadPhoto uploads thumbnail to presigned URL
- uploadPhoto uploads full image to presigned URL
- uploadPhoto calls createItem with imageUrl + state='Unanswered'
- uploadPhoto throws if processImage fails
- uploadPhoto throws if API calls fail (getUploadUrls, uploads,
  createItem)
- Upload sequence verification (correct order of operations)

**Mocks:**
- ApiService: Extend class, override methods with test data
  - getUploadUrls(): return synthetic Map with thumb/full URLs
  - uploadImage(): track calls, throw on flag
  - createItem(): return Item or throw
- ImageService: Extend class, return ProcessedImages with test bytes
- File I/O: Create temp files in test setup

### Phase 4: Create CameraScreen Widget Tests (8 tests)

**File:** `src/test/camera_screen_test.dart` (new)

**Automatable Tests:**
- Renders CircularProgressIndicator during initialization
- Renders permission denied message when permission rejected
- Shows "Open Settings" button in denied state
- Shows "Go Back" button in denied state
- Back button pops navigation
- Capture button visible when camera ready
- Capture button disabled (opacity 0.5) when queue full
- Flash overlay (white container) visible when _isCapturing=true

**Mocks:**
- cameraQueueServiceProvider: Override with mock returning
  isQueueFull state
- Test UI state rendering (not actual camera functionality)

**Note:** Cannot test actual camera capture, permission dialogs,
CameraController initialization (requires native platform)

### Phase 5: Create CameraBadge Widget Tests (4 tests)

**File:** `src/test/camera_badge_test.dart` (new)

**Tests:**
- Returns SizedBox.shrink when count = 0
- Visible with red background when count > 0
- Displays correct count text (count.toString())
- Text styling: white, bold, 12pt

**Pure stateless widget; no mocks needed**

### Phase 6: Document Manual Test Scenarios

**File:** `src/test/README_MANUAL_TESTS.md` (new)

**Manual test checklist:**
- Camera permission request flow (OS dialog)
- Permission denied → Settings button opens system settings
- Continuous capture (multiple photos in sequence)
- Queue full behavior (12 photos, button disabled visually)
- Network switching during upload (WiFi→cellular pauses)
- App backgrounding/foregrounding (camera reinit)
- Haptic feedback on capture (physical sensation)
- Flash feedback timing (visual perception)
- Image quality verification (JPEG 85%, dimensions correct)

## Mock Implementation Patterns

### Manual Class Extension
```dart
class MockApiService extends ApiService {
  bool shouldFailUpload = false;
  
  @override
  Future<Map<String, dynamic>> getUploadUrls() async {
    return {
      'uploadUrls': {'thumb': 'url1', 'full': 'url2'},
      'imageUrl': 'https://example.com/image.jpg'
    };
  }
  
  @override
  Future<void> uploadImage(String url, List<int> data) async {
    if (shouldFailUpload) throw Exception('Upload failed');
  }
}
```

### Provider Overrides
```dart
final container = ProviderContainer(overrides: [
  networkMonitorProvider.overrideWithValue(NetworkType.wifi),
  cameraUploadServiceProvider.overrideWithValue(MockUploadService()),
]);
```

### MethodChannel Mock (existing pattern)
```dart
setUp(() {
  const channel = MethodChannel('dev.fluttercommunity.plus/
connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => ['mobile']);
});
```

## Test File Structure

```
src/test/
├── camera_queue_service_test.dart    (expand: 7→15 tests)
├── camera_upload_service_test.dart   (new: 10 tests)
├── image_service_test.dart           (new: 12 tests)
├── camera_screen_test.dart           (new: 8 tests)
├── camera_badge_test.dart            (new: 4 tests)
├── README_MANUAL_TESTS.md            (new: manual checklist)
└── [existing test files unchanged]
```

## Coverage Summary

| Component | Tests | Type | Status |
|-----------|-------|------|--------|
| CameraQueueService | 15 | Unit | 7 exist, 8 new |
| ImageService | 12 | Unit | All new |
| CameraUploadService | 10 | Unit | All new |
| CameraScreen | 8 | Widget | All new |
| CameraBadge | 4 | Widget | All new |
| **Total** | **49** | **Mixed** | **42 new** |

## Critical Files

**Modify:**
- `src/test/camera_queue_service_test.dart` - Add 8 tests for
  network handling, state transitions, queue processing

**Create:**
- `src/test/image_service_test.dart` - 12 tests for resize, quality,
  size limits
- `src/test/camera_upload_service_test.dart` - 10 tests for upload
  orchestration
- `src/test/camera_screen_test.dart` - 8 widget tests for UI states
- `src/test/camera_badge_test.dart` - 4 widget tests for badge
  display
- `src/test/README_MANUAL_TESTS.md` - Manual test checklist

**Reference:**
- `src/lib/services/camera_queue_service.dart` - Implementation to
  test
- `src/lib/services/camera_upload_service.dart` - Implementation to
  test
- `src/lib/services/image_service.dart` - Implementation to test
- `src/lib/screens/camera_screen.dart` - Widget to test
- `src/lib/widgets/camera_badge.dart` - Widget to test

## Dependencies

No new packages required. Uses existing:
- `flutter_test` (built-in)
- Manual mocks via class extension
- ProviderScope overrides for Riverpod testing

## Constraints Honored

- Tests written but not executed (no Flutter toolkit on machine)
- Follows existing test patterns (manual mocks, ProviderScope)
- No mockito/mocktail needed
- Clearly separates automatable vs manual tests
- 70-char line limit in docs
