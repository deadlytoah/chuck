# Walkthrough: Automated Test Implementation for Camera Feature

## Overview

Implemented comprehensive automated test suite for in-app camera
functionality covering services, image processing, and UI components.
Total: 51 automated tests + 16 manual test scenarios.

## Files Created

### 1. camera_queue_service_test.dart (expanded from 7→15 tests)

**Location:** `src/test/camera_queue_service_test.dart`

**Added Tests:**
1. `addPhoto returns false when queue is full` - Verifies queue
   capacity enforcement (max 12 photos)
2. `processQueue only runs on WiFi` - Confirms uploads skip on
   cellular network
3. `processQueue processes items sequentially` - Tests serial upload
   behavior
4. `processQueue removes item on upload success` - Validates queue
   cleanup
5. `processQueue marks failed on upload exception` - Error handling
   verification
6. `Concurrent processQueue calls blocked by _isProcessing flag` -
   Prevents race conditions
7. `Network change to cellular stops processing mid-queue` - Tests
   network monitoring
8. `State transitions: pending→uploading→removed on success` -
   Validates state machine

**Mock Strategy:**
- MockNetworkMonitor: Controls WiFi/cellular state
- MockCameraUploadService: Simulates upload success/failure
- ProviderContainer overrides for dependency injection

**Key Patterns:**
```dart
final testContainer = ProviderContainer(
  overrides: [
    cameraUploadServiceProvider.overrideWithValue(mockUploadService),
    networkMonitorProvider.overrideWith((ref) => mockNetworkMonitor),
  ],
);
```

---

### 2. image_service_test.dart (12 new tests)

**Location:** `src/test/image_service_test.dart`

**Test Groups:**

**processImage Tests (10):**
1. Valid JPEG returns ProcessedImages
2. Valid PNG returns ProcessedImages
3. Throws on file > 10MB
4. Throws on corrupted image data
5. Thumbnail resized to fit 400x300 (aspect preserved)
6. Full image resized to fit 1200x900 (aspect preserved)
7. Portrait image: width bounded, height scaled
8. Landscape image: height bounded, width scaled
9. Square image scales to bounds
10. JPEG quality = 85 for both outputs

**createDataUrl Tests (2):**
1. Produces valid data URL format
2. Output starts with correct prefix

**Uint8ListBase64 Extension Tests (4):**
1. Handles empty bytes
2. Handles 1-byte input with padding (==)
3. Handles 2-byte input with padding (=)
4. Handles 3-byte input without padding

**Test Data Helpers:**
- `_createMinimalValidJpeg()` - 1x1 red pixel JPEG
- `_createMinimalValidPng()` - 1x1 white pixel PNG
- Minimal valid image headers for decoder testing

**No External Dependencies:** Pure unit tests using Uint8List

---

### 3. camera_upload_service_test.dart (10 new tests)

**Location:** `src/test/camera_upload_service_test.dart`

**Tests:**
1. `uploadPhoto success path - all steps complete` - End-to-end
   happy path
2. `uploadPhoto throws FileNotFoundException for missing file` -
   File validation
3. `uploadPhoto calls imageService.processImage with file bytes` -
   Service integration
4. `uploadPhoto calls apiService.getUploadUrls` - URL request
   verification
5. `uploadPhoto uploads thumbnail to presigned URL` - S3 thumb
   upload
6. `uploadPhoto uploads full image to presigned URL` - S3 full
   upload
7. `uploadPhoto calls createItem with imageUrl + state=Unanswered` -
   DB record creation
8. `uploadPhoto throws if processImage fails` - Image processing
   error
9. `uploadPhoto throws if API calls fail` - Network error handling
10. `Upload sequence verification - correct order of operations` -
    Step ordering

**Mock Strategy:**
- MockApiService: Extends ApiService, configurable success/failure
  - Tracks call counts: getUploadUrls, uploadImage, createItem
  - Records uploaded URLs and data
