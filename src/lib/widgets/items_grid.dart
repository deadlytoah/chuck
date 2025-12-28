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
  String? _previousError;
  bool _isShowingDialog = false;

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final selectionState = ref.watch(selectionProvider);

    // Show alert dialog when error changes
    if (itemsState.error != null &&
        itemsState.error != _previousError &&
        !_isShowingDialog) {
      print('[ItemsGrid] Scheduling dialog: error=${itemsState.error}, '
          'prev=$_previousError, showing=$_isShowingDialog');
      _previousError = itemsState.error;
      _isShowingDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('[ItemsGrid] PostFrameCallback executing, showing dialog');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text(itemsState.error!),
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
            // Ensure flag is reset even if dialog dismissed by other means
            if (mounted) {
              setState(() {
                _isShowingDialog = false;
              });
            }
          });
        }
      });
    } else if (itemsState.error == null) {
      if (_previousError != null) {
        print('[ItemsGrid] Error cleared, resetting previous');
      }
      _previousError = null;
    } else {
      print('[ItemsGrid] Build: error=${itemsState.error}, '
          'prev=$_previousError, showing=$_isShowingDialog (no action)');
    }

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
