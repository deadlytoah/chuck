# Technical Specifications — Next.js Web App

This document covers the Next.js web app frontend. See
`technical-backend.md` for the shared backend (API, DynamoDB, S3,
infrastructure) and `technical.md` for the Flutter iOS app.

## Stack

- Framework: Next.js 16 (static export via `output: 'export'`)
- Hosting: S3 bucket `chuck.overcomingsh.in` (root path)
- Styling: Tailwind CSS
- State: React `useState` / `useReducer` (no external library)
- No SSR; all rendering client-side

## API Integration

- Base URL: Lambda Function URL (from `technical.md`)
- All requests use `fetch`; JSON request/response bodies
- CORS handled by Lambda (allow all origins)
- Endpoints used:
  - `GET /folders` — load folder list on app init
  - `GET /items` — load item grid (with filter/sort/pagination params)
  - `PUT /items/{id}` — update state; called immediately on selection

## State Management

- Folder list: fetched once on load; re-fetched on manual refresh
- Item list: fetched per folder/filter/sort combination; paginated
- Optimistic updates: state change applied locally before API call;
  rolled back on error with toast notification
- `localStorage` keys:
  - `chuck.folderId` — last-selected folder ID
  - `chuck.filter` — last-selected filter
  - `chuck.sort` — last-selected sort

## Routing

- `/` — Main View (item grid); single route, no sub-pages

## Component Structure

- `<FolderSelector>` — top bar; opens `<FolderBottomSheet>`
- `<FilterBar>` — filter + sort controls; fixed below folder selector
- `<ItemGrid>` — CSS grid of `<ItemCard>` components
- `<ItemCard>` — thumbnail + state badge + context menu trigger
- `<StateContextMenu>` — context menu with state options
- `<Toast>` — transient success/error notifications
- `<ErrorBanner>` — inline error with retry button

## Responsiveness

- Breakpoints: single column < 640px; 2 columns ≥ 640px
- Touch targets: min 44×44pt
- Header (folder selector + filter bar): `position: sticky; top: 0`
- Bottom sheet: `position: fixed; bottom: 0`; `transform: translateY`
  animation for open/close

## Image Handling

- Grid: `<img src={thumbUrl} loading="lazy">`; thumbnail derived from
  full URL by convention (`s/full/thumb/`)
- S3 base URL: `http://chuck.overcomingsh.in`; constructed from item
  `imageUrl` (S3 object key)

## Build & Deploy

- Build: `npm run build` (in `web/`) → `out/` directory
- Deploy: `./deploy-web.sh` syncs `out/` to S3 root, preserving
  `images/` and `lambda/` prefixes
- Env vars (set at build time):
  - `NEXT_PUBLIC_API_URL` — Lambda Function URL
  - `NEXT_PUBLIC_S3_BASE` — S3 bucket base URL
