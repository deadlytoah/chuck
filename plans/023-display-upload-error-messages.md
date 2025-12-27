# Plan 023: Display Upload Error Messages

## Prompt
"Yes can you generate a plan for doing this." (Context: Show accurate
error messages instead of generic "Upload failed. Retry when connected
to WiFi." message when camera uploads fail due to errors like 404 S3
bucket missing)

## Plan

1. **Update `QueuedPhoto` model** (`src/lib/models/queued_photo.dart`)
   - Add optional `String? errorMessage` field
   - Update `copyWith()` to include errorMessage parameter

2. **Modify `CameraQueueService`** (`src/lib/services/camera_queue_
   service.dart`)
   - Update `markFailed()` to accept optional error message parameter
   - In `_handlePhotoStream()` catch block, pass `e.toString()` to
     `markFailed()`

3. **Update `FailedUploadBanner`** (`src/lib/widgets/failed_upload_
   banner.dart`)
   - Display specific error message from first failed photo instead of
     generic WiFi message
   - Fallback to generic message if no error message available
   - Consider showing count if multiple failures with different errors

## Files Referenced

- `src/lib/models/queued_photo.dart:1-31` - Model definition
- `src/lib/services/camera_queue_service.dart:56-66,103-107` - Error
  handling logic
- `src/lib/widgets/failed_upload_banner.dart:29-31` - Banner message
  display
