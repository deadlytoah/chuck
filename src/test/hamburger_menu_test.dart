import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chuck/widgets/hamburger_menu.dart';

void main() {
  group('HamburgerMenu Widget Tests', () {
    testWidgets('HamburgerMenu renders correctly', (WidgetTester tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                HamburgerMenu(
                  selectedIndex: selectedIndex,
                  onItemSelected: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(HamburgerMenu), findsOneWidget);
      expect(find.byType(AnimatedIcon), findsOneWidget);
    });

    testWidgets('Opens menu on tap', (WidgetTester tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                HamburgerMenu(
                  selectedIndex: selectedIndex,
                  onItemSelected: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('Selects item and closes menu', (WidgetTester tester) async {
      int selectedIndex = 0;
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                HamburgerMenu(
                  selectedIndex: selectedIndex,
                  onItemSelected: (index) {
                    tappedIndex = index;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Tap Admin
      await tester.tap(find.text('Admin'));
      await tester.pump(); // Start animation
      await tester.pump(
        const Duration(seconds: 1),
      ); // Wait for animation to complete

      expect(tappedIndex, 1);
      expect(find.text('Admin'), findsNothing); // Menu should be closed
    });
  });
}
