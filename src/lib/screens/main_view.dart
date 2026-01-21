import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/filter_bar.dart';
import '../widgets/items_grid.dart';
import '../widgets/folder_selector.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Load folders first
        await ref.read(foldersProvider.notifier).loadFolders();

        // Then load items for the current folder
        final currentFolderId = ref.read(foldersProvider).currentFolderId;
        if (currentFolderId != null) {
          final filter = ref.read(filterProvider);
          final sort = ref.read(sortProvider);
          await ref
              .read(itemsProvider.notifier)
              .loadItems(folderId: currentFolderId, filter: filter, sort: sort);
        }
      } catch (e) {
        // Silent failure on initial load - user can tap refresh button to retry
        print('Initial load failed: $e');
      }
    });

    // Listen for folder changes and reload items
    ref.listenManual(
      foldersProvider.select((s) => s.currentFolderId),
      (prev, next) {
        if (next != null && next != prev) {
          final filter = ref.read(filterProvider);
          final sort = ref.read(sortProvider);
          ref
              .read(itemsProvider.notifier)
              .loadItems(folderId: next, filter: filter, sort: sort);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SafeArea(
            bottom: false,
            child: const Center(child: FolderSelector()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: const FilterBar(),
        ),
        const Expanded(child: ItemsGrid()),
      ],
    );
  }
}
