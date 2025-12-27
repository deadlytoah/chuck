# Plan 021: Mock permission_handler for Camera Screen Tests

## Prompt
Can you generate a plan for solution #1?

Context: `Permission.camera.request()` in camera_screen_test.dart never
completes, causing `pumpAndSettle()` timeout. Need to mock
permission_handler platform interface to return predetermined
permission status in tests.

## Solution: Mock permission_handler Platform Interface

### 1. Add dependency
- Add `permission_handler_platform_interface` to `dev_dependencies` in
  `src/pubspec.yaml`
- Version: Use compatible version with current `permission_handler`

### 2. Create mock permission handler
- File: `src/test/mocks/mock_permission_handler.dart`
- Implement `MethodChannelPermissionHandler` or
  `PermissionHandlerPlatform` mock
- Return configurable permission status (granted/denied/
  permanentlyDenied)
- Handle `Permission.camera.request()` and `Permission.camera.status`
  calls

### 3. Update camera_screen_test.dart
- Import mock permission handler
- Set up mock in `setUpAll()` or per-test `setUp()`
- Register mock with `PermissionHandlerPlatform.instance`
- Configure desired permission status for each test scenario

### 4. Test scenarios to cover
- Permission granted: Camera initializes, capture button visible
- Permission denied: Shows denial message, "Open Settings" button
- Permission permanently denied: Shows denial message
- Queue full with permission granted: Capture button opacity 0.5
- Queue not full with permission granted: Capture button opacity 1.0

### 5. Clean up after tests
- Reset mock in `tearDown()` or `tearDownAll()`
- Ensure tests don't interfere with each other

## Files to modify
- `src/pubspec.yaml`: Add dev dependency
- `src/test/mocks/mock_permission_handler.dart`: Create new mock
- `src/test/camera_screen_test.dart`: Integrate mock, update tests

## Expected outcome
- All camera screen tests run without timeout
- Print statement at camera_screen.dart:54 executes in tests
- Tests can verify both permission granted and denied states
- `pumpAndSettle()` completes successfully
