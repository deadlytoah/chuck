import 'package:flutter/cupertino.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../providers/app_providers.dart';
import '../screens/edit_item_screen.dart';

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
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: widget.showCheckbox
            ? () => ref
                .read(selectionProvider.notifier)
                .toggleItem(widget.item.itemId)
            : () => _navigateToEditScreen(context),
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
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                          : CupertinoColors.secondarySystemBackground.resolveFrom(context),
                      border: Border.all(
                        color: widget.isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey3.resolveFrom(context),
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

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => EditItemScreen(item: widget.item),
      ),
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
