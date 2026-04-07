# Plan 041: Move Refresh Button into FolderSelector Toolbar

## Context

The refresh button in `ItemGrid` sits in a `flex justify-end` row
with nothing on the left, wasting vertical space. Moving refresh
into `FolderSelector`'s toolbar row eliminates that dedicated row
and co-locates the action with the thing it refreshes.

## Relevant Files

- `components/FolderSelector.tsx` L6–10 (props interface),
  L91–118 (trigger button JSX — this is where refresh goes)
- `components/ItemGrid.tsx` L6–11 (props interface), L31–51
  (refresh button row to remove)
- `app/page.tsx` L125–140 (passes `onRefresh` to `ItemGrid`,
  will move it to `FolderSelector`)

---

## Steps

### 1. Update `FolderSelectorProps` interface
File: `components/FolderSelector.tsx`, lines 6–10

Add one optional prop after `onSelect`:

```ts
onRefresh?: () => void
```

### 2. Destructure `onRefresh` in `FolderSelector` function signature
File: `components/FolderSelector.tsx`, line 12–16

Add `onRefresh` to the destructured props alongside `folders`,
`selectedFolderId`, `onSelect`.

### 3. Add refresh button inside the trigger button row
File: `components/FolderSelector.tsx`, lines 91–118

The trigger `<button>` currently contains two children:
`<span>{displayName}</span>` and the chevron `<svg>`.

Replace that `<button>` with a `<div>` (same classes, same
`ref={containerRef}` already exists on outer div — keep it). The
div becomes a flex row with three children:

```
[folder trigger button] [flex-1 spacer] [refresh button]
```

**Folder trigger button** — a `<button>` with:
- `ref={triggerRef}`
- `onClick={() => setIsOpen(prev => !prev)}`
- classes: `flex-1 min-h-[44px] px-4 py-3 text-left bg-gray-50
  hover:bg-gray-100 dark:bg-gray-800 dark:hover:bg-gray-700
  font-medium text-gray-900 dark:text-gray-100 flex items-center
  gap-2`
- `aria-haspopup="listbox"`, `aria-expanded={isOpen}`,
  `aria-controls="folder-listbox"`, `id="folder-selector-btn"`
- Children: `<span>{displayName}</span>` + chevron `<svg>`
  (unchanged)

**Refresh button** — a `<button>` rendered only when
`onRefresh` is defined:

```tsx
{onRefresh && (
  <button
    onClick={(e) => { e.stopPropagation(); onRefresh() }}
    className="min-h-[44px] px-3 flex items-center justify-center
      hover:bg-gray-100 dark:hover:bg-gray-700 border-l
      border-gray-200 dark:border-gray-700"
    aria-label="Refresh"
    type="button"
  >
    <svg className="w-5 h-5" fill="none" stroke="currentColor"
      viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round"
        strokeWidth={2}
        d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0
          0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357
          2H15" />
    </svg>
  </button>
)}
```

The outer wrapper replacing the old `<button>` trigger:

```tsx
<div className="flex border-b border-gray-200 dark:border-gray-700
  bg-gray-50 dark:bg-gray-800">
  ...folder button...
  ...refresh button...
</div>
```

Note: `e.stopPropagation()` prevents the refresh click from
toggling the dropdown.

### 4. Remove the refresh toolbar row from `ItemGrid`
File: `components/ItemGrid.tsx`, lines 31–51

Delete the entire `<div className="flex justify-end ...">` block
containing the refresh `<button>` and its `<svg>`.

Remove `onRefresh` from `ItemGridProps` interface (lines 11).
Remove `onRefresh` from the function destructuring (line 19).

### 5. Update `page.tsx` — move `onRefresh` prop
File: `app/page.tsx`, lines 125–140

- Remove `onRefresh={handleRefresh}` from `<ItemGrid>`.
- Add `onRefresh={handleRefresh}` to `<FolderSelector>`.

### 6. Verify TypeScript compiles
Run: `cd web && npx tsc --noEmit`

Fix any type errors before continuing.

### 7. Run Prettier
Run: `cd web && npx prettier --write components/FolderSelector.tsx
components/ItemGrid.tsx app/page.tsx`

Fix any formatting issues Prettier reports.

### 8. Run eclint
Run: `cd web && npx eclint fix components/FolderSelector.tsx
components/ItemGrid.tsx app/page.tsx`

Fix any EditorConfig violations eclint reports.

---

## Expected Result

- `FolderSelector` renders a single toolbar row: folder name +
  chevron on the left, refresh icon button on the right, separated
  by a vertical border.
- `ItemGrid` no longer has a dedicated refresh row; the grid starts
  immediately after the folder selector.
- Blank space above the grid is eliminated.
- Behaviour is unchanged: clicking refresh reloads the current
  folder's items.
