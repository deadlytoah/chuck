import 'package:uuid/uuid.dart';

enum PhotoState { pending, uploading, failed }

class QueuedPhoto {
  final String id;
  final String path;
  final DateTime timestamp;
  final PhotoState state;
  final int retryCount;
  final DateTime? nextRetryTime;

  QueuedPhoto({
    String? id,
    required this.path,
    DateTime? timestamp,
    this.state = PhotoState.pending,
    this.retryCount = 0,
    this.nextRetryTime,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  QueuedPhoto copyWith({
    String? id,
    String? path,
    DateTime? timestamp,
    PhotoState? state,
    int? retryCount,
    DateTime? nextRetryTime,
  }) {
    return QueuedPhoto(
      id: id ?? this.id,
      path: path ?? this.path,
      timestamp: timestamp ?? this.timestamp,
      state: state ?? this.state,
      retryCount: retryCount ?? this.retryCount,
      nextRetryTime: nextRetryTime ?? this.nextRetryTime,
    );
  }
}
