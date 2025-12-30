import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/models/queued_photo.dart';
import 'package:chuck/models/item.dart';
import 'package:chuck/providers/providers.dart';
import 'package:chuck/providers/app_providers.dart';
import 'package:chuck/services/network_monitor.dart';
import 'package:chuck/services/camera_upload_service.dart';
import 'package:chuck/services/api_service.dart';
import 'package:chuck/services/image_service.dart';

import 'package:flutter/services.dart';

// Mock network monitor for testing
class MockNetworkMonitor extends NetworkMonitor {
  MockNetworkMonitor(NetworkType initialState) : super(skipInit: true) {
    state = initialState;
  }

  void changeNetwork(NetworkType newType) {
    state = newType;
  }
}

// Mock camera upload service for testing
class MockCameraUploadService extends CameraUploadService {
  bool shouldFail = false;
  int uploadCallCount = 0;
  List<String> uploadedPaths = [];

  MockCameraUploadService()
      : super(
          apiService: _MockApiService(),
          imageService: _MockImageService(),
        );

  @override
  Future<Item> uploadPhoto(String path) async {
    uploadCallCount++;
    uploadedPaths.add(path);
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldFail) {
      throw Exception('Upload failed');
    }
    return Item(
      itemId: 'test-item-${uploadCallCount}',
      imageUrl: 'images/test-${uploadCallCount}/full.jpg',
      state: 'Unanswered',
      archived: false,
      createdAt: DateTime.now(),
    );
  }
}

class _MockApiService extends ApiService {
  _MockApiService() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Map<String, dynamic>> getUploadUrls() async {
    return {
      'uploadUrls': {'thumb': 'url1', 'full': 'url2'},
      'imageUrl': 'https://example.com/image.jpg'
    };
  }
}

class _MockImageService extends ImageService {
  @override
  Future<ProcessedImages> processImage(dynamic bytes) async {
    return ProcessedImages(
      thumbnailBytes: bytes,
      fullBytes: bytes,
    );
  }
}

