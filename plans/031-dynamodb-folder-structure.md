# Plan 031: DynamoDB Folder Structure

## Original Prompt
"If I were to add the concept of folder, so that you group the items
in different folders, how would this work with dynamodb?"

(Extended through discussion about UI, initial folder setup, and
migration strategy)

## Design Summary
- Single-table design: folders and items in chuck-items-v2
- PK: `FOLDER#{folderId}`, SK: `ITEM#{archived}#{createdAt}` or
  `METADATA`
- No GSI (archived filter scoped to current folder)
- First launch: auto-create "Clothes", "Blankets", "Books"; select
  "Clothes"
- Migration: script moves chuck-items data to "entryway" folder
- UI: folder selector at top center, bottom sheet picker

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
- Scan chuck-items table
- For each item: write to chuck-items-v2 with folderId="entryway"
- Build PK: `FOLDER#entryway`
- Build SK: `ITEM#{archived}#{createdAt}`
- Create "entryway" folder METADATA entity first
- Run manually: `cd lambda && go run migrate.go`

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
