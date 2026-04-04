# Technical Specifications — Flutter iOS App

Flutter iOS app frontend. See `technical-backend.md` for the shared
backend (API, DynamoDB, S3, infrastructure) and `technical-web.md`
for the Next.js web app.

## Flutter Integration
- State management: Riverpod with manual refresh for syncing. Camera
  uploads automatically update item list after backend confirms
  creation.
- UI controls: TabBar for view switching (Main View is default landing
  page, tab index 0); AppBar for filter, sort, and refresh.

## Image Upload (iOS)
- Image processing done in Flutter before upload
- Resize to 400x300px (thumbnail) and 1200x900px (full), 85% JPEG
  quality, preserving aspect ratio
- Upload flow: `POST /items/upload` → upload to S3 → `POST /items`
- Multiple files processed sequentially

## In-App Camera

- Camera package: `camera` (official Flutter plugin)
- Camera configuration: back camera only
- No preview mode: photos captured directly without user review
- Continuous capture: user can take photos continuously without
  leaving camera screen
- Queue management: maximum 12 photos in in-memory queue (lost on
  app restart)
- Queue full behavior: capture button disabled at 12; re-enabled when
  space available
- Network detection: queue processes when OS-defined unmetered network
  available (`connectivity_plus` package)
- Image processing: 400x300px thumbnail, 1200x900px full, 85% JPEG
  quality via `ImageService`
- Upload concurrency: serial (one photo at a time)
- Queue processing: `POST /items/upload` then `POST /items` flow
- Item display: new item added to Main View grid automatically after
  `POST /items` completes (no manual refresh)
- Visual confirmation: "Photo queued for upload" fades in/out after
  capture (400ms fade-in, 300ms display, 400ms fade-out); white text
  16px centered on semi-transparent dark background
- Haptic feedback: `mediumImpact` on queue
- Network monitoring: on network status change and app foreground
  return (no polling)
- Camera exit: back button only; no confirmation dialog
- Permission handling: request on first use; if denied, show alert
  with "Go to Settings" and "Cancel" buttons
- UI: camera FAB bottom right; queue status button beside it showing
  total queued count

## Upload Retry & Failure Handling

**Retry Strategy:**
- Automatic retries without user notification
- 3 attempts per photo
- Exponential backoff: 1, 2, 4 minutes
- Retry triggers: presigned URL fetch, S3 upload, network errors

**Status & Notification:**
- Queue status button shows total queued items (pending + failed)
- Consolidated notification: "Some photos have failed to upload. Tap
  the queue button next to the camera to review."
- Single message for all failed items (not per-photo alerts)

**Manual Review Screen:**
- Access via queue status button
- Display: pending/retrying/failed items with status and retry count
- Actions: "Retry" button (resets count, immediately retries all)
- Guidance: error resolution steps

## Error Message Display

- **List loading failures**: alert dialog with user-friendly message
- **Camera permission denied**: alert dialog with settings access
- **Item operations (archive/unarchive/state changes)**: alert dialog;
  technical details logged to console
- **Bulk archive results**: success/failure summary inline in bulk
  actions panel with retry option
- **Success confirmations**: toast-style banner (green, top of screen,
  2s auto-dismiss, slides down smoothly)
- **General principle**: user-friendly messages in UI, technical
  details in logs. No persistent banners or overlays.

**Error message guidelines:**
- UI: "Unable to archive item", "Unable to load items", etc.
- Console: full exception details with stack traces
- Error dialogs: single OK/Cancel button (no Retry)

Note: upload failures use silent retry (see Upload Retry & Failure
Handling section)
