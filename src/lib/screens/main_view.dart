import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/filter_bar.dart';
import '../widgets/items_grid.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> {
  bool _hasShownLoadError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final filter = ref.read(filterProvider);
        final sort = ref.read(sortProvider);
        await ref.read(itemsProvider.notifier).loadItems(filter: filter, sort: sort);
      } catch (e) {
        print('Load items error: $e');
        if (mounted && !_hasShownLoadError) {
          _hasShownLoadError = true;
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Unable to load items'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const FilterBar(),
          ),
        ),
        const Expanded(child: ItemsGrid()),
      ],
    );
  }
}
