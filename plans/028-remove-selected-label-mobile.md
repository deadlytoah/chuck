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
Remove "X selected (max 25)" label to make room for archive button

## Implementation Steps

1. **Remove selection count text** (bulk_actions.dart:52-55)
   - Delete Text widget showing "$selectedCount selected (max 25)"
   - Remove associated SizedBox spacing (line 51, 56)

2. **Update layout spacing**
   - Keep Spacer() between left and right button groups
   - Adjust spacing between Clear and Archive buttons if needed

3. **Alternative: Show count in badge or tooltip**
   - Optional: Add badge to archive button icon showing count
   - Or: Include count only in Archive button text

4. **Add test case** (test/widgets/bulk_actions_test.dart)
   - Test that selection count text is not present in widget tree
   - Verify Archive button is rendered when items selected
   - Ensure Clear button is present in selection mode

5. **Test on mobile**
   - Verify all buttons visible on narrow screens
   - Ensure button text doesn't wrap/truncate
   - Check spacing is adequate for touch targets

## Files Modified
- `src/lib/widgets/bulk_actions.dart` (lines 50-56)
- `src/test/widgets/bulk_actions_test.dart` (new test case)

## Expected Result
All action buttons (Exit, Clear, Archive) visible on mobile without
horizontal overflow or scrolling required.
