# Technical Specifications — Next.js Web App

This document is the technical spec for the Next.js web app. It maps
to the functional design in `design-web.md` (the system design spec).
For shared backend details see `technical-backend.md`; for the Flutter
iOS app see `technical.md`.

`design-web.md` defines *what* the app does and *why*. This document
defines *how* it is built: architecture, data models, API contracts,
deployment, and open questions.

## Architecture Overview

Single-page app (SPA) built as a Next.js static export. No server-side
rendering. The browser fetches static assets from S3, then calls the
Lambda REST API directly for data. All state is local to the browser
session (React state + `localStorage`).

```
Browser (iPhone Safari / desktop)
  ├── Static assets  ←  S3 (chuck.overcomingsh.in, root path)
  └── API calls      →  AWS Lambda Function URL (HTTPS)
                            └── DynamoDB (chuck-items-v2)
                            └── S3 (images/)
```

The web app is a pure consumer of the backend API; it writes no data
directly to DynamoDB or S3.

## Platform

- **Target:** iPhone Safari, iOS 16+ (375–430px viewport)
- **Desktop browsers:** not supported; may work incidentally
- **Rendering:** Client-side only; static export (`output: 'export'`)
- **Hosting OS:** N/A (static files on S3)
- **Build OS:** macOS (developer machines); Node.js 20+

## Technologies

| Technology | Choice | Rationale |
|---|---|---|
| Next.js 15 | Framework | Static export support; React ecosystem; file-based routing |
| React 19 | UI library | Hooks-based; no class components needed |
| Tailwind CSS | Styling | Utility-first; no custom build pipeline for CSS |
| TypeScript | Language | Type safety; better IDE support |
| Native `fetch` | HTTP | No extra dependency; adequate for simple REST calls |
| `localStorage` | Persistence | Folder selection only; no auth tokens to store |

**Alternatives considered:**

- *Vite + React* — simpler build, but less convention; Next.js static
  export is equally simple and better supported on S3.
- *SWR / React Query* — overkill for a single-page app with no
  background refetching or cache invalidation requirements.
- *Redux / Zustand* — no external state library; React `useState` /
  `useReducer` is sufficient for this scope.

## Data Models

All data originates from the backend API. The web app mirrors these
shapes in TypeScript.

### Folder

```ts
interface Folder {
  folderId: string;   // e.g. "entryway"
  name:     string;   // display name, e.g. "Entryway"
  createdAt: string;  // ISO 8601
}
```

### Item

```ts
type ItemState =
  "Chuck" | "Keep" | "Sell" | "Undecided" | "Unanswered";

interface Item {
  itemId:    string;     // UUID
  folderId:  string;
  imageUrl:  string;     // S3 object key for full-size image
  state:     ItemState;
  notes?:    string;
  archived:  boolean;
  createdAt: string;     // ISO 8601
  updatedAt: string;     // ISO 8601
  archivedAt?: string;
}
```

Thumbnail URL derived from `imageUrl` by convention:
`imageUrl.replace("/full", "/thumb")`.

### Pagination token

```ts
interface PageInfo {
  nextToken?: string;  // opaque; pass as query param for next page
}
```

### API response envelope

```ts
interface ApiResponse<T> {
  data:        T;
  pagination?: PageInfo;
}

interface ApiError {
  error: string;
  code:  string;
}
```

## Actors

| Actor | Description |
|---|---|
| Family member | Reviews and categorizes items on iPhone Safari |
| Backend API | AWS Lambda; source of truth for items and folders |
| S3 (images) | Serves thumbnail and full-size images |
| S3 (static) | Serves the compiled Next.js app bundle |

No authentication or user accounts. All actors share the same URL and
have identical read/write access.

## API Contracts

The web app uses a subset of the backend API (see `technical-backend.md`
for full spec). Base URL: `NEXT_PUBLIC_API_URL` (Lambda Function URL).

All requests use `fetch` with JSON bodies. CORS is handled by Lambda.

### GET /folders

Loads folder list on app init and manual refresh.

- **Request:** none
- **Response:** `{ "data": Folder[] }`

### GET /items

Loads item grid for a folder.

- **Query params:**
  - `folderId` (required)
  - `nextToken` (optional, from previous response)
  - `limit` (default 20, max 50)
  - `sort` (`createdAt` default)
  - `filter` (`Chuck` | `Keep` | `Sell` | `Undecided` | `Unanswered`
    | `archived` | `all`)
- **Response:** `{ "data": Item[], "pagination": { "nextToken"?: string } }`

