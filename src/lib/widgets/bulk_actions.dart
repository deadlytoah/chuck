import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

@Preview()
Widget bulkActionsPreview() {
  return const ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Padding(padding: EdgeInsets.all(16.0), child: BulkActions()),
      ),
    ),
  );
}

class BulkActions extends ConsumerWidget {
  const BulkActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final selectedCount = selectionState.selectedIds.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (!selectionState.isSelectionMode)
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(selectionProvider.notifier).toggleSelectionMode();
                },
                icon: const Icon(Icons.check_box_outline_blank),
                label: const Text('Bulk Archive'),
              ),
            if (selectionState.isSelectionMode) ...[
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(selectionProvider.notifier).toggleSelectionMode();
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              if (selectedCount > 0)
                ElevatedButton.icon(
                  onPressed: () => _bulkArchive(context, ref),
                  icon: const Icon(Icons.archive),
                  label: const Text('Archive Selected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _bulkArchive(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Archive'),
        content: Text(
          'Archive ${ref.read(selectionProvider).selectedIds.length} items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final selectedIds = ref.read(selectionProvider).selectedIds.toList();
    final apiService = ref.read(apiServiceProvider);

    try {
      final result = await apiService.bulkArchive(selectedIds);

      if (context.mounted) {
        if (result.failed.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully archived ${result.archived.length} items',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Archived ${result.archived.length} items. '
                'Failed: ${result.failed.length}',
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Details',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Failed Items'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Failed to archive ${result.failed.length} items:',
                          ),
                          const SizedBox(height: 8),
                          ...result.failed.map(
                            (id) => Text(
                              '• $id',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
      }

      // Clear selection and refresh
      ref.read(selectionProvider.notifier).clearSelection();
      ref.read(selectionProvider.notifier).toggleSelectionMode();

      final filter = ref.read(filterProvider);
      final sort = ref.read(sortProvider);
      ref.read(itemsProvider.notifier).loadItems(filter: filter, sort: sort);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
