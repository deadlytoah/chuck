enum UploadStatus { pending, uploading, processing, success, failed }

class UploadProgress {
  final String id;
  final String fileName;
  final UploadStatus status;
  final double progress;
  final String? imageUrl;
  final String? thumbnailDataUrl;
  final String? errorMessage;
  final int retryCount;

  UploadProgress({
    required this.id,
    required this.fileName,
    required this.status,
    this.progress = 0.0,
    this.imageUrl,
    this.thumbnailDataUrl,
    this.errorMessage,
    this.retryCount = 0,
  });

  UploadProgress copyWith({
    String? id,
    String? fileName,
    UploadStatus? status,
    double? progress,
    String? imageUrl,
    String? thumbnailDataUrl,
    String? errorMessage,
    int? retryCount,
  }) {
    return UploadProgress(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailDataUrl: thumbnailDataUrl ?? this.thumbnailDataUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  bool get canRetry => status == UploadStatus.failed && retryCount < 2;
  bool get needsManualRetry => status == UploadStatus.failed && retryCount >= 2;
}

class BulkArchiveResult {
  final List<String> archived;
  final List<String> failed;

  BulkArchiveResult({required this.archived, required this.failed});

  factory BulkArchiveResult.fromJson(Map<String, dynamic> json) {
    return BulkArchiveResult(
      archived: List<String>.from(json['archived'] as List),
      failed: List<String>.from(json['failed'] as List),
    );
  }
}
