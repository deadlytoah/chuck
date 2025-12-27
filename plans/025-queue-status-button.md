# Queue Status Button Implementation

## Prompt
@design.md and @technical.md talk about the queue button. Generate
plan to make the button as specified with the number describing the
number of items in the queue.

## Relevant Specifications

### From design.md (lines 62-64)
- Camera button located in bottom right corner of home page (Main View)
- Queue status button next to camera button shows total queued photo
  count (e.g., "3")

### From design.md (lines 81-84)
- Subtle indicator: queue status button shows total queued items
- Persistent failure notification: consolidated message after retry
  exhaustion directs user to queue status button
- Manual review screen: current status, pending/failed items, retry
  option, actionable guidance

### From technical.md (lines 139-140)
- UI: camera button (FAB) in bottom right corner; queue status button
  placed next to camera button showing total queued photo count

### From technical.md (lines 151-162)
- Queue status button shows total queued items (pending + failed)
- Consolidated notification after retry exhaustion: "Some photos have
  failed to upload. Tap the queue button next to the camera to review."
- Manual Review Screen accessed via queue status button with:
  - Display: pending/failed items with status
  - Actions: "Retry" button, clear completed items
  - Guidance: error resolution steps

## Current Implementation Analysis

### src/lib/widgets/camera_badge.dart
- Badge widget exists but displays as overlay on camera FAB (lines
  14-36)
- Shows red badge with white count text
- Hidden when count is 0

### src/lib/screens/home_page.dart (lines 71-84)
- Camera FAB with CameraBadge overlay in Stack
- Badge positioned top-right over FAB using Positioned widget
- Uses `pendingCount` from camera queue service

### src/lib/services/camera_queue_service.dart (lines 34-40)
- `pendingCount` getter correctly counts pending + failed photos
- Returns total of items needing upload/retry

## Gap Analysis

Current implementation uses badge overlay on camera button.
Specification requires separate queue status button next to camera
button. Need to:
1. Create standalone queue status button widget
2. Position button next to (not over) camera FAB
3. Add navigation to manual review screen
4. Implement manual review screen with retry functionality

## Implementation Plan

1. Create queue status button widget
   - Standalone button showing queue count as text (e.g., "3")
   - Always visible (shows "0" when queue empty)
   - Tappable to navigate to queue review screen
   - Position: next to camera FAB (to the left)

2. Create queue review screen
   - Display list of queued photos with status indicators
   - Show pending vs failed states clearly
   - "Retry All" button for failed items
   - Clear completed items option
   - Error resolution guidance text

3. Update home_page.dart layout
   - Remove CameraBadge overlay from camera FAB Stack
   - Add Row containing queue status button + camera FAB
   - Wrap in Stack if needed for positioning
   - Maintain bottom-right placement

4. Wire up navigation
   - Queue status button onPressed navigates to review screen
   - Pass camera queue service to review screen via provider

5. Update failed upload banner
   - Ensure banner text mentions queue button as specified
   - Message: "Some photos have failed to upload. Tap the queue button
     next to the camera to review."

6. Test queue button visibility
   - Always visible (shows "0" when queue empty)
   - Shows count when items queued
   - Updates reactively as queue changes
   - Navigation works correctly

## Files to Modify

- `src/lib/screens/home_page.dart`: Update FAB layout, add queue
  button
- `src/lib/widgets/camera_badge.dart`: Remove (no longer needed) or
  repurpose
- `src/lib/widgets/failed_upload_banner.dart`: Update message text
- Create `src/lib/screens/queue_review_screen.dart`: New manual review
  screen
- Create `src/lib/widgets/queue_status_button.dart`: New queue button
  widget
