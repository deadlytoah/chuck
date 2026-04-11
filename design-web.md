`chuck` web app — Next.js static site for viewing and updating item
states. Targets iPhone Safari. Consumes the existing REST API
(see `technical.md`). No authentication; URL-based access.

This document covers the **Next.js web app**. See `design.md` for
the Flutter iOS app spec.

## Overview

`chuck` is a shared family app for categorizing household items with
photos. Items are photographed via the Flutter iOS app, then reviewed
and categorized by family members. The web app solves the second half:
a fast, low-friction interface for anyone in the family to open a link
on their phone and start making decisions without installing an app.

The core problem with using the iOS app for review-only users is the
install barrier. The web app removes it: share a URL, open Safari,
start categorizing. The design priority is speed and directness—tap a
photo, tap a decision, done. No sign-in, no onboarding.

## Target Users

- Family members reviewing and categorizing household items
- iPhone Safari (iOS 16+); desktop browsers not supported
- Non-technical users; expected to need no explanation to use the app

## Scope

**In scope:**
- View items in a folder as a thumbnail grid
- Select and update item state (Chuck, Keep, Sell, Undecided)
- Folder switching via bottom sheet
- Token-based pagination with "Load More"
- Manual refresh
- Optimistic state updates with rollback on error
- Persistent folder selection via URL query parameter and `localStorage`
- Bookmarkable folder URLs: `/?folder=<folderId>`

**Out of scope:**
- Image upload (use Flutter iOS app)
- In-app camera
- Admin functions: item creation, folder management, bulk archive
- Offline support
- Push notifications
- Authentication or access control (URL kept private)
- Full-resolution image view

## Acceptance Criteria

- Folder list loads on first visit; last-selected folder restored on
  return visits
- Selecting a folder updates the URL to `/?folder=<folderId>`
- Opening a bookmarked URL opens the bookmarked folder
- Navigating to folder F then refreshing shows folder F (URL drives
  state on refresh)
- Invalid or missing `?folder=` falls back to `localStorage`, then
  to default folder priority
- Item grid renders thumbnails with current state badge
- Tapping a card opens state overlay with selectable states (Chuck,
  Keep, Sell, Undecided); tapping a state applies it and dismisses
  the overlay
- Optimistic update: badge changes immediately; reverts on API error
- "Load More" fetches next page without losing scroll position
- Errors shown inline or as toast; no blocking modals
- All touch targets ≥44×44pt (Apple HIG)
- Works correctly in iPhone Safari (375–430px viewport)

## Quality Expectations

- Code should be simple and maintainable; avoid over-engineering
- No external state management libraries; use React built-ins
- Static export only; no SSR, no server-side dependencies
- Graceful degradation: API errors surface to the user without
  crashing the app
- Inline errors with retry for list failures; toast for update
  failures
- User-friendly messages in UI; technical details in console only

## Performance

**Targets:**
- Time to interactive on LTE: <2s (static assets from S3 + CDN)
- Item grid render (50 items): <300ms after data arrives
- State update round-trip: <500ms on LTE; optimistic UI hides latency

**Approach:**
- Static export served from S3; no server-side rendering overhead
- Images lazy-loaded (`loading="lazy"`); thumbnails only in grid
- No polling; no background network activity

**Can live without:**
- Service worker / offline cache
- Image prefetching
- Virtualized grid (acceptable for 50–100 items per folder)
- Skeleton screens (loading spinner is sufficient)

## Security

- No authentication; access controlled by keeping the URL private
- Static assets served over HTTPS via CloudFront; S3 bucket is
  private (no public-read)
- All API calls go to the existing Lambda function URL (HTTPS)
- No secrets stored client-side; no tokens, no credentials
- No user-generated HTML rendered; XSS risk is minimal
- CORS configured on Lambda to allow the CloudFront origin only

## Assumptions

- Family members have the URL shared via iMessage or similar
- Item count per folder: 50–100; not expected to scale to thousands
- The REST API (Lambda) is already deployed and stable
- Thumbnails are pre-generated and stored in S3 alongside originals
- Network is generally reliable (home Wi-Fi or LTE); offline not
  required
- The custom domain is managed in Route 53 and an ACM certificate
  can be issued for it

## Dependencies

- **AWS Lambda** — REST API for item and folder data
- **AWS S3** — static site hosting (private) and image storage
- **AWS CloudFront** — HTTPS CDN in front of S3; caches static
  assets globally
- **AWS ACM** — TLS certificate for the custom domain
  (provisioned in us-east-1 for CloudFront)
