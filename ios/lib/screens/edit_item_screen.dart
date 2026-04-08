import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../providers/app_providers.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final Item item;

  const EditItemScreen({required this.item, super.key});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  late String selectedState;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    selectedState = widget.item.state;
    notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = widget.item.archived;
    final states = ['Unanswered', 'Chuck', 'Keep', 'Sell', 'Undecided'];
    final stateIndex = states.indexOf(selectedState);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Edit Item'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.item.fullImageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: CupertinoColors.systemGrey5,
                      child: const Icon(
                        CupertinoIcons.photo,
                        size: 80,
                        color: CupertinoColors.systemGrey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              if (!isArchived) ...[
                Text(
                  'State',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showStatePicker(context, states, stateIndex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedState,
                          style: TextStyle(
                            fontSize: 17,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 20,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: notesController,
                placeholder: 'Add notes...',
                maxLines: 8,
                minLines: 5,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              if (isArchived) ...[
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: _unarchive,
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
        ),
      ),
    );
  }

  void _showStatePicker(
      BuildContext context, List<String> states, int initialIndex) {
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
            notes: notesController.text != widget.item.notes
                ? notesController.text
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