- MockImageService: Returns synthetic ProcessedImages
- Temp directory for test files (created/cleaned per test)

**Setup/Teardown:**
```dart
setUp(() async {
  tempDir = await Directory.systemTemp.createTemp('camera_upload_test_');
});

tearDown(() async {
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
});
```

---

### 4. camera_screen_test.dart (8 new tests)

**Location:** `src/test/camera_screen_test.dart`

**Widget Tests:**
1. `Renders CircularProgressIndicator during initialization` -
   Loading state
2. `Shows black background during loading` - Scaffold styling
3. `Renders permission denied message when permission rejected` -
   Error state UI
4. `Capture button visible with correct styling` - Button rendering
5. `Capture button has opacity 0.5 when queue full` - Disabled state
6. `Capture button has opacity 1.0 when queue not full` - Enabled
   state
7. `Back button is visible and pops navigation` - Navigation test
8. `SafeArea wraps camera controls` - Layout verification

**Mock Strategy:**
- MockCameraQueueService: Controls isQueueFull state
- ProviderScope overrides for provider testing

**Navigation Testing Pattern:**
```dart
// Push camera screen
await tester.tap(find.text('Open Camera'));
await tester.pumpAndSettle();

// Tap back button
await tester.tap(find.byIcon(Icons.arrow_back));
await tester.pumpAndSettle();

// Verify navigation
expect(find.byType(CameraScreen), findsNothing);
```

**Limitations:**
- Cannot test actual camera capture (requires native platform)
- Cannot test permission dialogs (OS-level)
- Cannot test CameraController initialization
- Tests focus on UI state logic

---

### 5. camera_badge_test.dart (8 new tests)

**Location:** `src/test/camera_badge_test.dart`

**Tests:**
1. `Returns SizedBox.shrink when count = 0` - Hidden state
2. `Visible with red background when count > 0` - Visible state
3. `Displays correct count text` - Text rendering
4. `Text styling: white, bold, 12pt` - Typography verification
5. `Badge positioned at top-right` - Positioned widget placement
6. `Badge has circular border radius` - BorderRadius check (radius
   10)
7. `Badge has minimum constraints` - BoxConstraints min 20x20
8. `Badge handles double-digit counts` - Multi-digit display

**Pure Stateless Widget:** No mocks required

**Widget Inspection Pattern:**
```dart
final container = tester.widget<Container>(find.byType(Container));
final decoration = container.decoration as BoxDecoration;
expect(decoration.color, Colors.red);
```

---

### 6. README_MANUAL_TESTS.md (16 scenarios)

**Location:** `src/test/README_MANUAL_TESTS.md`

**Manual Test Scenarios:**
1. Camera permission request flow
2. Permission denied → Settings button
3. Continuous capture (multiple photos)
4. Queue full behavior (12 photos, button disabled)
5. Queue badge count accuracy
6. Network switching (cellular to WiFi)
7. Network switching (WiFi to cellular mid-upload)
8. App backgrounding/foregrounding
9. Upload processing (serial, one at a time)
10. Failed upload retry logic
11. Back button navigation
12. Flash feedback timing and appearance
13. Haptic feedback on capture
14. Image scaling verification (thumbnail 400x300)
15. Image scaling verification (full 1200x900)
16. JPEG quality (85%)

**Format:**
- Each scenario has Steps and Expected sections
- Pass/Fail checkbox
- Summary section with totals
- Test environment metadata fields

---

## Implementation Details

### Testing Patterns Used

**1. Provider Overrides (Riverpod):**
```dart
final container = ProviderContainer(
  overrides: [
    providerName.overrideWith(() => mockImplementation),
  ],
);
```

**2. Manual Mock Classes (Extension Pattern):**
```dart
class MockApiService extends ApiService {
  bool shouldFail = false;
  
  @override
  Future<void> uploadImage(String url, List<int> data) async {
    if (shouldFail) throw Exception('Upload failed');
  }
}
```

