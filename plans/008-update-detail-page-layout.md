# Plan: Update Detail Page Layout

## Prompt

The detail page shows the full sized image at the top, scaled to a
very small dimension. I want the image to be shown in larger scale,
but I want the UI to allow scrolling vertically down to the controls
(allowing editing of state and notes). Update the detail page in
`./src/lib/widgets/item_card.dart#194-266`. Record your plan and then
stop.

## Plan

1.  **Objective:** Modify the item detail view to display a larger
    image while ensuring all controls remain accessible via vertical
    scrolling.
2.  **File to Modify:** `src/lib/widgets/item_card.dart`
3.  **Strategy:**
    -   Wrap the content of the `showModalBottomSheet` in a
        `SingleChildScrollView`.
    -   Use a `Column` as the child of the `SingleChildScrollView` to
        arrange widgets vertically.
    -   Place the `Image.network` widget at the top of the `Column`,
        allowing it to render at a larger size.
    -   Place the state dropdown and notes field widgets below the
        image within the `Column`.
    -   Remove any existing `SizedBox` or other constraints that limit
        the image's height.