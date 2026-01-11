# Technical Specifications

## Image Resize & S3 Strategy
- Image processing done in Flutter web browser before upload
- Resize to fit within 400x300px (thumbnail) and 1200x900px (full),
  preserving the original aspect ratio.
- Upload flow: `POST /items/upload` returns presigned URLs only (no DB
  write); Flutter uploads to S3; then `POST /items` creates DynamoDB
  record. For multiple files, process them sequentially to ensure reliable
  uploads.
- Retry logic: Auto-retry failed uploads twice (presigned URL fetch or
  S3 upload failures). After 2 failures, surface error to user with
  manual retry option.
- S3 key format for uploaded image: images/{uuid}/full.jpg and
images/{uuid}/thumb.jpg
- The full-size image key is stored in DynamoDB. The thumbnail key is not
  stored but is derived by convention (e.g., `s/full/thumb/`).
- DynamoDB stores S3 object keys only, not full URLs
- Image constraints: JPEG only, max 10MB
- Lifecycle: Keep archived images 30 days from their `archivedAt` date,
  then auto-delete via S3 lifecycle policy.

## DynamoDB Schema

**Table: chuck-items-v2** (replaces chuck-items)

**Main Table:**
- Partition key: `PK` = `FOLDER#{folderId}`
- Sort key: `SK` = `ITEM#{archived}#{createdAt}` (items) or `METADATA`
  (folder metadata)
- Entity types stored: folders and items (single-table design)
- Attributes for items:
  - `entityType`: "item"
  - `itemId`: UUID
  - `folderId`: string (e.g., "entryway", "living-room")
  - `imageUrl`: S3 object key for full-size image
  - `state`: Chuck/Keep/Sell/Undecided/Unanswered (default: Unanswered)
  - `notes`: string (for multi-line notes)
  - `archived`: boolean (true/false)
  - `archivedAt`: timestamp when archived
  - `createdAt`: timestamp (set on creation)
  - `updatedAt`: last modification time
- Attributes for folders:
  - `entityType`: "folder"
  - `folderId`: string (unique identifier)
  - `name`: display name
  - `createdAt`: timestamp

**Query Patterns:**
- Items in folder (active): `PK = "FOLDER#clothes" AND SK begins_with
  "ITEM#false#"` (clothes is example folderId)
- Items in folder (archived): `PK = "FOLDER#clothes" AND SK begins_with
  "ITEM#true#"`
- All items in folder: `PK = "FOLDER#clothes" AND SK begins_with "ITEM#"`
- Folder metadata: `PK = "FOLDER#clothes" AND SK = "METADATA"`

**Initial Folder Setup:**
- On first launch (no folders exist): auto-create "Clothes", "Blankets",
  "Books"
- Default selection: "Clothes"
- Subsequent launches: use last-selected folder from local storage,
  fallback to first alphabetically if not found

**Migration:**
- Old table (chuck-items) remains during transition
- Migration script moves data from chuck-items to chuck-items-v2
- All old items go into "entryway" folder
- Migration runs manually post-deployment

## API Specification
- Deployment: Single Lambda with Lambda Function URL (anonymous mode)
- Internal routing within Lambda handler
- Environment vars: `BUCKET_NAME`, `TABLE_NAME`, `REGION`
- CORS: Allow all origins; headers: `Content-Type, Authorization,
  X-Requested-With`

## API Endpoints & Responses
- Response envelope: `{"data": {...},
  "pagination": {...}, "meta": {...}}`
- Error format: `{"error": "message",
  "code": "ERROR_CODE"}`

### GET /folders
- Returns list of all folders
- Response: `{"data": [{"folderId": "...", "name": "...",
  "createdAt": "..."}]}`

### POST /folders
- Request: `{"folderId": "clothes", "name": "Clothes"}` (example)
- Creates new folder
- Response: created folder object

### PUT /folders/{folderId}
- Request: `{"name": "New Name"}`
- Renames folder
- Response: updated folder object

### DELETE /folders/{folderId}
- Deletes folder (must be empty)
- Response: `{}`

### GET /items
- Query params: `folderId` (required), `nextToken`, `limit` (default
  20, max 50), `sort` (createdAt/state), `filter` (Chuck/Keep/Sell/
  Undecided/Unanswered/archived/all)
- Filter behavior: `archived` shows archived items only; `all` excludes
  archived items
- All queries scoped to specified folder
- Uses token-based pagination (LastEvaluatedKey)
- Response: array of items + nextToken if more

### POST /items/upload
- Request: none (generates unique S3 keys)
- Returns presigned URLs for thumbnail and full-size image upload
- Response: `{"uploadUrls": {"thumb": "...", "full": "..."},
  "imageUrl": "items/.../full/img.jpg"}`
