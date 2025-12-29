import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'item_card.dart';

@Preview()
Widget itemsGridPreview() {
  return const ProviderScope(
    child: MaterialApp(home: Scaffold(body: ItemsGrid(shrinkWrap: true))),
  );
}

class ItemsGrid extends ConsumerWidget {
  final bool shrinkWrap;

  const ItemsGrid({super.key, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(itemsProvider);
    final selectionState = ref.watch(selectionProvider);

    if (itemsState.isLoading && itemsState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (itemsState.items.isEmpty) {
      return const Center(child: Text('No items match your filter.'));
    }

    final gridView = GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.80,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemsState.items.length,
      itemBuilder: (context, index) {
        final item = itemsState.items[index];
        return ItemCard(
          item: item,
          showCheckbox: selectionState.isSelectionMode,
          isSelected: selectionState.selectedIds.contains(item.itemId),
        );
      },
    );

    return Column(
      children: [
        if (shrinkWrap) gridView else Expanded(child: gridView),
        if (itemsState.nextToken != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: itemsState.isLoading
                  ? null
                  : () async {
                      try {
                        final filter = ref.read(filterProvider);
                        final sort = ref.read(sortProvider);
                        await ref
                            .read(itemsProvider.notifier)
                            .loadMore(filter: filter, sort: sort);
                      } catch (e) {
                        print('Load more items error: $e');
                        if (context.mounted) {
                          showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Error'),
                              content: const Text('Unable to load more items'),
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
                    },
              child: itemsState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load More'),
            ),
          ),
      ],
    );
  }
}
