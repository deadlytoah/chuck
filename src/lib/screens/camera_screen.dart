import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_providers.dart';
import '../providers/providers.dart';
import '../services/camera_service.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _hasShownPermissionDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-initialize camera when app resumes if it was previously initialized
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameraService = ref.read(cameraServiceProvider);
    final response = await cameraService.initializeCamera();

    if (!mounted) return;

    switch (response.result) {
      case CameraInitResult.success:
        _controller = response.controller;
        setState(() {
          _isCameraInitialized = true;
        });
      case CameraInitResult.permissionDenied:
        if (!_hasShownPermissionDialog) {
          _hasShownPermissionDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPermissionDeniedDialog();
          });
        }
      case CameraInitResult.error:
        debugPrint('Error initializing camera: ${response.errorMessage}');
        if (!_hasShownPermissionDialog) {
          _hasShownPermissionDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPermissionDeniedDialog();
          });
        }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    final queueService = ref.read(cameraQueueServiceProvider.notifier);
    if (queueService.isQueueFull) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final file = await _controller!.takePicture();
      queueService.addPhoto(file.path);
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Access Required'),
        content: const Text('Camera access is needed to take photos of items.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );

    // After dialog is dismissed, pop the camera screen
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      // Loading state
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(_controller!),

          // Controls Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Back Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Control Area
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Center(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final queueService = ref.watch(cameraQueueServiceProvider.notifier);
                        final isQueueFull = queueService.isQueueFull;
                        return GestureDetector(
                          onTap: isQueueFull ? null : _capturePhoto,
                          child: Opacity(
                            opacity: isQueueFull ? 0.5 : 1.0,
                            child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: Center(
                                child: Container(
                                  height: 64,
                                  width: 64,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