- **AWS Route 53** — DNS alias record pointing to CloudFront
- **Next.js** — framework (static export mode)
- **React** — UI library
- No third-party UI component libraries; plain CSS + React

## Risks and Tradeoffs

| Risk / Tradeoff | Notes |
|---|---|
| No auth | Mitigated by keeping URL private; acceptable for family use |
| Optimistic updates | State can briefly diverge from server; rollback on error handles it |
| No offline support | Acceptable; family members are on reliable networks |
| Static export only | Limits future features requiring SSR (e.g., server actions) |
| Manual refresh only | Simpler, but users may miss updates made by others |
| Single API region | Latency acceptable for small family use; no geo-distribution needed |
| CloudFront cost | ~$0–$1/mo at family-scale traffic; negligible |

## Open Questions

- Should the web app support filtering by state (e.g., show only
  Unanswered items), consistent with the iOS app?
- Should there be a visual indicator when another user has recently
  updated an item (e.g., highlight or timestamp)?
- Should error toasts include a manual retry action for state update
  failures, or is rollback + re-tap sufficient?

## User Interface

### Folder Selection

- Folder selector displayed prominently at top of screen
- Selecting a folder updates the URL in place (`?folder=<folderId>`)
  without adding a browser history entry; the item grid reloads
- The selected folder is reflected in the URL at all times, making
  the current URL a valid bookmark for that folder
- Opening a bookmarked URL restores the bookmarked folder; navigating
  away changes the URL but does not retroactively alter the bookmark
- Refreshing the page shows whatever folder is in the URL at that
  moment (not necessarily the original bookmarked folder)
- Folder selection priority on load:
  1. `?folder=` query param, if it matches a known folder
  2. `chuck.folderId` from `localStorage`
  3. "Inbox" folder if it exists
  4. First folder alphabetically
  5. None (if no folders returned by API)
- If `?folder=` is present but matches no known folder, a transient
  notice is shown ("Folder not found; showing [folder name]",
  toast-style, 3s auto-dismiss) and the app falls through to
  step 2 of the priority list

### Main View (Item Grid)

- 2-column grid of thumbnail cards, filling viewport width
- Default: current folder, sorted by newest first
- "Load More" button at bottom of grid for additional items (not
  infinite scroll — explicit tap keeps behavior predictable and
  surfaces errors at the boundary)
- Manual refresh button
- Each card shows thumbnail image and current state badge

### Item State Update

- Tapping a card reveals an overlay listing the states the item can
  transition to (current state and Unanswered excluded)
- States: Chuck, Keep, Sell, Undecided
- Overlay: state labels stacked vertically, centered, over a
  semi-transparent dark background
- Tapping a state applies it immediately; overlay dismisses
- Tapping outside the card dismisses the overlay without changes
- No explicit save required; state change applies on selection
- State badge updates immediately; reverts automatically on error

### Animations

Animations must be brief and purposeful — never decorative. Duration
target: 150–200ms. Goal: reinforce causality between tap and result
without distracting from the decision task.

**State overlay (open/close):**

- Fade in (`opacity: 0 → 1`) combined with a subtle scale on the
  card (`scale: 1.0 → 1.02`) when the overlay opens
- Reverse on dismiss
- Cognitive link: fade reveals a layer; scale confirms the tap landed

**State badge update:**

- Brief fade-through when the badge label changes state
- Keeps the user's eye on the result of their decision

**Folder dropdown:**

- Spring-eased slide down on open; slide up on close
- Consistent with iOS system dropdown conventions

**Principles:**

- No animation on initial page load or \"Load More\" (spinner only)
- Prefer CSS transitions over JS animation libraries
- Respect `prefers-reduced-motion`: skip all transitions when set

### UI Responsiveness

Targets iPhone Safari (375–430px viewport width).

**Layout:**

- 2-column grid filling the iPhone viewport width
- Touch targets minimum 44×44pt per Apple HIG
- Fixed header (folder selector) always reachable

**Interaction feedback:**

- State button tap: immediate visual highlight before server confirms
- Loading spinner on initial load and "Load More"
- Errors shown inline (banner) with dismiss; no blocking modals for
  non-critical errors

### Error Messages

- List loading failures: inline error banner with retry button
- State update failures: toast-style error (red, 3s auto-dismiss)
  with state reverted
- Unknown `?folder=` on load: toast-style notice (3s auto-dismiss):
  "Folder not found; showing [folder name]"
- User-friendly messages in UI; no blocking overlays.
