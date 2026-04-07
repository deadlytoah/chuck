# Plan 042 — Item State Overlay

## Chat Summary

User wants to implement the new item state UI as specified in the
unstaged design changes: replace the context-menu approach with a
full-card tap overlay that lists available state transitions.

## Relevant Design Changes

### design-web.md (new spec)
- Tapping a card reveals a full-card overlay listing states the item
  can transition to (current state excluded).
- States: Chuck, Keep, Sell, Undecided, Unanswered (up to 4 shown).
- Overlay: state labels stacked vertically, centered, over semi-
  transparent dark background.
- Tapping a state applies it immediately; overlay dismisses.
- Tapping outside the card dismisses without changes.
- State change sent via `PUT /items/{id}`; optimistic update on badge.

### technical-web.md (new spec)
- `<ItemCard>` — thumbnail + state badge; tap toggles state overlay.
- `<StateOverlay>` — `position: absolute; inset: 0` over `<ItemCard>`;
  semi-transparent dark bg; vertically stacked state buttons (min 44pt
  touch target each); excludes current state; toggled via local
  `useState` in `<ItemCard>`; dismissed by full-screen transparent
  backdrop div rendered below overlay, above grid, capturing outside
  taps.
- No `<StateContextMenu>` component (was never created).

## Source Excerpts

- `web/components/ItemCard.tsx`:15 — `stateColors` record; current
  states are Keep/Discard/Archive/Review (to be replaced with
  Chuck/Keep/Sell/Undecided/Unanswered).
- `web/components/ItemGrid.tsx`:30 — renders `<ItemCard>` with no
  state-update callback; needs `onStateChange` prop.
- `web/app/page.tsx`:135 — renders `<ItemGrid>`; owns item list state;
  must pass `onStateChange` handler and render backdrop.
- `web/lib/api.ts` — no `updateItem` function yet; needs adding.
- `web/types/index.ts`:12 — `Item.state: string`; no state enum yet.

## Implementation Plan

### 1. Add `updateItem` to `web/lib/api.ts`
- Add `export async function updateItem(itemId: string, state: string):
  Promise<Item>` calling `PUT ${getApiUrl()}/items/${itemId}` with
  `Content-Type: application/json` body `{ state }`.
- Return parsed `Item` JSON.

### 2. Add `ITEM_STATES` constant to `web/types/index.ts`
- `export const ITEM_STATES = ['Chuck','Keep','Sell','Undecided',
  'Unanswered'] as const`
- `export type ItemState = typeof ITEM_STATES[number]`

### 3. Create `web/components/StateOverlay.tsx`
- Props: `currentState: string`, `onSelect: (state: string) => void`.
- Render `position: absolute; inset: 0; z-index: 10` div with
  `bg-black/60` (semi-transparent dark).
- Inside: `flex flex-col items-center justify-center gap-2`.
- For each state in `ITEM_STATES` where `state !== currentState`,
  render a `<button>` with:
  - `min-h-[44px] w-full px-4 text-white font-semibold text-sm`
  - `active:bg-white/20` for touch feedback.
  - `onClick={() => onSelect(state)`.
- Stop propagation on the overlay container click so it doesn't bubble
  to card (the card's own click opens overlay; overlay click on a
  button closes it; outside click is handled by backdrop).

### 4. Update `web/components/ItemCard.tsx`
- Add `onStateChange: (itemId: string, newState: string) => void` to
  `ItemCardProps`.
- Add local state: `const [overlayOpen, setOverlayOpen] = useState(false)`.
- Update `stateColors` map keys to: Chuck, Keep, Sell, Undecided,
  Unanswered (remove Keep/Discard/Archive/Review).
- Wrap card in `position: relative` container.
- Card `onClick`: toggle `setOverlayOpen(true)` (if not already open).
- When `overlayOpen`, render `<StateOverlay>` inside the card container.
- `onSelect` handler:
  1. `setOverlayOpen(false)`
  2. call `onStateChange(item.itemId, newState)`
- Pass `e.stopPropagation()` on card click to prevent backdrop
  triggering simultaneously.

### 5. Update `web/components/ItemGrid.tsx`
- Add `onStateChange: (itemId: string, newState: string) => void` to
  `ItemGridProps`.
- Pass it down to each `<ItemCard>`.

### 6. Update `web/app/page.tsx`
- Add `handleStateChange` async function:
  1. Optimistically update `items` state: replace matching item's
     `state` field.
  2. Call `updateItem(itemId, newState)`.
  3. On error: revert optimistic update, set `error` message.
- Add backdrop state: `const [overlayOpen, setOverlayOpen] =
  useState(false)` — actually delegate to a simpler approach:
  render a full-screen transparent div (fixed, inset-0, z-index 5)
  **only when** any card has its overlay open. Since overlay state
  lives in `ItemCard`, lift it: add `openCardId: string | null` state
  to `page.tsx` and pass `setOpenCardId` down so the backdrop can be
  rendered at page level.
  - Add `openCardId` / `setOpenCardId` props to `ItemGrid` and
    `ItemCard`.
  - Render backdrop `<div>` in `page.tsx` `main` when `openCardId !==
    null`: `fixed inset-0 z-[5]` transparent, `onClick:
    () => setOpenCardId(null)`.
- Pass `onStateChange={handleStateChange}` to `<ItemGrid>`.

### 7. Prop threading for `openCardId`
- `ItemCard` props: add `isOpen: boolean`, `onOpen: () => void`,
  `onClose: () => void`.
- Replace local `overlayOpen` useState with `isOpen` prop.
- Card click calls `onOpen()`; overlay select calls `onClose()` then
  `onStateChange`.
- `ItemGrid` props: add `openCardId`, `setOpenCardId`.
- In `ItemGrid` map: pass `isOpen={openCardId === item.itemId}`,
  `onOpen={() => setOpenCardId(item.itemId)}`,
  `onClose={() => setOpenCardId(null)}`.

### Summary of Files Changed
| File | Change |
|---|---|
| `web/lib/api.ts` | Add `updateItem` |
| `web/types/index.ts` | Add `ITEM_STATES`, `ItemState` |
| `web/components/StateOverlay.tsx` | New component |
| `web/components/ItemCard.tsx` | Add overlay, new props, update colors |
| `web/components/ItemGrid.tsx` | Thread `openCardId`/`onStateChange` |
| `web/app/page.tsx` | Add backdrop, `openCardId` state, `handleStateChange` |
