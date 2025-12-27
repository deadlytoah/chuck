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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filter = ref.read(filterProvider);
      final sort = ref.read(sortProvider);
      ref.read(itemsProvider.notifier).loadItems(filter: filter, sort: sort);
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
