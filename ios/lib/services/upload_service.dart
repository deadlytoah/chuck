import 'dart:async';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/upload_progress.dart';
import 'api_service.dart';
import 'image_service.dart';

class UploadService {
  final ApiService apiService;
  final ImageService imageService;

  UploadService({required this.apiService, required this.imageService});

  Stream<Map<String, UploadProgress>> uploadFiles(
    List<FileToUpload> files, {
    required String folderId,
  }) async* {
    final progressMap = <String, UploadProgress>{};
    final uuid = const Uuid();

    // Initialize progress for all files
    for (final file in files) {
      final id = uuid.v4();
      progressMap[id] = UploadProgress(
        id: id,
        fileName: file.name,
        status: UploadStatus.pending,
      );
    }
    yield Map.from(progressMap);

    // Process uploads sequentially
    final fileIdMap = <String, String>{};
    for (int i = 0; i < files.length; i++) {
      fileIdMap[files[i].name] = progressMap.keys.elementAt(i);
    }

    for (final file in files) {
      final id = fileIdMap[file.name]!;
      await _uploadSingleFile(file, id, folderId, progressMap, (updated) {
        progressMap[id] = updated;
      });
      yield Map.from(progressMap);
    }

    // Final yield
    yield Map.from(progressMap);
  }

  Future<void> _uploadSingleFile(
    FileToUpload file,
    String id,
    String folderId,
    Map<String, UploadProgress> progressMap,
    Function(UploadProgress) onUpdate,
  ) async {
    final progress = progressMap[id]!;
    int retryCount = 0;

    while (retryCount <= 2) {
      try {
        onUpdate(
          progress.copyWith(
            status: UploadStatus.uploading,
            progress: 0.0,
            retryCount: retryCount,
          ),
        );

        // Process image
        final processed = await imageService.processImage(file.bytes);

        onUpdate(
          progress.copyWith(
            status: UploadStatus.uploading,
            progress: 0.3,
            thumbnailDataUrl: imageService.createDataUrl(
              processed.thumbnailBytes,
            ),
          ),
        );

        // Get presigned URLs
        final uploadResponse = await apiService.getUploadUrls();
        final uploadUrls = uploadResponse['uploadUrls'] as Map<String, dynamic>;
        final imageUrl = uploadResponse['imageUrl'] as String;

        onUpdate(
          progress.copyWith(status: UploadStatus.uploading, progress: 0.4),
        );

        // Upload thumbnail
        await apiService.uploadImage(
          uploadUrls['thumb'] as String,
          processed.thumbnailBytes,
        );

        onUpdate(
          progress.copyWith(status: UploadStatus.uploading, progress: 0.6),
        );

        // Upload full image
        await apiService.uploadImage(
          uploadUrls['full'] as String,
          processed.fullBytes,
        );

        onUpdate(
          progress.copyWith(status: UploadStatus.processing, progress: 0.8),
        );

        // Create item in database
        await apiService.createItem(folderId: folderId, imageUrl: imageUrl);

        onUpdate(
          progress.copyWith(
            status: UploadStatus.success,
            progress: 1.0,
            imageUrl: imageUrl,
          ),
        );

        return;
      } catch (e) {
        retryCount++;

        if (retryCount > 2) {
          onUpdate(
            progress.copyWith(
              status: UploadStatus.failed,
              errorMessage: e.toString(),
              retryCount: retryCount,
            ),
          );
          return;
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }

  Future<void> retryUpload(
    FileToUpload file,
    String id, {
    required String folderId,
    required Function(Map<String, UploadProgress>) onUpdate,
  }) async {
    final progressMap = <String, UploadProgress>{
      id: UploadProgress(
        id: id,
        fileName: file.name,
        status: UploadStatus.pending,
      ),
    };

    await _uploadSingleFile(file, id, folderId, progressMap, (updated) {
      progressMap[id] = updated;
      onUpdate(progressMap);
    });
  }
}

class FileToUpload {
  final String name;
  final Uint8List bytes;

  FileToUpload({required this.name, required this.bytes});
}

extension FutureCompletion<T> on Future<T> {
  bool get isCompleted {
    bool completed = false;
    then((_) => completed = true).catchError((_) => completed = true);
    return completed;
  }
}
