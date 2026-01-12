# Plan 031: DynamoDB Folder Structure

## Original Prompt
"If I were to add the concept of folder, so that you group the items
in different folders, how would this work with dynamodb?"

(Extended through discussion about UI, initial folder setup, and
migration strategy)

## Overview
Add folder organization to chuck app. Users can organize items into
folders (e.g., "Clothes", "Blankets", "Books"). This requires new
DynamoDB schema, folder management API, and UI for folder selection.

## Current Schema (chuck-items table)

**Table: chuck-items**
- Partition key: `archived` (boolean: "true" or "false" as string)
- Sort key: `createdAt` (timestamp ISO string, descending)
- No GSI

**Item Attributes:**
- `itemId`: UUID string
- `imageUrl`: S3 object key (e.g., "images/{uuid}/full.jpg")
- `state`: Chuck|Keep|Sell|Undecided|Unanswered
- `notes`: string
- `archived`: boolean (stored as string "true" or "false")
- `archivedAt`: timestamp (ISO string)
- `createdAt`: timestamp (ISO string)
- `updatedAt`: timestamp (ISO string)

**Current Query Patterns:**
- Get active items: Query with PK=false, SK descending
- Get archived items: Query with PK=true, SK descending
- Filter by state: Query + client-side filter
- Sort: by createdAt (natural from SK) or client-side

**Limitations:**
- No folder organization
- All items in one flat collection
- Archived filter works globally across all items

## New Schema (chuck-items-v2 table)

**Table: chuck-items-v2**
- Partition key: `PK` (string) = `folder#{folderId}`
- Sort key: `SK` (string) = `item#{archived}#{createdAt}` (items) or
  `metadata` (folders)
- No GSI
- Single-table design: both folders and items

**Item Attributes:**
- `entityType`: "item"
- `itemId`: UUID string
- `folderId`: string (e.g., "clothes", "blankets")
- `imageUrl`: S3 object key
- `state`: Chuck|Keep|Sell|Undecided|Unanswered
- `notes`: string
- `archived`: boolean (true/false)
- `archivedAt`: timestamp (ISO string)
- `createdAt`: timestamp (ISO string)
- `updatedAt`: timestamp (ISO string)

**Folder Attributes:**
- `entityType`: "folder"
- `folderId`: string (unique identifier)
- `name`: display name (e.g., "Clothes")
- `createdAt`: timestamp (ISO string)

**New Query Patterns:**
- Get active items in folder: Query PK=folder#clothes, SK
  begins_with item#false#
- Get archived items in folder: Query PK=folder#clothes, SK
  begins_with item#true#
- Get all items in folder: Query PK=folder#clothes, SK begins_with
  item#
- Get folder metadata: Query PK=folder#clothes, SK=metadata
- List all folders: Scan with filter entityType=folder

**Key Changes:**
- Archived filter now scoped to current folder (not global)
- Items organized by folder first, then by archived status
- Folder metadata stored as separate entity in same table
- PK/SK use composite patterns for efficient queries

## Design Summary

**Schema:**
- Single-table design: folders and items in chuck-items-v2
- PK: `folder#{folderId}`, SK: `item#{archived}#{createdAt}` or
  `metadata`
- No GSI (archived filter scoped to current folder)

**Folder Initialization:**
- First launch (no folders exist): auto-create "Clothes", "Blankets",
  "Books"
- Default selection: "Clothes"
- Subsequent launches: restore last-selected folder from local storage
- Fallback: first folder alphabetically

**Migration:**
- Script moves chuck-items data to "entryway" folder
- Old table (chuck-items) remains for backup
- Manual execution post-deployment

**UI:**
- Folder selector: top center of home screen (above filter bar)
- Display: icon + current folder name + dropdown indicator
- Interaction: click to show bottom sheet with folder list
- Bottom sheet: scrollable folder list, "+ New Folder" button
- Folder management: long-press for rename/delete, also in hamburger
  menu
- Layout: FolderSelector → FilterBar → ItemsGrid

**API Changes:**
- New endpoints: GET/POST/PUT/DELETE /folders
- GET /items: now requires folderId query parameter
- POST /items: now requires folderId in request body
- All item queries scoped to specified folder

## API Endpoint Specifications

### New Folder Endpoints

**GET /folders**
- Response: `{"data": [{"folderId": "clothes", "name": "Clothes",
  "createdAt": "..."}]}`
- Returns all folders (scan with entityType=folder filter)

**POST /folders**
- Request: `{"folderId": "clothes", "name": "Clothes"}`
- Response: created folder object
- Creates folder metadata entity

**PUT /folders/{folderId}**
- Request: `{"name": "New Name"}`
- Response: updated folder object
- Updates folder name

**DELETE /folders/{folderId}**
- Response: `{}`
- Deletes folder (must be empty, verify no items exist)

### Modified Item Endpoints

**GET /items**
- OLD: `?filter=all&sort=createdAt&limit=20&nextToken=...`
- NEW: `?folderId=clothes&filter=all&sort=createdAt&limit=20&
  nextToken=...`
- Added required folderId parameter
- Query now scoped to folder: PK=folder#{folderId}

**POST /items**
- OLD: `{"imageUrl": "...", "state": "Unanswered"}`
- NEW: `{"imageUrl": "...", "folderId": "clothes", "state":
  "Unanswered"}`
- Added required folderId field
- Creates item in specified folder

**POST /items/upload** (no changes)
- Still returns presigned URLs only

**PUT /items/{id}** (no changes)
- State/notes/archive updates work same way
- Note: archiving changes SK (archived flag toggles)

**DELETE /items/{id}** (no changes)
- Still archives single item

**POST /items/archive** (no changes)
- Batch archive still works
- Note: archiving changes SK for each item

