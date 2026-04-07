# 039 — Web FolderSelector: Bottom Sheet → Dropdown

## Context

The web `FolderSelector` currently opens a full-screen
`FolderBottomSheet` (slide-up modal with backdrop). The goal is to
replace this with an inline dropdown anchored below the trigger
button. The plan is broken into 4 micro-tasks sized for Claude Haiku.

### Relevant files

- `web/components/FolderSelector.tsx` (lines 1–44): trigger button,
  `showSheet` state, renders `<FolderBottomSheet>` conditionally.
- `web/components/FolderBottomSheet.tsx` (lines 1–89): fixed backdrop,
  slide-up sheet, folder list, close button. To be deleted.

---

## Micro-Task 1: CSS / Positioning

- Wrap component in `relative` div (replaces `sticky top-0 z-10`).
- Dropdown panel: `absolute top-full left-0 right-0 z-50`
  `bg-white dark:bg-gray-800`
  `border border-gray-200 dark:border-gray-700 rounded-b-lg shadow-lg`
  `max-h-60 overflow-y-auto`
- Trigger button: add `flex items-center justify-between`; add
  chevron `<svg>` that applies `rotate-180` when open.
- Remove `FolderBottomSheet` import.
- **File:** `web/components/FolderSelector.tsx` only.

---

## Micro-Task 2: Toggle Logic

- Rename `showSheet` → `isOpen`.
- Trigger `onClick`: `setIsOpen(prev => !prev)` (toggle).
- `handleSelect(folderId)`: call `onSelect(folderId)`, then
  `setIsOpen(false)`.
- Render dropdown: `{isOpen && <div ...>...</div>}` inline.
- Map `folders` inline (port list from `FolderBottomSheet`).
- Selected item: `bg-blue-50 font-semibold text-blue-600`.
- **Delete:** `web/components/FolderBottomSheet.tsx`.

---

## Micro-Task 3: Event Listeners (Click-Away)

- Add `containerRef = useRef<HTMLDivElement>(null)` on wrapper div.
- Click-away effect (guard on `isOpen`):
  ```ts
  useEffect(() => {
    if (!isOpen) return
    const handler = (e: MouseEvent) => {
      if (!containerRef.current?.contains(e.target as Node))
        setIsOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [isOpen])
  ```
- Escape key effect (guard on `isOpen`):
  ```ts
  useEffect(() => {
    if (!isOpen) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setIsOpen(false)
    }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [isOpen])
  ```

---

## Micro-Task 4: Accessibility (ARIA)

**Trigger button attrs:**
```tsx
aria-haspopup="listbox"
aria-expanded={isOpen}
aria-controls="folder-listbox"
id="folder-selector-btn"
```

**Dropdown list:**
```tsx
<ul role="listbox" id="folder-listbox"
    aria-labelledby="folder-selector-btn">
```

**Each item:**
```tsx
<li role="option" aria-selected={selectedFolderId === folder.folderId}>
  <button ...>{folder.name}</button>
</li>
```

**Focus management:**
- On open: focus first `<button>` inside listbox via `useEffect` +
  `listboxRef.current?.querySelector('button')?.focus()`.
- On close: return focus to trigger via `triggerRef.current?.focus()`.

**Keyboard nav on `<ul>` `onKeyDown`:**
- `ArrowDown` / `ArrowUp`: move focus between items using
  `querySelectorAll('button')` + index arithmetic.
- `Enter` / `Space`: select focused item.

---

## File Changes Summary

| File | Action |
|------|--------|
| `web/components/FolderSelector.tsx` | Rewrite |
| `web/components/FolderBottomSheet.tsx` | Delete |
