# Plan: Wrap Upload Area in SafeArea on Admin Page

## Prompt

Can we place the upload area in the admin page @admin_page.dart in the
SafeArea as well? Record your plan.

## Current State

- `admin_page.dart` has `UploadZone` wrapped in `Padding` (line 33)
- `home_page.dart` uses `SafeArea` for `HamburgerMenu` (lines 40-52)
- Upload area currently may be obscured by device notches/camera island

## Proposed Changes

### Wrap UploadZone in SafeArea

Modify `admin_page.dart` line 33 to wrap `UploadZone` in `SafeArea`:

**Before:**
```dart
const Padding(padding: EdgeInsets.all(16), child: UploadZone()),
```

**After:**
```dart
SafeArea(
  child: Padding(padding: EdgeInsets.all(16), child: UploadZone()),
),
```

## Rationale

- Ensures upload area not obscured by system UI (notch, camera island)
- Consistent with filter bar SafeArea implementation (plan 016)
- Maintains existing padding while adding safe area protection
