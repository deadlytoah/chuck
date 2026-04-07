# Plan 040 — 2-Column Grid & Smaller Thumbnails

## Context

The web item grid currently uses `grid-cols-1 sm:grid-cols-2`, rendering
one column on mobile. This makes cards ~390px wide, far exceeding the
400×300px thumbnail size. The design spec has been updated to specify a
fixed 2-column grid. Future thumbnails should be reduced to 200×150px
(4:3, half current) to match the ~185px card width in a 2-col layout.
Existing thumbnails in S3 must not be modified.

## Files to Change

- `web/components/ItemGrid.tsx` — grid CSS class
- `ios/lib/services/image_service.dart` — `thumbWidth`/`thumbHeight`
  constants
- `technical.md` — iOS image upload spec
- `technical-backend.md` — shared image resize spec
- `technical-web.md` — already updated (`<ItemGrid>` description)
- `design-web.md` — already updated (grid description)

---

## Steps

### 1. `web/components/ItemGrid.tsx` — fix grid to 2 columns

- File: `web/components/ItemGrid.tsx`
- Line 54: change class `"grid grid-cols-1 sm:grid-cols-2 gap-2 px-2
  flex-1"` → `"grid grid-cols-2 gap-2 px-2 flex-1"`
- No other changes in this file.

### 2. `ios/lib/services/image_service.dart` — reduce thumb constants

- File: `ios/lib/services/image_service.dart`
- Line 7: change `static const int thumbWidth = 400;` →
  `static const int thumbWidth = 200;`
- Line 8: change `static const int thumbHeight = 300;` →
  `static const int thumbHeight = 150;`
- No other changes — `fullWidth`/`fullHeight` stay at 1200×900.

### 3. `technical.md` — update iOS image upload spec

- File: `technical.md`
- In section "Image Upload (iOS)", change:
  `Resize to 400x300px (thumbnail)` →
  `Resize to 200x150px (thumbnail)`

### 4. `technical-backend.md` — update shared image resize spec

- File: `technical-backend.md`
- In section "Image Resize & S3 Strategy", change:
  `Resize to fit within 400x300px (thumbnail)` →
  `Resize to fit within 200x150px (thumbnail)`

---

## What NOT to do

- Do not touch S3, DynamoDB, or any existing uploaded images.
- Do not change `fullWidth`/`fullHeight` (1200×900).
- Do not change `technical-web.md` or `design-web.md` (already done).
- Do not add migration scripts or backfill logic.
