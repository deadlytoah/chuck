import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageService {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int thumbWidth = 200;
  static const int thumbHeight = 150;
  static const int fullWidth = 1200;
  static const int fullHeight = 900;

  Future<ProcessedImages> processImage(Uint8List fileBytes) async {
    if (fileBytes.length > maxFileSizeBytes) {
      throw Exception('Image exceeds 10MB limit');
    }

    final image = img.decodeImage(fileBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final thumbnail = _resizeImage(image, thumbWidth, thumbHeight);
    final full = _resizeImage(image, fullWidth, fullHeight);

    final thumbBytes = img.encodeJpg(thumbnail, quality: 85);
    final fullBytes = img.encodeJpg(full, quality: 85);

    return ProcessedImages(
      thumbnailBytes: Uint8List.fromList(thumbBytes),
      fullBytes: Uint8List.fromList(fullBytes),
    );
  }

  img.Image _resizeImage(img.Image image, int maxWidth, int maxHeight) {
    final aspectRatio = image.width / image.height;
    final targetAspect = maxWidth / maxHeight;

    int targetWidth;
    int targetHeight;

    if (aspectRatio > targetAspect) {
      targetWidth = maxWidth;
      targetHeight = (maxWidth / aspectRatio).round();
    } else {
      targetHeight = maxHeight;
      targetWidth = (maxHeight * aspectRatio).round();
    }

    return img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  String createDataUrl(Uint8List bytes) {
    final base64 = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64';
  }
}

class ProcessedImages {
  final Uint8List thumbnailBytes;
  final Uint8List fullBytes;

  ProcessedImages({required this.thumbnailBytes, required this.fullBytes});
}
