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
  @override
  void initState() {
    super.initState();
    print('[MainView] initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('[MainView] postFrameCallback executing');
      try {
        final filter = ref.read(filterProvider);
        final sort = ref.read(sortProvider);
        await ref.read(itemsProvider.notifier).loadItems(filter: filter, sort: sort);
        print('[MainView] loadItems succeeded');
      } catch (e) {
        print('[MainView] Load items error: $e');
        if (mounted) {
          print('[MainView] Showing error dialog');
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Unable to load items'),
              actions: [
                TextButton(
                  onPressed: () {
                    print('[MainView] OK tapped');
                    Navigator.pop(context);
                  },
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
