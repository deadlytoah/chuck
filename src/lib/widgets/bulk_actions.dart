import 'package:flutter/cupertino.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

@Preview()
Widget bulkActionsPreview() {
  return const ProviderScope(
    child: CupertinoApp(
      home: CupertinoPageScaffold(
        child: Padding(padding: EdgeInsets.all(16.0), child: BulkActions()),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (!selectionState.isSelectionMode)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                ref.read(selectionProvider.notifier).toggleSelectionMode();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.check_mark_circled, size: 20),
                  SizedBox(width: 8),
                  Text('Bulk Archive'),
                ],
              ),
            ),
          if (selectionState.isSelectionMode) ...[
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.destructiveRed,
              borderRadius: BorderRadius.circular(8),
              onPressed: selectedCount > 0 ? () => _bulkArchive(context, ref) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.archivebox, size: 20, color: CupertinoColors.white),
                  SizedBox(width: 8),
                  Text('Archive Selected', style: TextStyle(color: CupertinoColors.white)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.systemGrey,
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                ref.read(selectionProvider.notifier).toggleSelectionMode();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.xmark, size: 20, color: CupertinoColors.white),
                  SizedBox(width: 8),
                  Text('Cancel', style: TextStyle(color: CupertinoColors.white)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _bulkArchive(BuildContext context, WidgetRef ref) async {
    final selectedCount = ref.read(selectionProvider).selectedIds.length;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Confirm Bulk Archive'),
        content: Text('Archive $selectedCount items?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
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
          await showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Success'),
              content: Text('Successfully archived ${result.archived.length} items'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          await showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Partial Success'),
              content: Text(
                'Archived ${result.archived.length} items.\n'
                'Failed: ${result.failed.length}',
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Failed Items'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Failed to archive ${result.failed.length} items:'),
                              const SizedBox(height: 8),
                              ...result.failed.map(
                                (id) => Text('• $id', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          CupertinoDialogAction(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Details'),
                ),
              ],
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
        await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Error: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
