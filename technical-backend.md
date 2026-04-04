# Technical Specifications — Backend

Shared backend consumed by both the Flutter iOS app and the Next.js
web app. See `technical.md` for Flutter iOS specifics and
`technical-web.md` for Next.js specifics.

## Image Resize & S3 Strategy
- Image processing done client-side before upload
- Resize to fit within 400x300px (thumbnail) and 1200x900px (full),
  preserving the original aspect ratio.
- Upload flow: `POST /items/upload` returns presigned URLs only (no DB
  write); client uploads to S3; then `POST /items` creates DynamoDB
  record. Process multiple files sequentially for reliable uploads.
- Retry logic: auto-retry failed uploads twice (presigned URL fetch or
  S3 upload failures). After 2 failures, surface error to user with
  manual retry option.
- S3 key format: `images/{uuid}/full.jpg` and `images/{uuid}/thumb.jpg`
- Full-size image key stored in DynamoDB. Thumbnail key derived by
  convention (e.g., `s/full/thumb/`).
- DynamoDB stores S3 object keys only, not full URLs
- Image constraints: JPEG only, max 10MB
- Lifecycle: keep archived images 30 days from `archivedAt`, then
  auto-delete via S3 lifecycle policy.

## DynamoDB Schema

**Table: chuck-items-v2** (replaces chuck-items)

**Main Table:**
- Partition key: `PK` = `folder#{folderId}`
- Sort key: `SK` = `item#{archived}#{createdAt}` (items) or
  `metadata` (folder metadata)
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
- Items in folder (active): `PK = "folder#clothes" AND SK
  begins_with "item#false#"`
- Items in folder (archived): `PK = "folder#clothes" AND SK
  begins_with "item#true#"`
- All items in folder: `PK = "folder#clothes" AND SK begins_with
  "item#"`
- Folder metadata: `PK = "folder#clothes" AND SK = "metadata"`

**Initial Folder Setup:**
- On first launch: user manually creates folders
- Subsequent launches: restore last-selected folder from local
  storage, fallback to first alphabetically if not found

**Migration:**
- Old table (chuck-items) remains during transition
- Migration script moves data from chuck-items to chuck-items-v2
- All old items go into "entryway" folder
- Migration runs manually post-deployment

## API Specification
- Runtime: Go (golang)
- Deployment: single Lambda with Lambda Function URL (anonymous mode)
- Internal routing within Lambda handler
- Environment vars: `BUCKET_NAME`, `TABLE_NAME`, `REGION`
- CORS: allow all origins; headers: `Content-Type, Authorization,
  X-Requested-With`
- Authentication: none (URL-based access, kept private within family)
- Concurrency: last write wins (no conflict resolution)

## API Endpoints & Responses
- Response envelope: `{"data": {...}, "pagination": {...},
  "meta": {...}}`
- Error format: `{"error": "message", "code": "ERROR_CODE"}`

### GET /folders
- Returns list of all folders
- Response: `{"data": [{"folderId": "...", "name": "...",
  "createdAt": "..."}]}`

### POST /folders
- Request: `{"folderId": "clothes", "name": "Clothes"}`
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
- Filter behavior: `archived` shows archived items only; `all`
  excludes archived items
- All queries scoped to specified folder: `PK=folder#{folderId}`
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
- Batch archive
- Request: `{"itemIds": ["id1", "id2", ...]}`
- Max 25 items per request
- Response: `{"archived": [...], "failed": [...]}`
- Partial success allowed; failures indicated in response

## Infrastructure
- DynamoDB table: chuck-items-v2 (v1: chuck-items deprecated)
- S3 bucket: chuck.overcomingsh.in (hosts Next.js static export at
  root; images/ and lambda/ subdirectories preserved on deploy)
- DynamoDB: on-demand capacity; PITR disabled
- Lambda deploy: `cd lambda/ && make update`
- Next.js deploy: `./deploy-web.sh` (build + `next export` + S3 sync)
