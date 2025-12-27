import 'dart:io';
import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Queue'),
      ),
      body: queue.isEmpty
          ? const Center(
              child: Text('No photos in queue'),
            )
          : Column(
              children: [
                if (failedPhotos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  '${failedPhotos.length} failed upload${failedPhotos.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check your WiFi connection and retry.',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                for (final photo in failedPhotos) {
                                  queueService.retryFailed(photo.id);
                                }
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry All'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
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
                              Icons.cloud_upload,
                              Colors.blue,
                              queueService,
                            )),
                        const SizedBox(height: 16),
                      ],
                      if (pendingPhotos.isNotEmpty) ...[
                        _buildSectionHeader('Pending', pendingPhotos.length),
                        ...pendingPhotos.map((photo) => _buildPhotoItem(
                              photo,
                              Icons.schedule,
                              Colors.grey,
                              queueService,
                            )),
                        const SizedBox(height: 16),
                      ],
                      if (failedPhotos.isNotEmpty) ...[
                        _buildSectionHeader('Failed', failedPhotos.length),
                        ...failedPhotos.map((photo) => _buildPhotoItem(
                              photo,
                              Icons.error,
                              Colors.red,
                              queueService,
                              showRetry: true,
                            )),
                      ],
                    ],
                  ),
                ),
              ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: File(photo.path).existsSync()
              ? Image.file(
                  File(photo.path),
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image),
                ),
        ),
        title: Text(
          photo.path.split('/').last,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatTimestamp(photo.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: showRetry
            ? IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => queueService.retryFailed(photo.id),
                tooltip: 'Retry',
              )
            : Icon(icon, color: color),
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
