import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/folder.dart';

class FolderBottomSheet extends ConsumerWidget {
  const FolderBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersState = ref.watch(foldersProvider);

    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Folders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Container(
            height: 1,
            color: CupertinoColors.separator,
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: foldersState.folders.length,
              itemBuilder: (context, index) {
                final folder = foldersState.folders[index];
                final isSelected =
                    folder.folderId == foldersState.currentFolderId;
                return GestureDetector(
                  onTap: () async {
                    await _selectFolder(context, ref, folder.folderId);
                  },
                  onLongPress: () => _showFolderMenu(context, ref, folder),
                  child: Container(
                    color: isSelected
                        ? CupertinoColors.systemGrey5.resolveFrom(context)
                        : CupertinoColors.systemBackground.resolveFrom(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.folder,
                          color: isSelected
                              ? CupertinoColors.activeBlue.resolveFrom(context)
                              : CupertinoColors.systemGrey.resolveFrom(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            folder.name,
                            style: TextStyle(
                              fontSize: 17,
                              color: isSelected
                                  ? CupertinoColors.activeBlue.resolveFrom(context)
                                  : CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            CupertinoIcons.check_mark,
                            color: CupertinoColors.activeBlue.resolveFrom(context),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.add, size: 20),
                SizedBox(width: 8),
                Text('New Folder'),
              ],
            ),
            onPressed: () => _showCreateFolderDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFolder(
    BuildContext context,
    WidgetRef ref,
    String folderId,
  ) async {
    await ref.read(foldersProvider.notifier).selectFolder(folderId);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _showFolderMenu(BuildContext context, WidgetRef ref, Folder folder) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showRenameFolderDialog(context, ref, folder);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pencil),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteFolder(context, ref, folder);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.delete),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => _CreateFolderDialog(ref: ref),
    );
  }

  void _showRenameFolderDialog(
      BuildContext context, WidgetRef ref, Folder folder) {
    final nameController = TextEditingController(text: folder.name);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Rename Folder'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            maxLength: 50,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }

              Navigator.pop(context);

              try {
                await ref.read(foldersProvider.notifier).updateFolder(
                      folderId: folder.folderId,
                      name: name,
                    );
              } catch (e) {
                print('Error renaming folder: $e');
                if (context.mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Error'),
                      content: const Text('Unable to rename folder'),
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
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(
      BuildContext context, WidgetRef ref, Folder folder) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder.name}"?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ref
                    .read(foldersProvider.notifier)
                    .deleteFolder(folder.folderId);
              } catch (e) {
                print('Error deleting folder: $e');
                if (context.mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Error'),
                      content: const Text('Unable to delete folder'),
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
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CreateFolderDialog extends StatefulWidget {
  final WidgetRef ref;

  const _CreateFolderDialog({required this.ref});

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  final _nameController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Folder name is required';
      });
      return;
    }

    // Generate folderId from name
    final folderId = name.toLowerCase().replaceAll(' ', '-');

    try {
      await widget.ref.read(foldersProvider.notifier).createFolder(
            folderId: folderId,
            name: name,
          );

      // Only close dialog if operation succeeded and widget is still mounted
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error creating folder: $e');
      if (context.mounted) {
        // Close the create dialog first
        Navigator.pop(context);

        // Then show error dialog
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Unable to create folder'),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Create Folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Folder Name',
            maxLength: 50,
            onChanged: (value) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 13,
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
          onPressed: _handleCreate,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
