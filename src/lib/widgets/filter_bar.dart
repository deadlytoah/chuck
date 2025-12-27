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
                  _refresh(ref, filterOverride: value);
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
                  _refresh(ref, sortOverride: value);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _refresh(ref),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }

  void _refresh(WidgetRef ref, {String? filterOverride, String? sortOverride}) {
    final filter = filterOverride ?? ref.read(filterProvider);
    final sort = sortOverride ?? ref.read(sortProvider);
    ref.read(itemsProvider.notifier).loadItems(filter: filter, sort: sort);
  }
}
