import 'dart:io';
import 'api_service.dart';
import 'image_service.dart';

class CameraUploadService {
  final ApiService apiService;
  final ImageService imageService;

  CameraUploadService({required this.apiService, required this.imageService});

  /// Processes and uploads a photo from the given file path.
  /// Throws an exception if any step fails.
  Future<void> uploadPhoto(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found at path: $path');
    }

    final bytes = await file.readAsBytes();

    // 1. Process image (resize/compress)
    final processed = await imageService.processImage(bytes);

    // 2. Get presigned URLs
    final uploadResponse = await apiService.getUploadUrls();
    final uploadUrls = uploadResponse['uploadUrls'] as Map<String, dynamic>;
    final imageUrl = uploadResponse['imageUrl'] as String;

    // 3. Upload thumbnail
    await apiService.uploadImage(
      uploadUrls['thumb'] as String,
      processed.thumbnailBytes,
    );

    // 4. Upload full image
    await apiService.uploadImage(
      uploadUrls['full'] as String,
      processed.fullBytes,
    );

    // 5. Create item in database
    await apiService.createItem(imageUrl: imageUrl, state: 'Unanswered');

    // 6. Clean up temporary file
    try {
      await file.delete();
    } catch (e) {
      // Log but don't fail upload if cleanup fails
      print('Warning: Failed to delete temporary file: $e');
    }
  }
}
