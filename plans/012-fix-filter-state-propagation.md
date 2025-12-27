# Fix Filter State Propagation

## Findings

1.  **Initial Load Issue**: `MainView.initState` calls `ref.read(itemsProvider.notifier).loadItems()` without arguments.
    -   `loadItems` defaults `filter` to `null`.
    -   `ApiService` omits `filter` param if `null`.
    -   Lambda backend defaults missing `filter` to `"all"`.
    -   Result: Initial load or re-initialization always fetches all items, ignoring any selected filter.

2.  **Refresh Race Condition**: `FilterBar`'s `onChanged` updates the provider and immediately calls `_refresh`.
    -   `_refresh` reads `ref.read(filterProvider)`.
    -   If the provider update hasn't propagated, it reads the old value (or `null`).
    -   Result: "Refresh" or changing filter triggers a call with the old/null filter (often `"all"`), followed by a second call with the correct filter.

3.  **Other Call Sites**: `UploadZone` and `AdminPage` also call `loadItems()` without arguments, potentially resetting the view to "all" items after actions.

## Plan

1.  **Fix `MainView` Initialization**:
    -   Update `MainView.initState` to read the current values of `filterProvider` and `sortProvider` and pass them to `loadItems`.

2.  **Fix `FilterBar` Logic**:
    -   Modify `_refresh` to accept optional `filterOverride` and `sortOverride`.
    -   Update `DropdownButtonFormField.onChanged` to pass the new value directly to `_refresh`.

3.  **Fix Other Call Sites**:
    -   Update `UploadZone` and `AdminPage` to read current providers before calling `loadItems`.

## Prompt Used
"I'm interested to hear 3 suggested fixes for the ROOT CAUSE (_refresh being called before the provider state propagates) and your recommendation."

## Relevant Files
-   `src/lib/screens/main_view.dart`: Lines 16-21
-   `src/lib/widgets/filter_bar.dart`: Lines 57-60, 113-117
-   `src/lib/widgets/upload_zone.dart`: Line 56
-   `src/lib/screens/admin_page.dart`: Line 21
