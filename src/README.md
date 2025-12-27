# `chuck` Flutter Client

This is the Flutter web client for `chuck`, a shared record-keeping web
app for organizing items with pictures.

## Features

### Main View
- Grid view of items with thumbnail images and token-based pagination.
- Sort items by `updatedAt` or state.
- Filter items by state: Chuck, Keep, Sell, Undecided, Unanswered. An
  "ALL" filter excludes archived items.
- Manually refresh to see updates from other users.
- Archive items individually.
- Select an item's state (Chuck, Keep, Sell, or Undecided).

### Detail View
- View full-size images of an item.
- Add and edit multi-line notes for an item.

### Admin Page
- Insert new items with image uploads (drag-and-drop or file picker).
- Update an item's state and notes. Images are immutable.
- Bulk archive up to 25 items at a time.
- Unarchive items.