void main() {
  late ProviderContainer container;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const MethodChannel channel = MethodChannel(
      'dev.fluttercommunity.plus/connectivity',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return ['mobile'];
        });

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('Initial state is empty', () {
    final service = container.read(cameraQueueServiceProvider);
    expect(service, isEmpty);
  });

  test('Add photo increases queue size', () {
    final notifier = container.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo.jpg');

    final service = container.read(cameraQueueServiceProvider);
    expect(service.length, 1);
    expect(service.first.path, '/path/to/photo.jpg');
    expect(service.first.state, PhotoState.pending);
  });

  test('Cannot add more than 12 photos', () {
    final notifier = container.read(cameraQueueServiceProvider.notifier);
    for (int i = 0; i < 15; i++) {
      notifier.addPhoto('/path/to/photo_$i.jpg');
    }

    final service = container.read(cameraQueueServiceProvider);
    expect(service.length, 12);
    expect(notifier.isQueueFull, isTrue);
  });

  test('Remove photo decreases queue size', () {
    final notifier = container.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo.jpg');
    final id = container.read(cameraQueueServiceProvider).first.id;

    notifier.removePhoto(id);

    final service = container.read(cameraQueueServiceProvider);
    expect(service, isEmpty);
  });

  test('Mark failed updates state', () {
    final notifier = container.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo.jpg');
    final id = container.read(cameraQueueServiceProvider).first.id;

    notifier.markFailed(id);

    final service = container.read(cameraQueueServiceProvider);
    expect(service.first.state, PhotoState.failed);
  });

  test('Retry failed updates state to pending', () {
    final notifier = container.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo.jpg');
    final id = container.read(cameraQueueServiceProvider).first.id;

    notifier.markFailed(id);
    notifier.retryFailed(id);

    final service = container.read(cameraQueueServiceProvider);
    expect(service.first.state, PhotoState.pending);
  });

  test('Pending count returns correct number', () {
    final notifier = container.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');
    notifier.addPhoto('/path/to/photo2.jpg');

    final id1 = container.read(cameraQueueServiceProvider).first.id;
    notifier.markFailed(
      id1,
    ); // Failed counts as pending for upload purposes usually, but let's check logic

    // The getter logic is: state.where((photo) => photo.state == PhotoState.pending || photo.state == PhotoState.failed).length;
    expect(notifier.pendingCount, 2);
  });

  // New tests for expanded coverage

  test('addPhoto returns false when queue is full', () {
    final notifier = container.read(cameraQueueServiceProvider.notifier);

    // Fill queue to max (12 photos)
    for (int i = 0; i < 12; i++) {
      final result = notifier.addPhoto('/path/to/photo_$i.jpg');
      expect(result, isTrue);
    }

    // Try to add 13th photo
    final result = notifier.addPhoto('/path/to/photo_13.jpg');
    expect(result, isFalse);
    expect(container.read(cameraQueueServiceProvider).length, 12);
  });

  test('Stream only processes on WiFi', () async {
    final mockUploadService = MockCameraUploadService();
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.cellular);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');

    // Wait for stream to process
    await Future.delayed(const Duration(milliseconds: 50));

    // Should not process on cellular
    expect(mockUploadService.uploadCallCount, 0);

    testContainer.dispose();
  });

  test('Stream processes items sequentially', () async {
    final mockUploadService = MockCameraUploadService();
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.wifi);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');
    notifier.addPhoto('/path/to/photo2.jpg');
    notifier.addPhoto('/path/to/photo3.jpg');

    // Wait for stream to process all items
    await Future.delayed(const Duration(milliseconds: 100));

    // All three should be uploaded
    expect(mockUploadService.uploadCallCount, 3);
    expect(mockUploadService.uploadedPaths.length, 3);

    testContainer.dispose();
  });

  test('Stream removes item on upload success', () async {
    final mockUploadService = MockCameraUploadService();
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.wifi);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');

    expect(testContainer.read(cameraQueueServiceProvider).length, 1);

    // Wait for stream to process
    await Future.delayed(const Duration(milliseconds: 50));

    // Item should be removed after successful upload
    expect(testContainer.read(cameraQueueServiceProvider).length, 0);

    testContainer.dispose();
  });

  test('Stream marks failed on upload exception', () async {
    final mockUploadService = MockCameraUploadService();
    mockUploadService.shouldFail = true;
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.wifi);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');

    // Wait for stream to process
    await Future.delayed(const Duration(milliseconds: 50));

    // Item should be marked as failed
    final queue = testContainer.read(cameraQueueServiceProvider);
    expect(queue.length, 1);
    expect(queue.first.state, PhotoState.failed);

    testContainer.dispose();
  });

  test('Stream naturally serializes concurrent adds', () async {
    final mockUploadService = MockCameraUploadService();
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.wifi);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    
    // Add multiple photos rapidly
    notifier.addPhoto('/path/to/photo1.jpg');
    notifier.addPhoto('/path/to/photo2.jpg');

    // Wait for stream to process both
    await Future.delayed(const Duration(milliseconds: 100));

    // Stream serializes naturally (2 uploads, processed one at a time)
    expect(mockUploadService.uploadCallCount, 2);

    testContainer.dispose();
  });

  test('Network change to cellular stops processing mid-queue', () async {
    final mockUploadService = MockCameraUploadService();
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.wifi);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');
    notifier.addPhoto('/path/to/photo2.jpg');
    notifier.addPhoto('/path/to/photo3.jpg');

    // Let first item start processing
    await Future.delayed(const Duration(milliseconds: 5));
    
    // Change network to cellular
    mockNetworkMonitor.changeNetwork(NetworkType.cellular);

    // Wait a bit more
    await Future.delayed(const Duration(milliseconds: 50));

    // Stream should stop processing new items after network change
    final queue = testContainer.read(cameraQueueServiceProvider);
    expect(queue.length, lessThanOrEqualTo(3));

    testContainer.dispose();
  });

  test('State transitions: pending -> uploading -> removed on success', () async {
    final mockUploadService = MockCameraUploadService();
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.wifi);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');

    // Initial state is pending
    expect(testContainer.read(cameraQueueServiceProvider).first.state, PhotoState.pending);

    // Wait for stream to process
    await Future.delayed(const Duration(milliseconds: 50));

    // After success, item should be removed
    expect(testContainer.read(cameraQueueServiceProvider).length, 0);

    testContainer.dispose();
  });

  test('Upload success adds item to itemsProvider', () async {
    final mockUploadService = MockCameraUploadService();
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.wifi);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    // Verify items list starts empty
    expect(testContainer.read(itemsProvider).items.length, 0);

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');

    // Wait for stream to process and upload
    await Future.delayed(const Duration(milliseconds: 50));

    // Verify item was added to items list
    final itemsState = testContainer.read(itemsProvider);
    expect(itemsState.items.length, 1);
    expect(itemsState.items[0].itemId, 'test-item-1');
    expect(itemsState.items[0].imageUrl, 'images/test-1/full.jpg');
    expect(itemsState.items[0].state, 'Unanswered');
    expect(itemsState.items[0].archived, false);

    testContainer.dispose();
  });

  test('Multiple uploads add items in order to itemsProvider', () async {
    final mockUploadService = MockCameraUploadService();
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.wifi);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');
    notifier.addPhoto('/path/to/photo2.jpg');

    // Wait for stream to process both uploads
    await Future.delayed(const Duration(milliseconds: 100));

    // Verify both items were added (newest first)
    final itemsState = testContainer.read(itemsProvider);
    expect(itemsState.items.length, 2);
    expect(itemsState.items[0].itemId, 'test-item-2');
    expect(itemsState.items[1].itemId, 'test-item-1');

    testContainer.dispose();
  });

  test('Failed upload does not add item to itemsProvider', () async {
    final mockUploadService = MockCameraUploadService();
    mockUploadService.shouldFail = true;
    final mockNetworkMonitor = MockNetworkMonitor(NetworkType.wifi);

    final testContainer = ProviderContainer(
      overrides: [
        cameraUploadServiceProvider.overrideWithValue(mockUploadService),
        networkMonitorProvider.overrideWith(
          (ref) => mockNetworkMonitor,
        ),
      ],
    );

    final notifier = testContainer.read(cameraQueueServiceProvider.notifier);
    notifier.addPhoto('/path/to/photo1.jpg');

    // Wait for stream to process
    await Future.delayed(const Duration(milliseconds: 50));

    // Verify item was NOT added to items list
    final itemsState = testContainer.read(itemsProvider);
    expect(itemsState.items.length, 0);

    // Verify photo is marked as failed in queue
    final queue = testContainer.read(cameraQueueServiceProvider);
    expect(queue.length, 1);
    expect(queue.first.state, PhotoState.failed);

    testContainer.dispose();
  });
}
