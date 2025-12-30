import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:chuck/services/camera_upload_service.dart';
import 'package:chuck/services/api_service.dart';
import 'package:chuck/services/image_service.dart';
import 'package:chuck/models/item.dart';

// Mock API Service
class MockApiService extends ApiService {
  bool shouldFailGetUrls = false;
  bool shouldFailUpload = false;
  bool shouldFailCreateItem = false;

  int getUploadUrlsCallCount = 0;
  int uploadImageCallCount = 0;
  int createItemCallCount = 0;

  List<String> uploadedUrls = [];
  List<List<int>> uploadedData = [];

  MockApiService() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Map<String, dynamic>> getUploadUrls() async {
    getUploadUrlsCallCount++;
    if (shouldFailGetUrls) {
      throw Exception('Failed to get upload URLs');
    }
    return {
      'uploadUrls': {
        'thumb': 'https://s3.example.com/thumb.jpg',
        'full': 'https://s3.example.com/full.jpg',
      },
      'imageUrl': 'https://cdn.example.com/image.jpg',
    };
  }

  @override
  Future<void> uploadImage(String presignedUrl, List<int> imageData) async {
    uploadImageCallCount++;
    uploadedUrls.add(presignedUrl);
    uploadedData.add(imageData);
    if (shouldFailUpload) {
      throw Exception('Failed to upload image');
    }
  }

  @override
  Future<Item> createItem({
    required String imageUrl,
    String state = 'Unanswered',
  }) async {
    createItemCallCount++;
    if (shouldFailCreateItem) {
      throw Exception('Failed to create item');
    }
    return Item(
      itemId: 'test-item-id',
      imageUrl: imageUrl,
      state: state,
      createdAt: DateTime.now(),
      archived: false,
    );
  }
}

// Mock Image Service
class MockImageService extends ImageService {
  bool shouldFail = false;
  int processImageCallCount = 0;
  Uint8List? lastProcessedBytes;

  @override
  Future<ProcessedImages> processImage(Uint8List fileBytes) async {
    processImageCallCount++;
    lastProcessedBytes = fileBytes;
    if (shouldFail) {
      throw Exception('Failed to process image');
    }
    return ProcessedImages(
      thumbnailBytes: Uint8List.fromList([1, 2, 3, 4]), // Mock thumbnail
      fullBytes: Uint8List.fromList([5, 6, 7, 8]), // Mock full image
    );
  }
}

void main() {
  late MockApiService mockApiService;
  late MockImageService mockImageService;
  late CameraUploadService uploadService;
  late Directory tempDir;

  setUp(() async {
    mockApiService = MockApiService();
    mockImageService = MockImageService();
    uploadService = CameraUploadService(
      apiService: mockApiService,
      imageService: mockImageService,
    );

    // Create temp directory for test files
    tempDir = await Directory.systemTemp.createTemp('camera_upload_test_');
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CameraUploadService', () {
    test('uploadPhoto success path - all steps complete', () async {
      // Create a test file
      final testFile = File('${tempDir.path}/test.jpg');
      await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header

      await uploadService.uploadPhoto(testFile.path);

      // Verify all service calls were made
      expect(mockImageService.processImageCallCount, 1);
      expect(mockApiService.getUploadUrlsCallCount, 1);
      expect(mockApiService.uploadImageCallCount, 2); // thumb + full
      expect(mockApiService.createItemCallCount, 1);
    });

    test('uploadPhoto throws FileNotFoundException for missing file', () async {
      final nonExistentPath = '${tempDir.path}/nonexistent.jpg';

      expect(
        () => uploadService.uploadPhoto(nonExistentPath),
        throwsA(isA<Exception>()),
      );
    });

    test('uploadPhoto calls imageService.processImage with file bytes', () async {
      final testFile = File('${tempDir.path}/test.jpg');
      final testData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      await testFile.writeAsBytes(testData);

      await uploadService.uploadPhoto(testFile.path);

      expect(mockImageService.processImageCallCount, 1);
      expect(mockImageService.lastProcessedBytes, equals(testData));
    });

    test('uploadPhoto calls createItem and returns Item', () async {
      final testFile = File('${tempDir.path}/test.jpg');
      await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

      final result = await uploadService.uploadPhoto(testFile.path);

      expect(mockApiService.createItemCallCount, 1);
      expect(result, isA<Item>());
      expect(result.itemId, 'test-item-id');
      expect(result.state, 'Unanswered');
      expect(result.archived, false);
    });

    test('uploadPhoto throws if processImage fails', () async {
      final testFile = File('${tempDir.path}/test.jpg');
      await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

      mockImageService.shouldFail = true;

      expect(
        () => uploadService.uploadPhoto(testFile.path),
        throwsA(isA<Exception>()),
      );
    });

    test('uploadPhoto throws if getUploadUrls fails', () async {
      final testFile = File('${tempDir.path}/test.jpg');
      await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

      mockApiService.shouldFailGetUrls = true;

      expect(
        () => uploadService.uploadPhoto(testFile.path),
        throwsA(isA<Exception>()),
      );
    });

    test('uploadPhoto throws if image upload fails', () async {
      final testFile = File('${tempDir.path}/test.jpg');
      await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

      mockApiService.shouldFailUpload = true;

      expect(
        () => uploadService.uploadPhoto(testFile.path),
        throwsA(isA<Exception>()),
      );
    });

    test('uploadPhoto throws if createItem fails', () async {
      final testFile = File('${tempDir.path}/test.jpg');
      await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

      mockApiService.shouldFailCreateItem = true;

      expect(
        () => uploadService.uploadPhoto(testFile.path),
        throwsA(isA<Exception>()),
      );
    });
  });
}
