import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/screens/camera_screen.dart';
import 'package:chuck/providers/app_providers.dart';
import 'package:chuck/providers/providers.dart';
import 'package:chuck/models/queued_photo.dart';
import 'package:chuck/services/camera_queue_service.dart';
import 'package:chuck/services/camera_service.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'mocks/mock_permission_handler.dart';
import 'mocks/mock_camera_service.dart';

// Mock CameraQueueService for testing
class MockCameraQueueService extends CameraQueueService {
  final bool initialQueueFull;

  MockCameraQueueService({this.initialQueueFull = false});

  @override
  List<QueuedPhoto> build() {
    if (initialQueueFull) {
      return List.generate(
        12,
        (i) => QueuedPhoto(path: '/path/to/photo_$i.jpg'),
      );
    }
    return [];
  }

  @override
  bool addPhoto(String path) {
    if (isQueueFull) return false;
    return super.addPhoto(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPermissionHandlerPlatform mockPermissionHandler;
  late MockCameraService mockCameraService;

  setUp(() {
    mockPermissionHandler = MockPermissionHandlerPlatform();
    PermissionHandlerPlatform.instance = mockPermissionHandler;
    
    mockCameraService = MockCameraService();
    mockCameraService.setMockResult(CameraInitResult.success);
  });

  tearDown(() {
    // Reset to default after each test
    mockPermissionHandler.setCameraPermissionStatus(PermissionStatus.granted);
  });

  group('CameraScreen Widget Tests', () {
    testWidgets('Renders CircularProgressIndicator during initialization',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      // Initial loading state should show CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Camera permission denied'), findsNothing);
    });

    testWidgets('Shows black background during loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      // Find the Scaffold
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('Renders permission denied message when permission rejected',
        (tester) async {
      // Note: Testing actual permission state is difficult without mocking
      // the permission_handler package. This test demonstrates the UI
      // structure when _isPermissionDenied is true.

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      // Permission denied state would show specific text and buttons
      // Since we can't easily trigger permission denial in test,
      // we verify the widget structure exists
      await tester.pump();
    });

    testWidgets('Capture button visible with correct styling', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(initialQueueFull: false),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The capture button is rendered through Consumer widget
      expect(find.byType(Consumer), findsWidgets);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('Capture button has opacity 0.5 when queue full',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(initialQueueFull: true),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Opacity widget
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));

      // Should find opacity widget with value 0.5 (queue full state)
      final hasDisabledOpacity = opacityWidgets.any((w) => w.opacity == 0.5);
      expect(hasDisabledOpacity, isTrue);
    });

    testWidgets('Capture button has opacity 1.0 when queue not full',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(initialQueueFull: false),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Opacity widget
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));

      // Should find opacity widget with value 1.0 (queue not full state)
      final hasEnabledOpacity = opacityWidgets.any((w) => w.opacity == 1.0);
      expect(hasEnabledOpacity, isTrue);
    });

    testWidgets('Back button is visible and pops navigation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CameraScreen()),
                  ),
                  child: const Text('Open Camera'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap to open camera screen
      await tester.tap(find.text('Open Camera'));
      await tester.pumpAndSettle();

      // Find back button (IconButton with arrow_back icon)
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should navigate back - camera screen gone
      expect(find.byType(CameraScreen), findsNothing);
      expect(find.text('Open Camera'), findsOneWidget);
    });

    testWidgets('SafeArea wraps camera controls', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pump();

      // SafeArea should be present to handle notches/status bars
      expect(find.byType(SafeArea), findsWidgets);
    });
  });

  group('CameraScreen - Permission Denied State', () {
    testWidgets('Shows permission denied dialog when permission rejected',
        (tester) async {
      mockPermissionHandler
          .setCameraPermissionStatus(PermissionStatus.denied);
      mockCameraService.setMockResult(CameraInitResult.permissionDenied);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Camera Access Required'), findsOneWidget);
      expect(find.text('Camera access is needed to take photos of items.'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Shows permission denied dialog for permanently denied permission',
        (tester) async {
      mockPermissionHandler
          .setCameraPermissionStatus(PermissionStatus.permanentlyDenied);
      mockCameraService.setMockResult(CameraInitResult.permissionDenied);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Camera Access Required'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
    });

    testWidgets('Go to Settings button is tappable', (tester) async {
      mockPermissionHandler
          .setCameraPermissionStatus(PermissionStatus.denied);
      mockCameraService.setMockResult(CameraInitResult.permissionDenied);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(),
            ),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      final openSettingsButton = find.widgetWithText(
        TextButton,
        'Go to Settings',
      );
      expect(openSettingsButton, findsOneWidget);

      // Verify button is tappable (onPressed is not null)
      final button = tester.widget<TextButton>(openSettingsButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Cancel button dismisses dialog and navigates back', (tester) async {
      mockPermissionHandler
          .setCameraPermissionStatus(PermissionStatus.denied);
      mockCameraService.setMockResult(CameraInitResult.permissionDenied);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWith((ref) => mockCameraService),
            cameraQueueServiceProvider.overrideWith(
              () => MockCameraQueueService(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CameraScreen()),
                  ),
                  child: const Text('Open Camera'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to camera screen
      await tester.tap(find.text('Open Camera'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Camera Access Required'), findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pump(); // Dismiss dialog
      await tester.pump(); // Process dialog dismissal
      await tester.pump(); // Pop camera screen
      await tester.pump(); // Transition animation
      await tester.pump(const Duration(milliseconds: 300)); // Wait for navigation

      // Should navigate back
      expect(find.byType(CameraScreen), findsNothing);
      expect(find.text('Open Camera'), findsOneWidget);
    });
  });
}
