# Manual Test Checklist for In-App Camera Feature

This document lists manual tests that require physical device testing
and cannot be fully automated. Run these tests on actual iOS/Android
devices before release.

## Prerequisites
- Physical device with camera (iOS or Android)
- Active WiFi and cellular data connections
- App installed in debug/release mode

## Test Scenarios

### 1. Camera Permission Request Flow
**Steps:**
1. Fresh app install (or clear app data)
2. Navigate to camera screen
3. Observe OS permission dialog

**Expected:**
- System permission dialog appears
- Dialog shows camera permission request
- "Allow" option available
- "Don't Allow" option available

**Pass/Fail:** ___

---

### 2. Permission Denied → Settings Button
**Steps:**
1. Deny camera permission when prompted
2. Navigate to camera screen again
3. Tap "Open Settings" button

**Expected:**
- Permission denied message displays
- "Open Settings" button visible and tappable
- Tapping button opens device Settings app
- Settings app shows app permissions page
- User can manually enable camera permission

**Pass/Fail:** ___

---

### 3. Continuous Capture (Multiple Photos)
**Steps:**
1. Grant camera permission
2. Tap capture button rapidly 5 times
3. Check queue count badge

**Expected:**
- Each tap captures a photo
- Queue badge shows increasing count (1→2→3→4→5)
- No crashes or freezes
- Camera preview remains responsive

**Pass/Fail:** ___

---

### 4. Queue Full Behavior (12 Photos)
**Steps:**
1. Capture 12 photos sequentially
2. Observe capture button state
3. Attempt to capture 13th photo

**Expected:**
- Queue badge shows count up to 12
- After 12 photos, capture button becomes semi-transparent (0.5
  opacity)
- Tapping button when full does nothing
- No photo captured
- No crash

**Pass/Fail:** ___

---

### 5. Queue Badge Count Accuracy
**Steps:**
1. Capture 3 photos
2. Note badge count
3. Wait for photos to upload (WiFi required)
4. Observe badge count decreasing

**Expected:**
- Badge shows "3" after capture
- Badge count decreases as uploads complete
- Badge disappears (hidden) when count reaches 0
- Badge reappears when new photo captured

**Pass/Fail:** ___

---

### 6. Network Switching (Cellular to WiFi)
**Steps:**
1. Enable cellular data only (disable WiFi)
2. Capture 3 photos
3. Observe queue (uploads should NOT start)
4. Enable WiFi
5. Observe queue processing

**Expected:**
- Photos remain in queue on cellular
- Queue badge stays at "3"
- Upon WiFi connection, uploads begin automatically
- Queue badge count decreases as uploads succeed

**Pass/Fail:** ___

---

### 7. Network Switching (WiFi to Cellular Mid-Upload)
**Steps:**
1. Connect to WiFi
2. Capture 5 photos
3. While uploads processing, disable WiFi
4. Enable cellular data only

**Expected:**
- Uploads pause when WiFi lost
- Queue badge stops decreasing
- Remaining photos stay in queue
- No crashes or errors displayed

**Pass/Fail:** ___

---

### 8. App Backgrounding/Foregrounding
**Steps:**
1. Open camera screen
2. Press home button (background app)
3. Wait 10 seconds
4. Reopen app to camera screen

**Expected:**
- Camera preview reinitializes on resume
- No camera freeze or black screen
- Capture button remains functional
- Queue persists (photos not lost)

**Pass/Fail:** ___

---

### 9. Upload Processing (Serial, One at a Time)
**Steps:**
1. Connect to WiFi
2. Capture 3 photos quickly
3. Observe network traffic or logs

**Expected:**
- Uploads process sequentially (not parallel)
- First photo uploads completely before second starts
- Queue badge decreases one at a time
- Total time: ~30-60 seconds for 3 photos (network-dependent)

**Pass/Fail:** ___

---

### 10. Failed Upload Retry Logic
**Steps:**
1. Enable airplane mode
2. Capture 2 photos
3. Disable airplane mode, enable WiFi
4. Observe upload behavior

**Expected:**
- Photos marked as failed after initial upload attempt
- Upon reconnecting, failed photos retry automatically
- Uploads succeed on retry
- Queue clears after successful retry

**Pass/Fail:** ___

---

### 11. Back Button Navigation
**Steps:**
1. Navigate to camera screen
2. Tap back button (arrow icon, top-left)

**Expected:**
- Screen navigates back to previous view
- Camera resources released (no background camera activity)
- Queue persists (not cleared)

**Pass/Fail:** ___

---

### 12. Flash Feedback Timing and Appearance
**Steps:**
1. Tap capture button
2. Observe screen flash

**Expected:**
- White overlay flashes on capture
- Flash duration: ~100ms
- Flash opacity: ~80% white
- Flash appears immediately after tap
- Flash disappears smoothly

**Pass/Fail:** ___

---

### 13. Haptic Feedback on Capture
**Steps:**
1. Enable haptics in device settings
2. Tap capture button with finger on device

**Expected:**
- Medium haptic vibration on tap
- Haptic occurs simultaneously with flash
- Haptic strength appropriate (not too strong/weak)

**Pass/Fail:** ___

---

### 14. Image Scaling Verification (Thumbnail 400x300)
**Steps:**
1. Capture a photo
2. Wait for upload
3. Inspect uploaded thumbnail in S3 bucket or database

**Expected:**
- Thumbnail dimensions: max 400x300 (aspect preserved)
- Image clear and recognizable
- No distortion or stretching

**Pass/Fail:** ___

---

### 15. Image Scaling Verification (Full 1200x900)
**Steps:**
1. Capture a photo
2. Wait for upload
3. Inspect uploaded full image in S3 bucket or database

**Expected:**
- Full image dimensions: max 1200x900 (aspect preserved)
- Image quality good
- JPEG compression visible but acceptable

**Pass/Fail:** ___

---

### 16. JPEG Quality (85%)
**Steps:**
1. Capture a photo
2. Download uploaded images from S3
3. Check file properties or use image analysis tool

**Expected:**
- Both thumbnail and full images in JPEG format
- File size reasonable (not too large/small)
- Visual quality good for 85% compression
- No excessive artifacts

**Pass/Fail:** ___

---

## Summary
- **Total Tests:** 16
- **Passed:** ___
- **Failed:** ___
- **Blocked:** ___

## Notes
(Add any observations, issues, or device-specific notes here)

---

## Test Environment
- **Date:** ___________
- **Tester:** ___________
- **Device:** ___________
- **OS Version:** ___________
- **App Version:** ___________
- **Network:** WiFi: ___ / Cellular: ___
