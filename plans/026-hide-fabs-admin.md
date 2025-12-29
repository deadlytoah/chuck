# Plan 026: Hide FABs on Admin Page

## Prompt
"Can you generate a plan to make the app comply to this part of the
design docs" (regarding FABs appearing on admin screen)

## Design Requirements (from design.md:62 and technical.md:139-140)
- Camera button (FAB) should be in bottom right corner of **Main
  View only**
- Queue status button should be next to camera button
- FABs should NOT appear on Admin Page

## Current Implementation (home_page.dart:72-96)
- `floatingActionButton` defined at HomePage level in Scaffold
- Contains Row with QueueStatusButton and camera FAB
- Shows on all screens (IndexedStack: MainView and AdminPage)
- `_selectedIndex` tracks active tab (0=MainView, 1=AdminPage)

## Implementation Steps

1. Conditionally show FABs based on `_selectedIndex`
   - Wrap `floatingActionButton` with conditional:
     `_selectedIndex == 0 ? Row(...) : null`
   - Only renders FABs when Main View is active (index 0)

2. Test visibility
   - Verify FABs appear on Main View
   - Verify FABs hidden on Admin Page
   - Verify navigation between tabs works correctly

## Files to Modify
- `src/lib/screens/home_page.dart` (line 72)
