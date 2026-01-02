import 'package:flutter/cupertino.dart';
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
import '../models/queued_photo.dart';

@Preview()
Widget homePagePreview() {
  return const ProviderScope(child: CupertinoApp(home: HomePage()));
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
    final queueCount = ref.watch(
      cameraQueueServiceProvider.select((photos) => photos
          .where((p) =>
              p.state == PhotoState.pending || p.state == PhotoState.failed)
          .length),
    );

    return CupertinoPageScaffold(
      child: Stack(
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
            bottom: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedIndex == 0) ...[
                    QueueStatusButton(
                      count: queueCount,
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => const QueueReviewScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                  ],
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: HamburgerMenu(
                      selectedIndex: _selectedIndex,
                      onItemSelected: _onItemSelected,
                    ),
                  ),
                  if (_selectedIndex == 0) ...[
                    const SizedBox(width: 16),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => const CameraScreen()),
                          );
                        },
                        child: const Icon(
                          CupertinoIcons.camera,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
