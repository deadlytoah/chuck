# Plan 009: Fix Admin Page Scrolling

## Prompt

In the admin page, the vertical scrolling is over the multi archival
widget. That gives the multi archival widget a very small screen
estate, especially on a small screen device. I'd like to have the
vertical scrolling over the entire admin page. The source code for
the admin page can be found in `./src/lib/screens/admin_page.dart`.
Keep in mind that changing `items_grid.dart` will affect another
widget that shares this widget, `./src/lib/screens/main_view.dart`.

## Current State Analysis

### admin_page.dart (lines 24-38)
- Uses Column with fixed-height widgets (UploadZone, FilterBar,
  BulkActions)
- ItemsGrid wrapped in Expanded, takes remaining vertical space
- Problem: Grid scrolls within limited space, not entire page

### items_grid.dart (lines 40-86)
- Column contains Expanded GridView.builder (scrollable)
- GridView scrolls internally, constrained by parent's Expanded
- Also contains optional "Load More" button below grid

### main_view.dart (lines 19-29)
- Uses Column with FilterBar + Expanded ItemsGrid
- Must continue working with scrollable ItemsGrid

## Problem

ItemsGrid in admin_page has limited vertical space because Column
allocates fixed heights to widgets above it. GridView scrolls within
this constraint, creating poor UX on small screens.

## Solution

Add parameter to ItemsGrid controlling scroll behavior, then modify
admin_page to use page-level scrolling.

### Step 1: Modify items_grid.dart
- Add optional bool parameter `shrinkWrap` (default: false)
- When false: Keep current behavior (Expanded GridView, scrollable)
- When true: Remove Expanded, use shrinkWrap on GridView, no scroll
- Ensures main_view.dart continues working unchanged

### Step 2: Modify admin_page.dart
- Wrap body Column in SingleChildScrollView
- Remove Expanded wrapper from ItemsGrid
- Pass shrinkWrap: true to ItemsGrid
- Entire page becomes scrollable unit

## Benefits

- Full vertical scrolling over entire admin page
- More screen real estate for ItemsGrid on small screens
- No impact on main_view.dart functionality
- Minimal code changes, backward compatible

## Files to Modify

1. `chuck/src/lib/widgets/items_grid.dart`
2. `chuck/src/lib/screens/admin_page.dart`
