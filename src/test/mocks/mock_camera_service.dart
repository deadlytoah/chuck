import 'package:camera/camera.dart';
import 'package:chuck/services/camera_service.dart';

class MockCameraService extends CameraService {
  CameraInitResult _mockResult = CameraInitResult.success;
  String? _mockErrorMessage;

  void setMockResult(CameraInitResult result, {String? errorMessage}) {
    _mockResult = result;
    _mockErrorMessage = errorMessage;
  }

  @override
  Future<CameraInitResponse> initializeCamera() async {
    switch (_mockResult) {
      case CameraInitResult.success:
        // Create a mock camera description
        final mockCamera = CameraDescription(
          name: 'mock_camera',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        );

        // Create a mock controller (won't actually initialize)
        final controller = CameraController(
          mockCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        return CameraInitResponse(
          result: CameraInitResult.success,
          controller: controller,
        );

      case CameraInitResult.permissionDenied:
        return CameraInitResponse(
          result: CameraInitResult.permissionDenied,
        );

      case CameraInitResult.error:
        return CameraInitResponse(
          result: CameraInitResult.error,
          errorMessage: _mockErrorMessage ?? 'Mock camera error',
        );
    }
  }
}
