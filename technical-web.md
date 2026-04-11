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
  ├── Static assets  →  CloudFront (custom domain, HTTPS)
  │                         └── S3 origin (private; OAC only)
  ├── Images         →  CloudFront (same distribution, /images/*)
  │                         └── S3 origin (private; OAC only)
  └── API calls      →  AWS Lambda Function URL (HTTPS)
                            └── DynamoDB (chuck-items-v2)
                            └── S3 (images/)
```

The web app is a pure consumer of the backend API; it writes no data
directly to DynamoDB or S3. CloudFront sits in front of S3 for both
static assets and images; the S3 bucket has no public-read ACL.

## Platform

- **Target:** iPhone Safari, iOS 16+ (375–430px viewport)
- **Desktop browsers:** not supported; may work incidentally
- **Rendering:** Client-side only; static export (`output: 'export'`)
- **Hosting:** CloudFront → S3 (private); no direct S3 website URL
- **TLS:** ACM certificate for the custom domain
  (provisioned in `us-east-1`; required by CloudFront)
- **DNS:** Route 53 alias record → CloudFront distribution
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
  ├── npm run build    →  web/out/  (static HTML/JS/CSS)
  └── ./deploy-web.sh  →  aws s3 sync out/ s3://<bucket>/
                           (preserves images/ and lambda/ prefixes)
                        →  aws cloudfront create-invalidation \
                             --paths "/*"
```

- **Build tool:** Next.js (`next build`); outputs to `web/out/`
- **Hosting:** S3 (private) behind CloudFront distribution
- **CDN:** CloudFront; PriceClass_100 (US/EU/Asia); default TTL
  86400s for static assets; `/*.html` TTL 0 (always revalidate)
- **TLS termination:** CloudFront; ACM cert in `us-east-1`
- **S3 access:** Origin Access Control (OAC); bucket policy grants
  `s3:GetObject` to the CloudFront distribution only; S3 static
  website hosting disabled
- **DNS:** Route 53 A/AAAA alias records for the custom
  domain → CloudFront distribution domain
- **Env vars (set at build time):**
  - `NEXT_PUBLIC_API_URL` — Lambda Function URL
  - `NEXT_PUBLIC_S3_BASE` — HTTPS URL of the CloudFront
    distribution (replaces former HTTP S3 URL)
- **Routing:** single route `/`; CloudFront default root object
  set to `index.html`; custom error response 403/404 → `/index.html`
  (SPA fallback); `?folder=` query param is passed through unchanged
  by CloudFront and read by the SPA on load
- **Cache key:** CloudFront cache policy for the `/` route excludes
  all query parameters; `?folder=` does not fragment the cache
- **Cache invalidation:** `deploy-web.sh` runs after each sync to
  invalidate `/*`; first 1000 invalidations/mo free

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
| Selected folder | URL `?folder=` + `page.tsx` | URL (primary); `localStorage` fallback |
| Item list | `page.tsx` | In-memory; refetched on folder change |
| Overlay open | `ItemCard.tsx` | Local `useState`; ephemeral |
| Toast message | `page.tsx` | Local `useState`; auto-cleared |

## URL Structure

The selected folder is encoded in the URL query parameter:

```
/?folder=<folderId>
```

Example: `https://chuck.example.com/?folder=entryway`

- No path segments used; the app is a single route `/`.
- Hash (`#`) is avoided; query params are copied into bookmarks and
  shared links naturally.
- Changing the folder calls `history.replaceState()` (or
  `router.replace()`) to update `?folder=` in place without pushing
  a new browser history entry. The back button is unaffected.
- On every folder change the URL is written first, then
  `localStorage` key `chuck.folderId` is written. Both writes occur
  on every folder change without exception; they are never split
  across separate code paths.

**Folder initialization priority (on page load):**

1. `?folder=<folderId>` query param, if `folderId` matches a folder
   returned by `GET /folders`
2. `chuck.folderId` from `localStorage`, if it matches a known folder
3. "Inbox" folder if it exists
4. First folder alphabetically
5. None (if `GET /folders` returns an empty list)

If `?folder=` is present but does not match any known folder (deleted
or mistyped), a toast notice is shown ("Folder not found; showing
[folder name]", 3s auto-dismiss) and priority falls to step 2.

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
- S3 (static hosting bucket) — private; static assets +
  image storage; accessed only via CloudFront OAC
- CloudFront — HTTPS CDN; TLS termination; serves static assets
  and images
- ACM — TLS certificate for the custom domain
  (must be provisioned in `us-east-1`)
- Route 53 — DNS alias records pointing to CloudFront

No third-party UI component libraries.

## Tests

**Manual test checklist (pre-deploy):**

- Folder list loads; last-selected folder restored on reload
- Switching folders updates URL (`?folder=`) and loads correct items
- Opening `/?folder=<id>` directly loads the correct folder
- Invalid `?folder=` value falls back gracefully to default folder
- Folder list loads; last-selected folder restored on reload
- Tapping card opens state overlay; tapping state updates badge
- Optimistic update visible immediately; reverts on simulated API error
- "Load More" appends items without losing scroll position
- Error banner shown on fetch failure; retry works
- Toast shown on state update failure; badge reverts
- Touch targets ≥ 44×44pt on iPhone Safari
- Works at 375px and 430px viewport widths

**E2E Tests (Playwright)**

*Purpose & Scope*

Automated browser tests (Chromium) covering the core user flows:
initial load and folder auto-selection, folder switching, pagination
via "Load More", state change with optimistic update and rollback on
server error, and API error banner display with retry. All API calls
are intercepted with `page.route()` — no real backend or AWS
credentials needed.

Test files in `web/e2e/tests/` (7 tests across 5 files):

- `init.spec.ts` — auto-selects Inbox, shows items
- `folder-switch.spec.ts` — switching folder replaces item list
- `pagination.spec.ts` — Load More appends items
- `error.spec.ts` — folder/item fetch errors show banner; retry
  clears banner and reloads items
- `state-change.spec.ts` — state change updates badge; PUT 500
  reverts badge and shows error banner

*Prerequisites*

- Node.js and `npm install` completed in `web/`
- Playwright browser installed: `npx playwright install chromium`
- No backend required; routes mocked via `e2e/helpers/routes.ts`

*Run Commands*

```bash
# From web/
npm run test:e2e        # headless, list reporter
npm run test:e2e:ui     # interactive Playwright UI
```

Playwright auto-starts `npm run dev` on port 3000 if not already
running (`reuseExistingServer: true` by default). Set `CI=true` to
force a fresh dev server on each run.

*Expected Output*

All 7 tests pass. Reporter: `list` (one line per test). Traces are
saved to `web/test-results/` only on failure (`retain-on-failure`).

*Troubleshooting*

- `browserType.launch: Executable doesn't exist` — run
  `npx playwright install chromium`
- Port 3000 conflict — kill the conflicting process, or set `CI=true`
  to prevent server reuse
- Overlay assertion fails — `.overlay-open` must be visible before
  interacting; increase default timeout if running on a slow machine

**Future:**

- Unit tests for state update logic and folder initialization

## Security

- No authentication. Access controlled by keeping the URL private.
- Static assets and images served over HTTPS via CloudFront; S3
  bucket is private (no public-read ACL or static website endpoint).
- CloudFront OAC restricts S3 access to the distribution only.
- All API calls over HTTPS via the Lambda Function URL.
- No secrets stored client-side; no tokens or credentials.
- User-generated content (item notes) not rendered as HTML; no XSS
  risk from display.
- CORS on Lambda: update allowed origin from the plain HTTP S3
  URL to the CloudFront HTTPS origin.

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
