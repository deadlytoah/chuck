import 'package:flutter/cupertino.dart';
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
    child: CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
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
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
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
                        color: CupertinoColors.systemGrey5,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: CupertinoColors.systemGrey,
                        ),
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
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 20,
                              onPressed: () {
                                if (widget.item.archived) {
                                  _unarchiveItem(ref, context);
                                } else {
                                  _archiveItem(ref, context);
                                }
                              },
                              child: Icon(
                                widget.item.archived
                                    ? CupertinoIcons.tray_arrow_up
                                    : CupertinoIcons.archivebox,
                                size: 20,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                        ],
                      ),
                      if (widget.item.notes != null &&
                          widget.item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.notes!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel,
                          ),
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
                child: GestureDetector(
                  onTap: () => ref
                      .read(selectionProvider.notifier)
                      .toggleItem(widget.item.itemId),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.secondarySystemBackground,
                      border: Border.all(
                        color: widget.isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey3,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: widget.isSelected
                        ? const Icon(
                            CupertinoIcons.check_mark,
                            size: 16,
                            color: CupertinoColors.white,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _archiveItem(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(itemsProvider.notifier).archiveItem(widget.item.itemId);
    } catch (e) {
      print('Archive item error: $e');
      if (context.mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Unable to archive item'),
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

  Future<void> _unarchiveItem(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(itemsProvider.notifier).unarchiveItem(widget.item.itemId);
    } catch (e) {
      print('Unarchive item error: $e');
      if (context.mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Unable to unarchive item'),
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

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
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
        return CupertinoColors.systemRed;
      case 'Keep':
        return CupertinoColors.systemGreen;
      case 'Sell':
        return CupertinoColors.systemBlue;
      case 'Undecided':
        return CupertinoColors.systemOrange;
      case 'Unanswered':
      default:
        return CupertinoColors.systemGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        state,
        style: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
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
    final states = ['Unanswered', 'Chuck', 'Keep', 'Sell', 'Undecided'];
    final stateIndex = states.indexOf(selectedState);

    return CupertinoAlertDialog(
      title: const Text('Edit Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(widget.item.imageUrl, fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          if (!isArchived) ...[
            const Text(
              'State',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showStatePicker(context, states, stateIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedState,
                      style: const TextStyle(color: CupertinoColors.label),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: commentController,
            placeholder: 'Add notes...',
            maxLines: 3,
            padding: const EdgeInsets.all(12),
          ),
          if (isArchived) ...[
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () => _unarchive(),
              color: CupertinoColors.activeBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.tray_arrow_up, size: 20),
                  SizedBox(width: 8),
                  Text('Unarchive'),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => _save(),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showStatePicker(BuildContext context, List<String> states, int initialIndex) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32,
            scrollController: FixedExtentScrollController(
              initialItem: initialIndex >= 0 ? initialIndex : 0,
            ),
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                selectedState = states[selectedItem];
              });
            },
            children: List<Widget>.generate(states.length, (int index) {
              return Center(child: Text(states[index]));
            }),
          ),
        ),
      ),
    );
  }

  void _save() async {
    try {
      await ref.read(itemsProvider.notifier).updateItem(
            widget.item.itemId,
            state: selectedState != widget.item.state ? selectedState : null,
            notes: commentController.text != widget.item.notes
                ? commentController.text
                : null,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Update item error: $e');
      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Unable to update item'),
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

  void _unarchive() async {
    try {
      await ref.read(itemsProvider.notifier).unarchiveItem(widget.item.itemId);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Unarchive item error: $e');
      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Unable to unarchive item'),
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
