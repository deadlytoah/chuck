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
Remove "X selected (max 25)" label and Clear button to make room for
archive button

## Implementation Steps

1. **Remove selection count text** (bulk_actions.dart:52-55)
   - Delete Text widget showing "$selectedCount selected (max 25)"
   - Remove associated SizedBox spacing

2. **Remove Clear button** (bulk_actions.dart:53-59)
   - Delete TextButton for clearing selection
   - Users can exit selection mode to clear instead
   - Simplifies layout to just Exit and Archive buttons

3. **Shorten button labels** (bulk_actions.dart:40)
   - "Bulk Archive" => "Archive"
   - "Exit Selection Mode" => "Cancel"
   - Reduces button width significantly

4. **Update layout spacing**
   - Keep Spacer() between buttons
   - Minimal elements for maximum mobile space

5. **Add test case** (test/widgets/bulk_actions_test.dart)
   - Test that selection count text is not present in widget tree
   - Test that Clear button is not present
   - Verify Archive button is rendered when items selected

6. **Test on mobile**
   - Verify all buttons visible on narrow screens
   - Ensure button text doesn't wrap/truncate
   - Check spacing is adequate for touch targets

## Files Modified
- `src/lib/widgets/bulk_actions.dart` (lines 50-64)
- `src/test/widgets/bulk_actions_test.dart` (new test case)

## Expected Result
Archive button visible on mobile with compact layout:
- Initial: "Archive" button (enters selection mode)
- Selection mode: "Cancel" button (left), "Archive X items" (right)
- No overflow on narrow mobile screens
