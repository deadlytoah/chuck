import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:chuck/services/image_service.dart';

void main() {
  late ImageService imageService;

  setUp(() {
    imageService = ImageService();
  });

  group('ImageService - processImage', () {
    test('processImage with valid JPEG returns ProcessedImages', () async {
      final validJpeg = await File('test/fixtures/test_image.jpg').readAsBytes();

      final result = await imageService.processImage(validJpeg);

      expect(result, isA<ProcessedImages>());
      expect(result.thumbnailBytes, isNotEmpty);
      expect(result.fullBytes, isNotEmpty);
    });

    test('processImage with valid PNG returns ProcessedImages', () async {
      final validPng = await File('test/fixtures/test_image.png').readAsBytes();

      final result = await imageService.processImage(validPng);

      expect(result, isA<ProcessedImages>());
      expect(result.thumbnailBytes, isNotEmpty);
      expect(result.fullBytes, isNotEmpty);
    });

    test('processImage throws on file > 10MB', () async {
      final largeImage = await File('test/fixtures/large_test.jpg').readAsBytes();

      expect(
        () => imageService.processImage(largeImage),
        throwsA(isA<Exception>()),
      );
    });

    test('processImage throws on corrupted image data', () async {
      final corruptedData = Uint8List.fromList([1, 2, 3, 4, 5, 6]); // Invalid image

      expect(
        () => imageService.processImage(corruptedData),
        throwsA(isA<Exception>()),
      );
    });

  });

  group('ImageService - createDataUrl', () {
    test('createDataUrl produces valid data URL format', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final dataUrl = imageService.createDataUrl(bytes);

      expect(dataUrl, contains('data:image/jpeg;base64,'));
    });
  });
}
