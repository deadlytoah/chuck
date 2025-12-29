import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

@Preview()
Widget filterBarPreview() {
  return const ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Padding(padding: EdgeInsets.all(16.0), child: FilterBar()),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: DropdownButtonFormField<String?>(
                initialValue: filter,
                decoration: const InputDecoration(
                  labelText: 'Filter',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'Chuck', child: Text('Chuck')),
                  DropdownMenuItem(value: 'Keep', child: Text('Keep')),
                  DropdownMenuItem(value: 'Sell', child: Text('Sell')),
                  DropdownMenuItem(
                    value: 'Undecided',
                    child: Text('Undecided'),
                  ),
                  DropdownMenuItem(
                    value: 'Unanswered',
                    child: Text('Unanswered'),
                  ),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (value) {
                  ref.read(filterProvider.notifier).state = value;
                  _refresh(ref, context, filterOverride: value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: DropdownButtonFormField<String?>(
                initialValue: sort,
                decoration: const InputDecoration(
                  labelText: 'Sort',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'updatedAt:desc',
                    child: Text('Updated \u{25BC}'),
                  ),
                  DropdownMenuItem(
                    value: 'updatedAt:asc',
                    child: Text('Updated \u{25B2}'),
                  ),
                  DropdownMenuItem(
                    value: null,
                    child: Text('Created \u{25BC}'),
                  ),
                  DropdownMenuItem(
                    value: 'createdAt:asc',
                    child: Text('Created \u{25B2}'),
                  ),
                  DropdownMenuItem(value: 'state', child: Text('State')),
                ],
                onChanged: (value) {
                  ref.read(sortProvider.notifier).state = value;
                  _refresh(ref, context, sortOverride: value);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _refresh(ref, context),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
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
  }
}