- No DynamoDB record created at this stage

### POST /items
- Request: `{"imageUrl": "items/.../full/img.jpg",
  "folderId": "entryway", "state": "Unanswered"}`
- Creates DynamoDB record with generated itemId in specified folder
- Response: created item with itemId
- If this call fails, dangling S3 images require manual cleanup

### PUT /items/{id}
- Request: `{"state": "Sell"}` or `{"notes": "..."}` or
  `{"archived": false}` (unarchive)
- Images cannot be updated/replaced after item creation
- Archived items read-only for state updates
- Unarchive via `{"archived": false}` to restore item
- Last write wins (no version checking)
- Response: updated item

### DELETE /items/{id}
- Archive single item
- Response: `{}`

### POST /items/archive
- Batch archive via checkbox selection mode (toggle button in UI)
- Request: `{"itemIds": ["id1", "id2", ...]}`
- Max 25 items per request
- Response: `{"archived": [...], "failed": [...]}`
- Partial success allowed; failures indicated in response

## Lambda + Flutter Integration
- Lambda runtime: Go (golang)
- Flutter state management: Riverpod with manual refresh for syncing.
  Camera uploads automatically update item list after backend confirms
  creation.
- UI controls: TabBar for view switching (Main View is default landing
  page, tab index 0); AppBar for filter, sort, and refresh.
- Authentication: none (URL-based access, kept private within family)
- Concurrency: Last write wins (no conflicts)

## In-App Camera (iOS only)

- Camera package: `camera` (official Flutter plugin)
- Camera configuration: back camera only
- No preview mode: photos captured directly without user review
- Continuous capture: user can take photos continuously without leaving
  camera screen
- Queue management: maximum 12 photos maintained in in-memory queue
  (queue lost on app restart)
- Queue full behavior: capture button disabled when queue reaches 12
  photos; re-enabled when queue has space
- Network detection: queue processes when OS-defined unmetered network
  available (uses `connectivity_plus` package to check network type)
- Image processing: apply existing photo scaling logic (400x300px
  thumbnail, 1200x900px full, 85% JPEG quality) from `ImageService`
- Upload concurrency: serial processing (one photo at a time) to
  simplify error handling and retry logic
- Queue processing: items sent to backend using existing `POST
  /items/upload` and `POST /items` flow
- Item display: After `POST /items` completes successfully, new item
  automatically added to Main View grid via state update (no manual refresh
  required)
- Visual confirmation: text message "Photo queued for upload" fades
  in/out after photo added to queue (400ms fade-in, 300ms display, 400ms
  fade-out)
- Text style: white text, 16px, centered, semi-transparent dark background
  for contrast
- Haptic feedback: `mediumImpact` when photo queued for clear, distinct
  confirmation
- Network monitoring: check on network status change and app foreground
  return (no polling)
- Camera exit: no confirmation dialog (back button always exits; queue
  processes automatically)
- Permission handling: request camera permission on first use; if
  denied, show alert dialog explaining camera access is needed to take
  photos of items, with "Go to Settings" and "Cancel" buttons
- UI: camera button (FAB) in bottom right corner; queue status button
  placed next to camera button showing total queued photo count

## Upload Retry & Failure Handling

**Retry Strategy:**
- Automatic retries for transient errors without user notification
- Retry parameters: 3 attempts per photo
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
- Actions: "Retry" button (resets retry count and immediately retries
  all queued photos)
- Guidance: error resolution steps

## Error Message Display

Error display patterns:
- **List loading failures**: Alert dialog with user-friendly message for
  critical errors that prevent app functionality
- **Camera permission denied**: Alert dialog with settings access option
- **Item operations (archive/unarchive/state changes)**: Alert dialog
  with user-friendly message. Technical error details logged to console
  for debugging.
- **Bulk archive results**: Success/failure summary inline in bulk
  actions panel with retry option
- **Success confirmations**: Brief toast-style banner (green, appears at
  top of screen, 2s auto-dismiss, slides down smoothly)
- **General principle**: User-friendly messages in UI, technical details
  in logs. No persistent banners or overlays. Users retry via normal UI
  elements (refresh button, etc.).

**Error message guidelines**:
- UI displays: "Unable to archive item", "Unable to load items", etc.
- Console logs: Full exception details with stack traces
- All operations that can fail should follow this pattern
- Error dialogs have single OK/Cancel button (no Retry)

Note: Upload failures use silent retry (see Upload Retry & Failure
Handling section)

## Infrastructure
- DynamoDB table name: chuck-items-v2 (v1: chuck-items deprecated)
- S3 bucket name: chuck.overcomingsh.in
- DynamoDB: on-demand
- PITR: disabled