### PUT /items/{id}

Updates item state. Called immediately on user selection.

- **Request body:** `{ "state": ItemState }`
- **Response:** `{ "data": Item }`

*Note:* Optimistic update applied before call; rolled back on error.

## Deployment Model

```
Developer machine
  ├── npm run build   →  web/out/  (static HTML/JS/CSS)
  └── ./deploy-web.sh →  aws s3 sync out/ s3://chuck.overcomingsh.in/
                          (preserves images/ and lambda/ prefixes)
```

- **Build tool:** Next.js (`next build`); outputs to `web/out/`
- **Hosting:** S3 static website; no CloudFront CDN
- **Env vars (set at build time):**
  - `NEXT_PUBLIC_API_URL` — Lambda Function URL
  - `NEXT_PUBLIC_S3_BASE` — S3 bucket base URL
    (`http://chuck.overcomingsh.in`)
- **Routing:** single route `/`; no sub-pages
- **Cache:** S3 default (no explicit cache headers configured)

## Component Structure

```
app/
  layout.tsx          Root layout (metadata, global CSS)
  page.tsx            Main view; composes all major components

components/
  FolderSelector.tsx  Top bar; opens folder dropdown
  ItemGrid.tsx        2-column CSS grid of ItemCard
  ItemCard.tsx        Thumbnail + state badge; manages overlay toggle
  StateOverlay.tsx    State-selection overlay over ItemCard
  ErrorBanner.tsx     Inline error with retry button
```

**Additional UI elements (inlined or in page.tsx):**
- `<Toast>` — transient success/error notifications (3s auto-dismiss)
- Full-screen backdrop div — captures outside taps to dismiss overlay

## State Management

All state managed with React `useState` / `useReducer`. No external
library.

| State | Location | Persistence |
|---|---|---|
| Folder list | `page.tsx` | In-memory; refetched on refresh |
| Selected folder | `page.tsx` | `localStorage` (`chuck.folderId`) |
| Item list | `page.tsx` | In-memory; refetched on folder change |
| Overlay open | `ItemCard.tsx` | Local `useState`; ephemeral |
| Toast message | `page.tsx` | Local `useState`; auto-cleared |

**Folder initialization priority (first visit):**

1. "Inbox" folder if it exists
2. First folder alphabetically
3. None (if no folders)

On return visits, `chuck.folderId` is restored from `localStorage`
with fallback to the above priority.

## Dependencies

**Runtime:**

| Package | Version | Purpose |
|---|---|---|
| next | 16.x | Framework |
| react | 19.x | UI library |
| react-dom | 19.x | DOM rendering |

**Dev/build:**

| Package | Purpose |
|---|---|
| typescript | Type checking |
| tailwindcss | Utility CSS |
| @types/react | React type defs |
| eslint | Linting |

**AWS services (runtime, not npm packages):**

- Lambda Function URL — REST API
- S3 `chuck.overcomingsh.in` — static hosting + image storage

No third-party UI component libraries.

## Tests

No automated tests currently. The app is small and manually tested
in iPhone Safari.

**Manual test checklist (pre-deploy):**

- Folder list loads; last-selected folder restored on reload
- Switching folders loads correct items
- Tapping card opens state overlay; tapping state updates badge
- Optimistic update visible immediately; reverts on simulated API error
- "Load More" appends items without losing scroll position
- Error banner shown on fetch failure; retry works
- Toast shown on state update failure; badge reverts
- Touch targets ≥ 44×44pt on iPhone Safari
- Works at 375px and 430px viewport widths

**Future:**

- Unit tests for state update logic and folder initialization
- E2E tests (Playwright) for the happy path on mobile viewport

## Security

- No authentication. Access controlled by keeping the URL private.
- All API calls over HTTPS (Lambda Function URL).
- No secrets stored client-side; no tokens or credentials.
- User-generated content (item notes) not rendered as HTML; no XSS
  risk from display.
- CORS configured on Lambda; allows all origins (family-use tradeoff).
- S3 bucket is public-read for static assets and images; no sensitive
  data stored.

See `design-web.md` → Security for rationale and tradeoffs.

## Open Questions

- Should the web app support state filtering (e.g., show only
  Unanswered items), consistent with the iOS app?
- Should there be a visual indicator when another user has recently
  updated an item (highlight or timestamp)?
- Should error toasts include a manual retry action for state update
  failures, or is rollback + re-tap sufficient?
- Should S3 cache headers be set explicitly to improve repeat-visit
  performance?
