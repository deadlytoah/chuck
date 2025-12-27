# Plan: Wrap Filter Bar in SafeArea

## Prompt

The filter bar in the home page screen can be obscured by the camera
island at the top of the screen of an iPhone. I see the hamburger menu
is in the `SafeArea`. Can we do this for the filter bar as well? Record
your plan.

## Analysis

Current structure:
- `HomePage` (home_page.dart): Contains Stack with hamburger menu
  wrapped in SafeArea
- `MainView` (main_view.dart): Contains Column with FilterBar and
  ItemsGrid
- FilterBar is currently wrapped only in Padding, no SafeArea

Problem: FilterBar at top of MainView can be obscured by iPhone camera
island/notch.

Solution: Wrap FilterBar in SafeArea widget, similar to hamburger menu
implementation.

## Changes

### File: src/lib/screens/main_view.dart

Lines 27-35: Modify the Column children to wrap FilterBar in SafeArea

Current:
```dart
return Column(
  children: [
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilterBar(),
    ),
    const Expanded(child: ItemsGrid()),
  ],
);
```

Updated:
```dart
return Column(
  children: [
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const FilterBar(),
      ),
    ),
    const Expanded(child: ItemsGrid()),
  ],
);
```

## Implementation Steps

1. Open main_view.dart
2. Locate the Column widget in build method (line 27)
3. Wrap the Padding widget containing FilterBar with SafeArea
4. Test on iPhone simulator/device to verify filter bar is no longer
   obscured by camera island
