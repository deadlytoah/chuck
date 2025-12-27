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
  });
}
