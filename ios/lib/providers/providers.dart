import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queued_photo.dart';
import '../services/camera_queue_service.dart';

final cameraQueueServiceProvider =
    NotifierProvider<CameraQueueService, List<QueuedPhoto>>(
      CameraQueueService.new,
    );
