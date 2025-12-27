# Plan: Align Error Alerts with Design Specifications

## Prompt

Identify part of the code that alert errors that need to be made in
line with design.md and technical.md

## Files Referenced

- `design.md:74-96` - Error handling specifications
- `technical.md:166-175` - Error message display requirements
- `src/lib/screens/camera_screen.dart:114-137` - Camera permission UI
- `src/lib/widgets/item_card.dart:126-148` - Archive/unarchive error
  handling
- `src/lib/widgets/failed_upload_banner.dart:22-61` - Upload failure
  banner

## Implementation Plan

### 1. Camera Permission Denied - Convert to AlertDialog

**File:** `src/lib/screens/camera_screen.dart:114-137`

**Current:** Full-screen UI with text and buttons

**Changes:**
- Replace full-screen UI with AlertDialog
- Title: "Camera Access Required"
- Content: "Camera access is needed to take photos of items."
- Actions: "Go to Settings" (calls `openAppSettings`), "Cancel" (pop)
- Show dialog when permission denied, then pop back to previous screen

### 2. Archive/Unarchive Failures - Add Inline Error State

**File:** `src/lib/widgets/item_card.dart:126-148`

**Current:** SnackBar on failure

**Changes:**
- Remove SnackBar calls (lines 131-133, 143-145)
- Add error state tracking to ItemCard widget
- Show red border + error icon on card when operation fails
- Add inline retry button in error state
- Clear error state on successful retry or manual dismissal

### 3. Failed Upload Banner - Convert to Consolidated Notification

**File:** `src/lib/widgets/failed_upload_banner.dart:22-61`

**Current:** Persistent red banner with retry button

**Changes:**
- Remove persistent banner display
- Replace with brief consolidated notification (toast-style)
- Message: "Some photos failed to upload. Tap the queue button to
  review."
- Green background, top of screen, 2s auto-dismiss
- Show once after retry exhaustion (not continuously)
- Track notification shown state to avoid repeated displays
- No retry button in notification (user reviews via queue button)
