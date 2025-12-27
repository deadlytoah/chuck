import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queued_photo.dart';
import 'network_monitor.dart';
import '../providers/app_providers.dart';

class CameraQueueService extends Notifier<List<QueuedPhoto>> {
  static const int maxQueueSize = 12;
  late StreamController<String> _photoStreamController;
  StreamSubscription<String>? _streamSubscription;

  @override
  List<QueuedPhoto> build() {
    _photoStreamController = StreamController<String>();
    _streamSubscription = _photoStreamController.stream.listen(_handlePhotoStream);
    
    ref.listen(networkMonitorProvider, (previous, next) {
      if (next == NetworkType.wifi && previous != NetworkType.wifi) {
        _processAllPending();
      }
    });
    
    ref.onDispose(() {
      _streamSubscription?.cancel();
      _photoStreamController.close();
    });
    
    return [];
  }

  bool get isQueueFull => state.length >= maxQueueSize;

  int get pendingCount => state
      .where(
        (photo) =>
            photo.state == PhotoState.pending ||
            photo.state == PhotoState.failed,
      )
      .length;

  bool addPhoto(String path) {
    if (isQueueFull) {
      return false;
    } else {
      final photo = QueuedPhoto(path: path);
      state = [...state, photo];
      _photoStreamController.add(path);
      return true;
    }
  }

  void removePhoto(String id) {
    state = state.where((photo) => photo.id != id).toList();
  }

  void markFailed(String id) {
    state = state.map((photo) {
      if (photo.id == id) {
        return photo.copyWith(state: PhotoState.failed);
      }
      return photo;
    }).toList();
  }

  void retryFailed(String id) {
    final photo = state.firstWhere((p) => p.id == id);
    state = state.map((photo) {
      if (photo.id == id) {
        return photo.copyWith(state: PhotoState.pending);
      }
      return photo;
    }).toList();
    _photoStreamController.add(photo.path);
  }

  void _handlePhotoStream(String path) async {
    final networkType = ref.read(networkMonitorProvider);
    if (networkType != NetworkType.wifi) {
      debugPrint('Not on WiFi. Skipping photo processing.');
      return;
    }

    // Find the photo by path
    final photo = state.where((p) => p.path == path && p.state == PhotoState.pending).firstOrNull;
    if (photo == null) {
      debugPrint('Photo not found or not pending: $path');
      return;
    }

    final photoId = photo.id;
    debugPrint('Processing photo $photoId...');

    // Update to uploading
    state = state.map((p) {
      if (p.id == photoId) {
        return p.copyWith(state: PhotoState.uploading);
      }
      return p;
    }).toList();

    try {
      await ref.read(cameraUploadServiceProvider).uploadPhoto(path);
      debugPrint('Upload success for $photoId');
      removePhoto(photoId);
    } catch (e) {
      debugPrint('Upload failed for $photoId: $e');
      markFailed(photoId);
    }
  }

  void _processAllPending() {
    for (final photo in state) {
      if (photo.state == PhotoState.pending || photo.state == PhotoState.failed) {
        _photoStreamController.add(photo.path);
      }
    }
  }
}