## Implementation Steps

### 1. CloudFormation (cloudformation.yaml)
- Add chuck-items-v2 DynamoDB table resource
  - PK: PK (String)
  - SK: SK (String)
  - BillingMode: PAY_PER_REQUEST
  - No GSI
- Keep chuck-items table (for migration, remove in future PR)
- Update Lambda environment variable TABLE_NAME to chuck-items-v2
- No changes to S3 or Lambda function config

### 2. Lambda Backend (lambda/)

**types.go:**
- Add Folder struct (FolderId, Name, EntityType, CreatedAt)
- Update Item struct: add FolderId field, EntityType field
- Update DynamoDB attribute mapping for PK/SK pattern

**dynamodb.go:**
- Remove old query methods (QueryItemsByArchived, etc.)
- Add GetFolders() - scan for entityType=folder
- Add CreateFolder(folderId, name) - write METADATA entity
- Add UpdateFolder(folderId, name) - update METADATA entity
- Add DeleteFolder(folderId) - delete METADATA (check empty first)
- Add GetItemsInFolder(folderId, archived, filter, sort, limit,
  nextToken) - query with PK/SK pattern
- Add CreateItem(folderId, imageUrl, state) - write with composite SK
- Update ArchiveItem, UnarchiveItem - rebuild SK when toggling
  archived

**main.go:**
- Add GET /folders handler
- Add POST /folders handler
- Add PUT /folders/{folderId} handler
- Add DELETE /folders/{folderId} handler
- Update GET /items - require folderId query param
- Update POST /items - require folderId in request body
- Update archive/unarchive handlers

**dynamodb_test.go:**
- Update test fixtures for new schema
- Add folder CRUD operation tests
- Test SK pattern queries (archived=true/false)

### 3. Flutter Frontend (src/)

**models/folder.dart (new):**
- Folder model: folderId, name, createdAt
- JSON serialization

**services/api_service.dart:**
- Add getFolders() → List<Folder>
- Add createFolder(folderId, name) → Folder
- Add updateFolder(folderId, name) → Folder
- Add deleteFolder(folderId)
- Update getItems() - add required folderId param
- Update createItem() - add required folderId param

**providers/folder_provider.dart (new):**
- FolderNotifier: manages folder list, current selection
- Load folders from API
- Save/load last selected folder (local storage)
- Initial setup: create default folders if none exist
- Select "Clothes" by default

**widgets/folder_selector.dart (new):**
- Top bar widget: icon + folder name + dropdown icon
- onTap: show folder bottom sheet
- Display current folder name

**widgets/folder_bottom_sheet.dart (new):**
- List of folders (scrollable)
- "+ New Folder" button
- Long-press: show rename/delete menu
- Tap folder: switch to that folder, close sheet

**screens/home_page.dart:**
- Add FolderSelector at top (above FilterBar)
- Watch FolderNotifier for current folder
- Pass current folderId to ItemsGrid
- Auto-create default folders on first launch if needed

**screens/main_view.dart:**
- Update layout: FolderSelector, FilterBar, ItemsGrid
- Ensure proper spacing

**widgets/hamburger_menu.dart:**
- Add "Manage Folders" option
- Opens folder management dialog (create/rename/delete)

**lib/main.dart:**
- Register folder providers

### 4. Migration Script (lambda/migrate.go - new file)

**Purpose:** Migrate all existing items from chuck-items to
chuck-items-v2, placing them in "entryway" folder.

**Steps:**
1. Create "entryway" folder in chuck-items-v2:
   - PK: `folder#entryway`
   - SK: `metadata`
   - entityType: "folder"
   - name: "Entryway"
   - folderId: "entryway"
   - createdAt: current timestamp

2. Scan chuck-items table (all items)

3. For each item, transform and write to chuck-items-v2:
   - PK: `folder#entryway`
   - SK: `item#{archived}#{createdAt}` (e.g., "item#false#2024-01-
     15T10:30:00Z")
   - Copy all attributes: itemId, imageUrl, state, notes, archived,
     archivedAt, createdAt, updatedAt
   - Add: entityType="item", folderId="entryway"

**Example Transformation:**

Old item (chuck-items):
```
PK: "false"
SK: "2024-01-15T10:30:00Z"
itemId: "abc-123"
imageUrl: "images/abc-123/full.jpg"
state: "Unanswered"
archived: "false"
createdAt: "2024-01-15T10:30:00Z"
```

New item (chuck-items-v2):
```
PK: "folder#entryway"
SK: "item#false#2024-01-15T10:30:00Z"
entityType: "item"
folderId: "entryway"
itemId: "abc-123"
imageUrl: "images/abc-123/full.jpg"
state: "Unanswered"
archived: false (boolean, not string)
createdAt: "2024-01-15T10:30:00Z"
```

**Execution:** Run manually: `cd lambda && go run migrate.go`

**Note:** Ensure chuck-items-v2 table exists before running.

### 5. Testing
- Unit tests: Lambda DynamoDB operations
- Unit tests: Flutter folder provider logic
- Manual testing: folder creation, switching, item upload
- Manual testing: migration script on dev data

### 6. Deployment
- Deploy CloudFormation (creates chuck-items-v2)
- Deploy Lambda (new code with folder endpoints)
- Deploy Flutter web (build and sync to S3)
- Run migration script
- Verify production functionality

## Key Files Referenced

**technical.md:23-68** - DynamoDB schema and query patterns
**technical.md:83-100** - Folder API endpoints
**design.md:32-42** - Folder Organization UI specs
**lambda/dynamodb.go** - Current DynamoDB operations (to refactor)
**lambda/types.go** - Current type definitions (to extend)
**src/lib/services/api_service.dart** - Current API client (to extend)
