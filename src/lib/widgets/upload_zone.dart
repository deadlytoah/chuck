import 'package:flutter/cupertino.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import '../models/upload_progress.dart';
import '../providers/app_providers.dart';
import '../services/upload_service.dart';

@Preview()
Widget uploadZonePreview() {
  return const ProviderScope(
    child: CupertinoApp(
      home: CupertinoPageScaffold(
        child: Padding(padding: EdgeInsets.all(16.0), child: UploadZone()),
      ),
    ),
  );
}

class UploadZone extends ConsumerStatefulWidget {
  const UploadZone({super.key});

  @override
  ConsumerState<UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends ConsumerState<UploadZone> {
  late DropzoneViewController? dropzoneController;
  bool isDragging = false;

  @override
  void initState() {
    super.initState();
    dropzoneController = null;
  }

  Future<void> _handleFiles(List<PlatformFile> files) async {
    final filesToUpload = <FileToUpload>[];

    for (final file in files) {
      if (file.bytes != null) {
        filesToUpload.add(FileToUpload(name: file.name, bytes: file.bytes!));
      }
    }

    if (filesToUpload.isEmpty) return;

    final uploadService = ref.read(uploadServiceProvider);

    await for (final progressMap in uploadService.uploadFiles(filesToUpload)) {
      ref.read(uploadProgressProvider.notifier).state = progressMap;
    }

    // Refresh items after upload
    final filter = ref.read(filterProvider);
    final sort = ref.read(sortProvider);
    ref.read(itemsProvider.notifier).loadItems(filter: filter, sort: sort);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null) {
      await _handleFiles(result.files);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadProgress = ref.watch(uploadProgressProvider);
    final hasUploads = uploadProgress.isNotEmpty;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMobile)
          // Mobile: Just show the button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CupertinoButton(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(8),
                onPressed: _pickFiles,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.folder, color: CupertinoColors.white),
                    SizedBox(width: 8),
                    Text('Choose Images'),
                  ],
                ),
              ),
            ),
          )
        else
          // Desktop: Show full drag & drop zone
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDragging ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isDragging ? CupertinoColors.activeBlue.withOpacity(0.1) : null,
            ),
            child: Stack(
              children: [
                DropzoneView(
                  onCreated: (controller) => dropzoneController = controller,
                  onDropFile: (dynamic ev) async {
                    setState(() => isDragging = false);

                    final name = await dropzoneController!.getFilename(ev);
                    final bytes = await dropzoneController!.getFileData(ev);

                    await _handleFiles([
                      PlatformFile(
                        name: name,
                        size: bytes.length,
                        bytes: bytes,
                      ),
                    ]);
                  },
                  onHover: () => setState(() => isDragging = true),
                  onLeave: () => setState(() => isDragging = false),
                ),
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.cloud_upload,
                          size: 64,
                          color: isDragging ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Drag & drop images here',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDragging ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) => Text(
                            'or',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CupertinoButton(
                          color: CupertinoColors.activeBlue,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: _pickFiles,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.folder, color: CupertinoColors.white),
                              SizedBox(width: 8),
                              Text('Choose Images'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (hasUploads) ...[
          const SizedBox(height: 16),
          _UploadProgressList(uploadProgress: uploadProgress),
        ],
      ],
    );
  }
}

class _UploadProgressList extends ConsumerWidget {
  final Map<String, UploadProgress> uploadProgress;

  const _UploadProgressList({required this.uploadProgress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = uploadProgress.values.toList();
    final completed = items
        .where((i) => i.status == UploadStatus.success)
        .length;
    final failed = items.where((i) => i.status == UploadStatus.failed).length;
    final inProgress = items.length - completed - failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 1,
              ),
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$completed/${items.length} completed',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CupertinoProgressBar(
                value: items.isEmpty ? 0 : completed / items.length,
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) => Text(
                  'In progress: $inProgress | Failed: $failed',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final progress = items[index];
              return _UploadThumbnail(progress: progress);
            },
          ),
        ),
      ],
    );
  }
}

class _CupertinoProgressBar extends StatelessWidget {
  final double value;

  const _CupertinoProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _UploadThumbnail extends StatelessWidget {
  final UploadProgress progress;

  const _UploadThumbnail({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: progress.thumbnailDataUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        progress.thumbnailDataUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(child: _buildStatusIcon()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.fileName,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildStatusWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (progress.status) {
      case UploadStatus.pending:
        return const Icon(CupertinoIcons.time, color: CupertinoColors.systemGrey);
      case UploadStatus.uploading:
      case UploadStatus.processing:
        return const CupertinoActivityIndicator();
      case UploadStatus.success:
        return const Icon(CupertinoIcons.check_mark_circled, color: CupertinoColors.activeGreen);
      case UploadStatus.failed:
        return const Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.destructiveRed);
    }
  }

  Widget _buildStatusWidget() {
    switch (progress.status) {
      case UploadStatus.pending:
        return const Text('Pending...', style: TextStyle(fontSize: 10));
      case UploadStatus.uploading:
        return _CupertinoProgressBar(value: progress.progress);
      case UploadStatus.processing:
        return const Text('Processing...', style: TextStyle(fontSize: 10));
      case UploadStatus.success:
        return const Text(
          'Success',
          style: TextStyle(fontSize: 10, color: CupertinoColors.activeGreen),
        );
      case UploadStatus.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Failed',
              style: TextStyle(fontSize: 10, color: CupertinoColors.destructiveRed),
            ),
            if (progress.needsManualRetry)
              const Text(
                'Manual retry needed',
                style: TextStyle(fontSize: 8, color: CupertinoColors.destructiveRed),
              ),
          ],
        );
    }
  }
}
