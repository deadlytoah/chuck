import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queued_photo.dart';
import '../providers/app_providers.dart';
import '../providers/providers.dart';

class QueueReviewScreen extends ConsumerWidget {
  const QueueReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(cameraQueueServiceProvider);
    final queueService = ref.read(cameraQueueServiceProvider.notifier);

    final pendingPhotos = queue.where((p) => p.state == PhotoState.pending).toList();
    final failedPhotos = queue.where((p) => p.state == PhotoState.failed).toList();
    final uploadingPhotos = queue.where((p) => p.state == PhotoState.uploading).toList();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Upload Queue'),
      ),
      child: SafeArea(
        child: queue.isEmpty
            ? const Center(
                child: Text('No photos in queue'),
              )
            : Column(
                children: [
                if (failedPhotos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CupertinoColors.systemOrange.withOpacity(0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: CupertinoColors.systemOrange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${failedPhotos.length} failed upload${failedPhotos.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.systemOrange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check your WiFi connection and retry.',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CupertinoButton(
                              onPressed: () {
                                for (final photo in failedPhotos) {
                                  queueService.retryFailed(photo.id);
                                }
                              },
                              color: CupertinoColors.systemOrange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.refresh, size: 18),
                                  SizedBox(width: 8),
                                  Text('Retry All'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      if (uploadingPhotos.isNotEmpty) ...[
                        _buildSectionHeader('Uploading', uploadingPhotos.length),
                        ...uploadingPhotos.map((photo) => _buildPhotoItem(
                              photo,
                              CupertinoIcons.cloud_upload,
                              CupertinoColors.activeBlue,
                              queueService,
                            )),
                        const SizedBox(height: 16),
                      ],
                      if (pendingPhotos.isNotEmpty) ...[
                        _buildSectionHeader('Pending', pendingPhotos.length),
                        ...pendingPhotos.map((photo) => _buildPhotoItem(
                              photo,
                              CupertinoIcons.clock,
                              CupertinoColors.systemGrey,
                              queueService,
                            )),
                        const SizedBox(height: 16),
                      ],
                      if (failedPhotos.isNotEmpty) ...[
                        _buildSectionHeader('Failed', failedPhotos.length),
                        ...failedPhotos.map((photo) => _buildPhotoItem(
                              photo,
                              CupertinoIcons.exclamationmark_circle,
                              CupertinoColors.systemRed,
                              queueService,
                              showRetry: true,
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPhotoItem(
    QueuedPhoto photo,
    IconData icon,
    Color color,
    dynamic queueService, {
    bool showRetry = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 50,
                child: File(photo.path).existsSync()
                    ? Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: CupertinoColors.systemGrey5,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.path.split('/').last,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(photo.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            showRetry
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => queueService.retryFailed(photo.id),
                    child: const Icon(
                      CupertinoIcons.refresh,
                      color: CupertinoColors.activeBlue,
                    ),
                  )
                : Icon(icon, color: color),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
