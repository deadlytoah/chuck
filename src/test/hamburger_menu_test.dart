import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chuck/widgets/hamburger_menu.dart';

void main() {
  group('HamburgerMenu Widget Tests', () {
    testWidgets('HamburgerMenu renders correctly', (WidgetTester tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              trailing: HamburgerMenu(
                selectedIndex: selectedIndex,
                onItemSelected: (index) {},
              ),
            ),
            child: Container(),
          ),
        ),
      );

      expect(find.byType(HamburgerMenu), findsOneWidget);
      expect(find.byType(CupertinoButton), findsOneWidget);
    });

    testWidgets('Opens menu on tap', (WidgetTester tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              trailing: HamburgerMenu(
                selectedIndex: selectedIndex,
                onItemSelected: (index) {},
                menuOffset: const Offset(-152, 48),
              ),
            ),
            child: Container(),
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoButton));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('Selects item and closes menu', (WidgetTester tester) async {
      int selectedIndex = 0;
      int? tappedIndex;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              trailing: HamburgerMenu(
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  tappedIndex = index;
                },
                menuOffset: const Offset(-152, 48),
              ),
            ),
            child: Container(),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.byType(CupertinoButton));
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
