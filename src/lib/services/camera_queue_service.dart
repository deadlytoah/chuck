import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queued_photo.dart';
import 'network_monitor.dart';
import '../providers/app_providers.dart';

class CameraQueueService extends Notifier<List<QueuedPhoto>> {
  static const int maxQueueSize = 12;
  static const int maxRetries = 3;
  static const List<int> retryDelayMinutes = [1, 2, 4];
  late StreamController<String> _photoStreamController;
  StreamSubscription<String>? _streamSubscription;
  Timer? _retryTimer;

  @override
  List<QueuedPhoto> build() {
    _photoStreamController = StreamController<String>();
    _streamSubscription = _photoStreamController.stream.listen(_handlePhotoStream);

    ref.listen(networkMonitorProvider, (previous, next) {
      if (next == NetworkType.wifi && previous != NetworkType.wifi) {
        _processAllPending();
      }
    });

    // Check for retry-ready photos every 30 seconds
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processRetryReady();
    });

    ref.onDispose(() {
      _streamSubscription?.cancel();
      _photoStreamController.close();
      _retryTimer?.cancel();
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
        return photo.copyWith(
          state: PhotoState.pending,
          retryCount: 0,
          nextRetryTime: null,
        );
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
      final item = await ref.read(cameraUploadServiceProvider).uploadPhoto(path);
      debugPrint('Upload success for $photoId');

      // Add new item to items list
      ref.read(itemsProvider.notifier).addItem(item);

      removePhoto(photoId);
    } catch (e) {
      debugPrint('Upload failed for $photoId: $e');
      _handleUploadFailure(photoId);
    }
  }

  void _processAllPending() {
    for (final photo in state) {
      if (photo.state == PhotoState.pending || photo.state == PhotoState.failed) {
        _photoStreamController.add(photo.path);
      }
    }
  }

  void _handleUploadFailure(String photoId) {
    final photo = state.firstWhere((p) => p.id == photoId);
    final newRetryCount = photo.retryCount + 1;

    if (newRetryCount >= maxRetries) {
      // Retry exhausted, mark as failed
      debugPrint('Retry exhausted for $photoId after $maxRetries attempts');
      markFailed(photoId);
    } else {
      // Schedule retry with exponential backoff
      final delayMinutes = retryDelayMinutes[newRetryCount - 1];
      final nextRetry = DateTime.now().add(Duration(minutes: delayMinutes));
      debugPrint('Scheduling retry ${newRetryCount} for $photoId in $delayMinutes minutes');

      state = state.map((p) {
        if (p.id == photoId) {
          return p.copyWith(
            state: PhotoState.pending,
            retryCount: newRetryCount,
            nextRetryTime: nextRetry,
          );
        }
        return p;
      }).toList();
    }
  }

  void _processRetryReady() {
    final now = DateTime.now();
    final networkType = ref.read(networkMonitorProvider);

    if (networkType != NetworkType.wifi) {
      return;
    }

    for (final photo in state) {
      if (photo.state == PhotoState.pending &&
          photo.nextRetryTime != null &&
          now.isAfter(photo.nextRetryTime!)) {
        debugPrint('Retrying photo ${photo.id} (attempt ${photo.retryCount + 1})');
        _photoStreamController.add(photo.path);
      }
    }
  }
}
