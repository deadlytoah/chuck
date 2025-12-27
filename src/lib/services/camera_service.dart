import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraInitResult {
  success,
  permissionDenied,
  error,
}

class CameraInitResponse {
  final CameraInitResult result;
  final CameraController? controller;
  final String? errorMessage;

  CameraInitResponse({
    required this.result,
    this.controller,
    this.errorMessage,
  });
}

class CameraService {
  Future<CameraInitResponse> initializeCamera() async {
    final status = await Permission.camera.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      return CameraInitResponse(result: CameraInitResult.permissionDenied);
    }

    try {
      final cameras = await availableCameras();
      
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      return CameraInitResponse(
        result: CameraInitResult.success,
        controller: controller,
      );
    } catch (e) {
      return CameraInitResponse(
        result: CameraInitResult.error,
        errorMessage: e.toString(),
      );
    }
  }
}
