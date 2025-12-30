import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queued_photo.dart';
import '../providers/providers.dart';

class FailedUploadBanner extends ConsumerStatefulWidget {
  const FailedUploadBanner({super.key});

  @override
  ConsumerState<FailedUploadBanner> createState() =>
      _FailedUploadBannerState();
}

class _FailedUploadBannerState extends ConsumerState<FailedUploadBanner> {
  bool _hasShownNotification = false;
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(cameraQueueServiceProvider);
    final failedPhotos =
        queue.where((photo) => photo.state == PhotoState.failed).toList();

    if (failedPhotos.isNotEmpty && !_hasShownNotification) {
      _hasShownNotification = true;
      _isVisible = true;

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isVisible = false);
        }
      });
    }

    if (failedPhotos.isEmpty) {
      _hasShownNotification = false;
      _isVisible = false;
    }

    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      color: CupertinoColors.systemGreen,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                color: CupertinoColors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Some photos failed to upload. Tap the queue button to review.',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
