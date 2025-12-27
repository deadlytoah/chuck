import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../providers/app_providers.dart';

@Preview()
Widget itemCardPreview() {
  final sampleItem = Item(
    itemId: 'preview-123',
    imageUrl: 'https://via.placeholder.com/300x400/thumb.jpg',
    state: 'Keep',
    notes: 'This is a sample item for preview',
    archived: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 300, child: ItemCard(item: sampleItem)),
        ),
      ),
    ),
  );
}

class ItemCard extends ConsumerStatefulWidget {
  final Item item;
  final bool showCheckbox;
  final bool isSelected;

  const ItemCard({
    required this.item,
    this.showCheckbox = false,
    this.isSelected = false,
    super.key,
  });

  @override
  ConsumerState<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends ConsumerState<ItemCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.showCheckbox
            ? () => ref
                .read(selectionProvider.notifier)
                .toggleItem(widget.item.itemId)
            : () => _showEditDialog(context, ref),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    widget.item.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StateChip(state: widget.item.state),
                          if (!widget.showCheckbox)
                            IconButton(
                              icon: Icon(
                                widget.item.archived
                                    ? Icons.unarchive
                                    : Icons.archive,
                              ),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                if (widget.item.archived) {
                                  _unarchiveItem(ref, context);
                                } else {
                                  _archiveItem(ref, context);
                                }
                              },
                            ),
                        ],
                      ),
                      if (widget.item.notes != null &&
                          widget.item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.notes!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (widget.showCheckbox)
              Positioned(
                top: 8,
                right: 8,
                child: Checkbox(
                  value: widget.isSelected,
                  onChanged: (_) => ref
                      .read(selectionProvider.notifier)
                      .toggleItem(widget.item.itemId),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _archiveItem(WidgetRef ref, BuildContext context) async {
    await ref.read(itemsProvider.notifier).archiveItem(widget.item.itemId);
  }

  Future<void> _unarchiveItem(WidgetRef ref, BuildContext context) async {
    await ref.read(itemsProvider.notifier).unarchiveItem(widget.item.itemId);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(item: widget.item),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String state;

  const _StateChip({required this.state});

  Color get _color {
    switch (state) {
      case 'Chuck':
        return Colors.red;
      case 'Keep':
        return Colors.green;
      case 'Sell':
        return Colors.blue;
      case 'Undecided':
        return Colors.orange;
      case 'Unanswered':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        state,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: _color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _EditItemDialog extends ConsumerStatefulWidget {
  final Item item;

  const _EditItemDialog({required this.item});

  @override
  ConsumerState<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends ConsumerState<_EditItemDialog> {
  late String selectedState;
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    selectedState = widget.item.state;
    commentController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = widget.item.archived;

    return AlertDialog(
      title: const Text('Edit Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(widget.item.imageUrl, fit: BoxFit.contain),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedState,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Unanswered',
                  child: Text('Unanswered'),
                ),
                DropdownMenuItem(value: 'Chuck', child: Text('Chuck')),
                DropdownMenuItem(value: 'Keep', child: Text('Keep')),
                DropdownMenuItem(value: 'Sell', child: Text('Sell')),
                DropdownMenuItem(value: 'Undecided', child: Text('Undecided')),
              ],
              onChanged: isArchived
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => selectedState = value);
                      }
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (isArchived) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _unarchive(),
                icon: const Icon(Icons.unarchive),
                label: const Text('Unarchive'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: () => _save(), child: const Text('Save')),
      ],
    );
  }

  void _save() async {
    await ref
        .read(itemsProvider.notifier)
        .updateItem(
          widget.item.itemId,
          state: selectedState != widget.item.state ? selectedState : null,
          notes: commentController.text != widget.item.notes
              ? commentController.text
              : null,
        );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _unarchive() async {
    await ref.read(itemsProvider.notifier).unarchiveItem(widget.item.itemId);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
