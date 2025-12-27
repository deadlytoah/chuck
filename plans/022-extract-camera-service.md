# Plan: Extract Camera Logic to Injectable Service

## Prompt

User asked to extract camera initialization logic from CameraScreen
into an injectable service to enable proper testing. Currently,
`availableCameras()` blocks indefinitely in tests because the camera
plugin's platform channel is not mocked, causing all camera screen
tests to fail.

## Goals

- Make camera screen testable
- Follow existing service pattern in codebase
- Enable mocking of camera initialization in tests
- Maintain current functionality

## Implementation Steps

1. Create `CameraService` class in `src/lib/services/camera_service.dart`
   - Wrap `availableCameras()` and `CameraController` initialization
   - Return `CameraController` or error/permission denied state
   - Handle permission requests via `permission_handler`
   - Method: `Future<CameraController?> initializeCamera()`
   - Track permission state and initialization errors

2. Add `cameraServiceProvider` in `src/lib/providers/app_providers.dart`
   - Pattern: `Provider<CameraService>((ref) => CameraService())`
   - Follows existing pattern for apiServiceProvider, imageServiceProvider

3. Update `CameraScreen` in `src/lib/screens/camera_screen.dart`
   - Inject `CameraService` via Riverpod
   - Replace direct `availableCameras()` call with service method
   - Simplify `_initCamera()` to call service
   - Keep existing state management (_isCameraInitialized, etc.)

4. Create mock `CameraService` in tests
   - File: `src/test/mocks/mock_camera_service.dart`
   - Return mock `CameraController` or simulated error states
   - Pattern similar to `MockCameraQueueService`

5. Update `camera_screen_test.dart`
   - Override `cameraServiceProvider` with mock in ProviderScope
   - Remove blocking calls to real camera plugin
   - Test all UI states: loading, initialized, permission denied

## Files Modified

- `src/lib/services/camera_service.dart` (new)
- `src/lib/providers/app_providers.dart` (add provider)
- `src/lib/screens/camera_screen.dart` (inject service)
- `src/test/mocks/mock_camera_service.dart` (new)
- `src/test/camera_screen_test.dart` (use mock)

## Dependencies

No new package dependencies. Uses existing:
- camera package (already in use)
- permission_handler package (already in use)
- flutter_riverpod (already in use)

## Testing Strategy

- Mock service returns pre-configured CameraController
- Test permission denied state
- Test initialization success state
- Test loading state
- All existing test cases should pass with mocked service