**3. Widget Testing with ProviderScope:**
```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [...],
    child: MaterialApp(home: WidgetUnderTest()),
  ),
);
```

**4. Test Isolation:**
- setUp() for mock initialization
- tearDown() for container disposal and cleanup
- Temp directories for file I/O tests

---

### Coverage Summary

| Component | Tests | Type | File |
|-----------|-------|------|------|
| CameraQueueService | 15 | Unit | camera_queue_service_test.dart |
| ImageService | 16 | Unit | image_service_test.dart |
| CameraUploadService | 10 | Unit | camera_upload_service_test.dart |
| CameraScreen | 8 | Widget | camera_screen_test.dart |
| CameraBadge | 8 | Widget | camera_badge_test.dart |
| Manual Scenarios | 16 | Manual | README_MANUAL_TESTS.md |
| **Total** | **57** | **Automated** | **51 tests** |

---

### Dependencies

**No New Packages Required:**
- flutter_test (built-in)
- flutter_riverpod (existing dependency)
- Manual mocks via class extension

**Platform Channels Mocked:**
- connectivity_plus (MethodChannel mock in setUp)

---

### Running Tests

**Command (when Flutter toolkit available):**
```bash
cd src/
flutter test
```

**Individual Test Files:**
```bash
flutter test test/camera_queue_service_test.dart
flutter test test/image_service_test.dart
flutter test test/camera_upload_service_test.dart
flutter test test/camera_screen_test.dart
flutter test test/camera_badge_test.dart
```

**Coverage Report:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Key Decisions

**1. Manual Mocks Over Mockito/Mocktail:**
- Followed existing codebase pattern
- No new dependencies
- Simple and explicit
- Easy to debug

**2. Minimal Valid Images for Testing:**
- Created helper functions for JPEG/PNG headers
- Avoids large binary test fixtures
- Fast test execution
- Portable across platforms

**3. Widget Tests Focus on UI Logic:**
- Cannot mock native camera/permissions
- Tests verify state-driven UI changes
- Tests verify widget composition
- Actual camera testing left to manual scenarios

**4. Comprehensive Manual Test Documentation:**
- Structured checklist format
- Clear pass/fail criteria
- Environment metadata tracking
- Complements automated tests

---

## Test Execution Notes

**Not Executed:**
- Tests written but not run (no Flutter toolkit on machine)
- Tests should pass when run with proper Flutter environment
- Some tests may need minor adjustments for file I/O paths on
  different platforms

**Potential Issues:**
- Temp directory cleanup may fail on Windows (file locks)
- Network change test timing-sensitive (may need adjustment)
- Widget tests assume standard Flutter widget tree structure

---

## Maintenance

**Adding New Tests:**
1. Follow existing mock patterns
2. Use descriptive test names
3. Group related tests
4. Include setup/teardown as needed
5. Update this walkthrough

**Updating Mocks:**
- Extend mock classes when service APIs change
- Keep mocks simple (avoid over-engineering)
- Document mock behavior in comments

**Manual Test Updates:**
- Add new scenarios to README_MANUAL_TESTS.md
- Update expected behavior when features change
- Track test results in version control

---

## Related Files

**Implementation:**
- `src/lib/services/camera_queue_service.dart`
- `src/lib/services/camera_upload_service.dart`
- `src/lib/services/image_service.dart`
- `src/lib/screens/camera_screen.dart`
- `src/lib/widgets/camera_badge.dart`

**Documentation:**
- `plans/019-camera-automated-tests.md` - Implementation plan
- `plans/018-in-app-camera.md` - Feature implementation (Phase 9)

**Existing Tests:**
- `src/test/unit_test.dart` - Model tests
- `src/test/widget_test.dart` - AdminPage tests
- `src/test/hamburger_menu_test.dart` - Menu tests
