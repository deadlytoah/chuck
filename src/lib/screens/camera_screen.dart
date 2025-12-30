import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_providers.dart';
import '../providers/providers.dart';
import '../services/camera_service.dart';
import '../services/camera_queue_service.dart';

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
  double _checkmarkOpacity = 0.0;

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

      // Show checkmark confirmation
      if (mounted) {
        setState(() {
          _checkmarkOpacity = 1.0;
        });
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          setState(() {
            _checkmarkOpacity = 0.0;
          });
        }
      }
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

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Camera Access Required'),
        content: const Text('Camera access is needed to take photos of items.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
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
      return const CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: Center(
          child: CupertinoActivityIndicator(
            color: CupertinoColors.white,
            radius: 14,
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(_controller!),

          // Confirmation Message Overlay
          Center(
            child: AnimatedOpacity(
              opacity: _checkmarkOpacity,
              duration: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Photo queued for upload',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

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
                          color: CupertinoColors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Icon(
                            CupertinoIcons.back,
                            color: CupertinoColors.white,
                            size: 28,
                          ),
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
                        final isQueueFull = ref.watch(
                          cameraQueueServiceProvider.select(
                            (photos) =>
                                photos.length >= CameraQueueService.maxQueueSize,
                          ),
                        );
                        return GestureDetector(
                          onTap: isQueueFull ? null : _capturePhoto,
                          child: Opacity(
                            opacity: isQueueFull ? 0.5 : 1.0,
                            child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: CupertinoColors.white, width: 4),
                                color: CupertinoColors.white.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Container(
                                  height: 64,
                                  width: 64,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CupertinoColors.white,
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
