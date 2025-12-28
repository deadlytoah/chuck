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

class ItemsGrid extends ConsumerStatefulWidget {
  final bool shrinkWrap;

  const ItemsGrid({super.key, this.shrinkWrap = false});

  @override
  ConsumerState<ItemsGrid> createState() => _ItemsGridState();
}

class _ItemsGridState extends ConsumerState<ItemsGrid> {
  String? _lastShownError;
  bool _isShowingDialog = false;

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final selectionState = ref.watch(selectionProvider);

    // Use ref.listen to react to error changes and show dialog
    // ref.listen fires after build completes, so we can show dialog directly
    ref.listen<ItemsState>(itemsProvider, (previous, next) {
      print('[ItemsGrid] Listen fired: prevError=${previous?.error}, '
          'nextError=${next.error}, lastShown=$_lastShownError, showing=$_isShowingDialog');

      // Show dialog if there's a new error that we haven't shown yet
      if (next.error != null &&
          next.error != _lastShownError &&
          !_isShowingDialog &&
          mounted) {
        print('[ItemsGrid] Showing dialog for error: ${next.error}');
        _lastShownError = next.error;
        _isShowingDialog = true;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(next.error!),
            actions: [
              TextButton(
                onPressed: () {
                  print('[ItemsGrid] OK tapped, closing dialog');
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ).then((_) {
          print('[ItemsGrid] Dialog dismissed, resetting flag');
          _isShowingDialog = false;
        });
      } else if (next.error == null && _lastShownError != null) {
        print('[ItemsGrid] Error cleared, resetting lastShown');
        _lastShownError = null;
      }
    });

    if (itemsState.isLoading && itemsState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (itemsState.items.isEmpty) {
      return const Center(child: Text('No items match your filter.'));
    }

    final gridView = GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
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
        if (widget.shrinkWrap) gridView else Expanded(child: gridView),
        if (itemsState.nextToken != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: itemsState.isLoading
                  ? null
                  : () {
                      final filter = ref.read(filterProvider);
                      final sort = ref.read(sortProvider);
                      ref
                          .read(itemsProvider.notifier)
                          .loadMore(filter: filter, sort: sort);
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
