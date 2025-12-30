import 'package:flutter/cupertino.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

@Preview()
Widget filterBarPreview() {
  return const ProviderScope(
    child: CupertinoApp(
      home: CupertinoPageScaffold(
        child: Padding(padding: EdgeInsets.all(16.0), child: FilterBar()),
      ),
    ),
  );
}

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final sort = ref.watch(sortProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () => _showFilterPicker(context, ref),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getFilterLabel(filter),
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 16,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () => _showSortPicker(context, ref),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getSortLabel(sort),
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 16,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _refresh(ref, context),
            child: const Icon(
              CupertinoIcons.refresh,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String? filter) {
    switch (filter) {
      case null:
        return 'All';
      case 'Chuck':
        return 'Chuck';
      case 'Keep':
        return 'Keep';
      case 'Sell':
        return 'Sell';
      case 'Undecided':
        return 'Undecided';
      case 'Unanswered':
        return 'Unanswered';
      case 'archived':
        return 'Archived';
      default:
        return filter;
    }
  }

  String _getSortLabel(String? sort) {
    switch (sort) {
      case 'updatedAt:desc':
        return 'Updated \u{25BC}';
      case 'updatedAt:asc':
        return 'Updated \u{25B2}';
      case null:
        return 'Created \u{25BC}';
      case 'createdAt:asc':
        return 'Created \u{25B2}';
      case 'state':
        return 'State';
      default:
        return sort;
    }
  }

  void _showFilterPicker(BuildContext context, WidgetRef ref) {
    final filters = [null, 'Chuck', 'Keep', 'Sell', 'Undecided', 'Unanswered', 'archived'];
    final labels = ['All', 'Chuck', 'Keep', 'Sell', 'Undecided', 'Unanswered', 'Archived'];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Filter'),
        actions: List.generate(
          filters.length,
          (index) => CupertinoActionSheetAction(
            onPressed: () {
              ref.read(filterProvider.notifier).state = filters[index];
              _refresh(ref, context, filterOverride: filters[index]);
              Navigator.pop(context);
            },
            child: Text(labels[index]),
          ),
        ),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showSortPicker(BuildContext context, WidgetRef ref) {
    final sorts = ['updatedAt:desc', 'updatedAt:asc', null, 'createdAt:asc', 'state'];
    final labels = ['Updated \u{25BC}', 'Updated \u{25B2}', 'Created \u{25BC}', 'Created \u{25B2}', 'State'];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Sort'),
        actions: List.generate(
          sorts.length,
          (index) => CupertinoActionSheetAction(
            onPressed: () {
              ref.read(sortProvider.notifier).state = sorts[index];
              _refresh(ref, context, sortOverride: sorts[index]);
              Navigator.pop(context);
            },
            child: Text(labels[index]),
          ),
        ),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _refresh(WidgetRef ref, BuildContext context, {String? filterOverride, String? sortOverride}) async {
    try {
      final filter = filterOverride ?? ref.read(filterProvider);
      final sort = sortOverride ?? ref.read(sortProvider);
      await ref.read(itemsProvider.notifier).loadItems(filter: filter, sort: sort);
    } catch (e) {
      print('Load items error: $e');
      if (context.mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Unable to load items'),
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
