import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_view.dart';
import 'admin_page.dart';
import 'camera_screen.dart';
import 'queue_review_screen.dart';
import '../widgets/hamburger_menu.dart';
import '../widgets/queue_status_button.dart';
import '../widgets/failed_upload_banner.dart';
import '../providers/providers.dart';

@Preview()
Widget homePagePreview() {
  return const ProviderScope(child: MaterialApp(home: HomePage()));
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [MainView(), AdminPage()];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final queueCount =
        ref.watch(cameraQueueServiceProvider.notifier).pendingCount;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const FailedUploadBanner(),
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: _screens),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: HamburgerMenu(
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onItemSelected,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QueueStatusButton(
            count: queueCount,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QueueReviewScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
            heroTag: 'camera',
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
