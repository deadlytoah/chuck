`chuck` web app — Next.js static site for viewing and updating item
states. Targets iPhone Safari. Consumes the existing REST API
(see `technical.md`). No authentication; URL-based access.

This document covers the **Next.js web app**. See `design.md` for
the Flutter iOS app spec.

## User Interface

### Folder Selection

- On load, fetch folder list via `GET /folders`
- Folder selector displayed prominently at top of screen
- Last-selected folder persisted in `localStorage`; restored on next
  visit, fallback to first folder alphabetically
- Tapping selector opens a bottom sheet listing all folders
- Selecting a folder reloads the item grid for that folder

### Main View (Item Grid)

- Responsive CSS grid of thumbnail cards, filling viewport width
- Default: current folder, "ALL" filter, sorted by `createdAt`
  descending
- Filter bar below folder selector: All, Chuck, Keep, Sell, Undecided,
  Unanswered, Archived
- Sort controls: `createdAt`, `updatedAt`, `state`
- Token-based pagination; "Load More" button at bottom of grid
- Manual refresh button
- Each card shows thumbnail image and current state badge

### Item State Update

- State updated via context menu on each card (no separate edit
  screen)
- Context menu options: Chuck, Keep, Sell, Undecided, Unanswered
- State change sent immediately via `PUT /items/{id}` on selection;
  no explicit save required
- Card state badge updates immediately (optimistic update);
  rolled back on error

### State Management

- Client state: React `useState`/`useReducer`; no external library
- Item list mutations update local state optimistically before API
  response; rolled back on error
- Folder selection and active filter/sort persisted in `localStorage`
- No polling; users refresh manually

### UI Responsiveness

Targets iPhone Safari (375–430px viewport width).

**Layout:**
- Single-column layout on mobile; grid adapts to 2 columns at ≥640px
- Touch targets minimum 44×44pt per Apple HIG
- Bottom sheet for folder selection uses spring animation
  (`transition: transform`)
- Fixed header (folder selector + filter bar) always reachable

**Interaction feedback:**
- State button tap: immediate visual highlight before API response
  (optimistic update)
- Loading spinner on initial fetch and "Load More"
- Errors shown inline (banner below filter bar) with dismiss; no
  blocking modals for non-critical errors
- Success: brief toast (green, slides up from bottom, 2s auto-dismiss)

**Performance:**
- Images lazy-loaded via `loading="lazy"`
- Thumbnails in grid only; no full-image view
- Static export served from S3; no server-side rendering

### Error Messages

- List loading failures: inline error banner with retry button
- Item state update failures: toast-style error (red, 3s auto-dismiss)
  with state rolled back
- General principle: user-friendly messages in UI, technical details
  in browser console. No blocking overlays.

### Out of Scope

- Admin functions (item creation, bulk archive, folder management)
- Image upload (use Flutter iOS app)
- In-app camera and upload queue
- Offline support
