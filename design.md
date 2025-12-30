`chuck` is a shared record-keeping web app for organizing items with
pictures. All users can view and update item states together from
their own devices. View items in a grid and select Chuck, Keep, Sell, or
Undecided. Items start in Unanswered state. No access protection—URL
kept private within family. Access via domain URL shared via text
message.

Designed for small-scale use: 50-100 items per collection.

## Architecture

Hosted on AWS with the following stack:
- **Frontend:** Flutter web application
- **Backend:** AWS Lambda functions
- **Storage:** Pictures are resized in the browser before upload and
  stored in S3.
  - Presigned URL expires in 5 minutes.
  - Images are capped at 400x300 (thumbnail) and 1200x900 (full),
    preserving the original aspect ratio.
  - The thumbnail path is derived from the full image URL by convention.
  - Archived items are automatically deleted from S3 after 30 days via a
    lifecycle policy.
- **Data:** User selections stored in DynamoDB

## User Interface

The main view serves as the landing page. A TabBar at the top switches
between Main View and Admin. Filter, sort and refresh controls are in
the AppBar. Default: Main View tab with "ALL" filter, sorted by
updatedAt descending.

**Main View:**
- Grid view using thumbnail images, with token-based pagination.
- Sort: by `createdAt`, `updatedAt` or `state`
- Filter: by state (Chuck, Keep, Sell, Undecided, Unanswered). The "ALL"
  filter excludes archived items.
- Manual refresh for updates. Newly uploaded items appear automatically
  after backend confirmation.
- Archive button per item. Archived items retain their last known state.
- State selection available to all users

**Edit Item Screen:**
- Separate screen (not dialog) accessed by tapping an item card
- View full-size images
- Edit state (Chuck, Keep, Sell, Undecided, Unanswered)
- Add and edit multi-line notes

**Admin Page:**
- All users have permission to perform all actions, including admin tasks.
- Insert items: image upload (drag-drop/picker). Supports sequential
  file uploads with an overall progress indicator and thumbnail
  previews. Failed uploads auto-retry with exponential backoff.
- Update items: modify state and notes via Edit Item Screen. Images
  are immutable after creation.
- Bulk archive: toggle button activates checkbox selection mode.
  Supports up to 25 items per batch. Partial success acceptable with
  failure indicators.
- Archive individual items via archive button
- Unarchive items: access archived items via main grid filter="archived",
  then unarchive using Edit Item Screen

**In-App Camera (iOS only):**

- Camera button located in bottom right corner of home page (Main View)
- Queue status button next to camera button shows total queued photo
  count (e.g., "3")
- Continuous capture mode: user can continuously take photos without
  leaving the camera screen
- Photos immediately added to queue upon capture (no cancellation)
- Maximum queue of 12 photos maintained to manage memory and processing
- Visual feedback: brief text message "Photo queued for upload" fades
  in/out with haptic feedback when photo added to queue
- Queue processes immediately when non-metered network available,
  regardless of app state
- New items appear in Main View grid after backend confirms creation
  (POST /items completes)
- Camera exit: back button only, returns user to home page
- Camera permission denied: alert dialog explaining camera access need
  with "Go to Settings" and "Cancel" buttons

**Upload Failure Handling:**

- Silent retry strategy: automatic retries for transient errors without
  user notification
- Retry limit: 3 attempts per photo
- Subtle indicator: queue status button shows total queued items
- Persistent failure notification: consolidated message directs user to
  queue status button for review
- Manual review screen: current status, pending/retrying/failed items,
  Retry button to trigger upload for all queued photos, actionable
  guidance

**Error Messages:**

Error display patterns:
- List loading failures: alert dialog with user-friendly message for
  critical errors that prevent app functionality
- Item operations (archive/unarchive/state changes): alert dialog with
  user-friendly message. Technical error details logged to console.
- Bulk operation results: success/failure summary inline in bulk actions
  panel
- Upload failures: silent retry with consolidated notification after
  exhaustion; manual review via queue status button
- Success confirmations: brief toast-style banner (green, top of screen,
  2s auto-dismiss, no user interaction required)
- General principle: user-friendly messages in UI, technical details in
  logs. No persistent banners or overlays. Users retry via normal UI
  elements (refresh button, etc.).
