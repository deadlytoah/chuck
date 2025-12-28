import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuck/screens/home_page.dart';
import 'package:chuck/widgets/queue_status_button.dart';
import 'package:chuck/providers/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const MethodChannel channel = MethodChannel(
      'dev.fluttercommunity.plus/connectivity',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return ['mobile'];
    });
  });

  group('HomePage Widget Tests', () {
    testWidgets('QueueStatusButton shows 0 when queue is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomePage()),
        ),
      );

      expect(find.byType(QueueStatusButton), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNWidgets(2));
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('QueueStatusButton shows count when queue has items', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queueService = container.read(cameraQueueServiceProvider.notifier);
      queueService.addPhoto('/test/1.jpg');
      queueService.addPhoto('/test/2.jpg');
      queueService.markFailed(container.read(cameraQueueServiceProvider)[0].id);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomePage()),
        ),
      );

      expect(find.byType(QueueStatusButton), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNWidgets(2));

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('Camera FAB is always visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomePage()),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('FABs are visible on Main View (tab index 0)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomePage()),
        ),
      );

      // FABs should be visible on Main View
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byType(QueueStatusButton), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNWidgets(2));
    });

    testWidgets('FABs are hidden on Admin Page (tab index 1)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomePage()),
        ),
      );

      // Initially FABs should be visible on Main View
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byType(QueueStatusButton), findsOneWidget);

      // Open hamburger menu
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Tap "Admin" to switch to Admin Page
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      // FABs should NOT be visible on Admin Page
      expect(find.byIcon(Icons.camera_alt), findsNothing);
      expect(find.byType(QueueStatusButton), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('FABs reappear when switching back to Main View', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomePage()),
        ),
      );

      // Switch to Admin Page
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      // FABs should be hidden
      expect(find.byIcon(Icons.camera_alt), findsNothing);

      // Switch back to Home
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // FABs should reappear
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byType(QueueStatusButton), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNWidgets(2));
    });
  });
}
