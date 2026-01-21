import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'folder_bottom_sheet.dart';

class FolderSelector extends ConsumerWidget {
  const FolderSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersState = ref.watch(foldersProvider);
    final currentFolder = foldersState.currentFolder;

    return GestureDetector(
      onTap: () => _showFolderBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.folder, size: 20),
            const SizedBox(width: 8),
            Text(currentFolder?.name ?? 'No Folder'),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_down, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFolderBottomSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const FolderBottomSheet(),
    );
  }
}
