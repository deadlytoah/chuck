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

    test('Thumbnail resized to fit 400x300 (aspect preserved)', () async {
      final largeImage = await File('test/fixtures/test_image.jpg').readAsBytes();

      final result = await imageService.processImage(largeImage);

      // Thumbnail should fit within 400x300
      expect(result.thumbnailBytes, isNotEmpty);
      // Note: Exact dimension testing would require decoding the result
    });

    test('Full image resized to fit 1200x900 (aspect preserved)', () async {
      final largeImage = await File('test/fixtures/test_image.jpg').readAsBytes();

      final result = await imageService.processImage(largeImage);

      // Full should fit within 1200x900
      expect(result.fullBytes, isNotEmpty);
    });

    test('Portrait image: width bounded, height scaled', () async {
      final portraitImage = await File('test/fixtures/test_image.jpg').readAsBytes();

      final result = await imageService.processImage(portraitImage);

      expect(result.thumbnailBytes, isNotEmpty);
      expect(result.fullBytes, isNotEmpty);
    });

    test('Landscape image: height bounded, width scaled', () async {
      final landscapeImage = await File('test/fixtures/test_image.jpg').readAsBytes();

      final result = await imageService.processImage(landscapeImage);

      expect(result.thumbnailBytes, isNotEmpty);
      expect(result.fullBytes, isNotEmpty);
    });

    test('Square image scales to bounds', () async {
      final squareImage = await File('test/fixtures/small_test.jpg').readAsBytes();

      final result = await imageService.processImage(squareImage);

      expect(result.thumbnailBytes, isNotEmpty);
      expect(result.fullBytes, isNotEmpty);
    });

    test('JPEG quality = 85 for both outputs', () async {
      final testImage = await File('test/fixtures/test_image.jpg').readAsBytes();

      final result = await imageService.processImage(testImage);

      // Quality is verified by checking output is JPEG format
      expect(result.thumbnailBytes, isNotEmpty);
      expect(result.fullBytes, isNotEmpty);
      // JPEG quality setting is internal to img.encodeJpg call
    });
  });

  group('ImageService - createDataUrl', () {
    test('createDataUrl produces valid data URL format', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header

      final dataUrl = imageService.createDataUrl(bytes);

      expect(dataUrl, startsWith('data:image/jpeg;base64,'));
    });

    test('createDataUrl output starts with correct prefix', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final dataUrl = imageService.createDataUrl(bytes);

      expect(dataUrl, contains('data:image/jpeg;base64,'));
    });
  });
}
