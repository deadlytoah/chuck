# Plan: Remove "x selected" Label for Mobile Archive Button

## Prompt
"I can't see the archive button in bulk archive screen because the
button overflows to the right on my phone screen"

## Problem
Archive button overflows on narrow mobile screens in bulk actions bar
due to competing elements:
- "Exit Selection Mode" button (left)
- "X selected (max 25)" text (center)
- "Clear" button (right side)
- "Archive X items" button (rightmost, overflows)

## Solution
Redesign button layout to swap "Bulk Archive" with "Cancel" and
"Archive Selected" buttons in selection mode

## Implementation Steps

1. **Remove selection count text** (bulk_actions.dart:52-55)
   - Delete Text widget showing "$selectedCount selected (max 25)"
   - Frees horizontal space

2. **Remove Clear button** (bulk_actions.dart:53-59)
   - Delete TextButton for clearing selection
   - Functionality replaced by Cancel button

3. **Redesign button interaction** (bulk_actions.dart:30-60)
   - Initial state: Show "Bulk Archive" button only
   - Click "Bulk Archive": Hide it, show "Cancel" and "Archive Selected"
   - "Archive Selected" initially disabled/grayed out (onPressed: null)
   - As user selects items, "Archive Selected" becomes enabled
   - "Cancel" button exits selection mode (restores "Bulk Archive")
   - No Spacer needed - buttons naturally flow left

4. **Add test case** (test/widgets/bulk_actions_test.dart)
   - Test Bulk Archive button shown initially
   - Test Bulk Archive hidden when in selection mode
   - Test Cancel and Archive Selected appear in selection mode
   - Test Archive Selected is disabled (onPressed: null) when no items selected

5. **Test on mobile**
   - Verify all buttons visible on narrow screens
   - Ensure button text doesn't wrap/truncate
   - Check spacing is adequate for touch targets

## Files Modified
- `src/lib/widgets/bulk_actions.dart` (lines 30-64)
- `src/test/widgets/bulk_actions_test.dart` (new test case)

## Expected Result
Compact mobile layout with button swap interaction:
- Initial: "Bulk Archive" button
- Selection mode: "Cancel" + "Archive Selected" (disabled) buttons
- As items selected: "Archive Selected" becomes enabled
- No overflow on mobile screens
