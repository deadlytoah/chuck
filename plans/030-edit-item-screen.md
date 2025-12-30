# Plan 030: Convert Edit Item Dialog to Screen

## User Prompt
"Edit Item dialog isn't quite big enough to show all of its elements.
But then maybe it should have its own screen, instead of being a
dialog. Can you update the docs appropriately, being careful not to
introduce redundancies, to specify this?"

"Generate a plan to implement this change."

## Objective
Convert Edit Item dialog (_EditItemDialog) to a dedicated screen
(EditItemScreen) to provide adequate space for all UI elements and
better UX.

## Implementation Steps

### 1. Create Edit Item Screen File
- Create `src/lib/screens/edit_item_screen.dart`
- Move `_EditItemDialog` and `_EditItemDialogState` from item_card.dart
- Rename to `EditItemScreen` and `_EditItemScreenState`
- Convert from ConsumerStatefulWidget extending dialog to screen

### 2. Update Screen Layout
- Replace `CupertinoAlertDialog` with `CupertinoPageScaffold`
- Add `CupertinoNavigationBar` with:
  - Title: "Edit Item"
  - Leading: back button (automatic with CupertinoPageRoute)
  - Trailing: Save button (replaces dialog action)
- Add body with `SafeArea` and `SingleChildScrollView`
- Remove dialog actions section (Cancel/Save buttons)

### 3. Reorganize Content Layout
- Full-width image display (not constrained by dialog)
- State picker section (if not archived)
- Notes TextField with expanded height (5-8 lines instead of 3)
- Unarchive button (if archived) at bottom
- Add proper spacing and padding for screen layout

### 4. Update Navigation in ItemCard
- Replace `_showEditDialog` with `_navigateToEditScreen` in
  item_card.dart:222
- Change from `showCupertinoDialog` to `Navigator.push`
- Use `CupertinoPageRoute` for iOS-style transition
- Update onTap handler in item_card.dart:67

### 5. Update Save Behavior
- Change Save button from dialog action to trailing nav bar button
- Keep same update logic (call itemsProvider.notifier.updateItem)
- Navigator.pop on success
- Show error dialog on failure (same as current)

### 6. Handle Screen State
- Maintain TextEditingController lifecycle
- Maintain selectedState tracking
- Keep same dispose pattern for controller

### 7. Update Tests
- Update any tests that reference _EditItemDialog
- Add navigation tests for EditItemScreen
- Test back button behavior
- Test save button in nav bar

### 8. Clean Up
- Remove _EditItemDialog class from item_card.dart (lines 271-489)
- Add import for edit_item_screen.dart in item_card.dart
- Ensure _StateChip remains in item_card.dart (shared widget)

## Files to Create

### New
- `src/lib/screens/edit_item_screen.dart` - New screen implementation

## Files to Modify

### Core Widget
- `src/lib/widgets/item_card.dart` (lines 222-227, 271-489)
  - Update navigation method
  - Remove dialog widget class

### Tests (if applicable)
- Search for tests referencing _EditItemDialog
- Update to work with screen navigation

## Key Excerpts

### item_card.dart:222-227 (Current Dialog Navigation)
```dart
void _showEditDialog(BuildContext context, WidgetRef ref) {
  showCupertinoDialog(
    context: context,
    builder: (context) => _EditItemDialog(item: widget.item),
  );
}
```
→ Replace with screen navigation using Navigator.push

### item_card.dart:271-489 (Dialog Widget)
```dart
class _EditItemDialog extends ConsumerStatefulWidget {
  final Item item;
  const _EditItemDialog({required this.item});
  @override
  ConsumerState<_EditItemDialog> createState() =>
_EditItemDialogState();
}

class _EditItemDialogState extends ConsumerState<_EditItemDialog> {
  late String selectedState;
  late TextEditingController commentController;
  // ... state management and build method
}
```
→ Move to edit_item_screen.dart and convert to screen layout

### item_card.dart:303-393 (Dialog Layout)
```dart
return CupertinoAlertDialog(
  title: const Text('Edit Item'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),
      ClipRRect(...),  // Image
      // State picker
      // Notes field
      // Unarchive button
    ],
  ),
  actions: [
    CupertinoDialogAction(...),  // Cancel
    CupertinoDialogAction(...),  // Save
  ],
);
```
→ Convert to CupertinoPageScaffold with navigation bar

## Screen Layout Design

```
┌─────────────────────────────────┐
│ ← Edit Item           [Save]    │ CupertinoNavigationBar
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │    Full-Size Image      │   │ Larger image display
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  State                          │
│  ┌─────────────────────────┐   │
│  │ Keep              ▼     │   │ State picker
│  └─────────────────────────┘   │
│                                 │
│  Notes                          │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │                         │   │
│  │  Multi-line notes       │   │ 5-8 lines
│  │  text field             │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  [    Unarchive    ]           │ (if archived)
│                                 │
└─────────────────────────────────┘
```

## Benefits
- More space for full-size image viewing
- Larger notes TextField (5-8 lines vs 3)
- Standard iOS navigation pattern
- Better scrolling for long notes
- Clearer visual hierarchy
- Matches "Edit Item Screen" in updated docs

## Risks & Considerations
- Navigation adds slight delay vs instant dialog
- Need to handle back button (auto-save vs discard changes?)
- Current implementation: no confirmation on cancel
- Recommendation: keep same behavior (discard on back, save on
  Save button)

## Success Criteria
- Tapping item card navigates to Edit Item Screen
- Screen shows full-size image
- State picker works for non-archived items
- Notes field has more lines (5-8)
- Save button updates item and returns to previous screen
- Back button discards changes and returns
- Unarchive button works for archived items
- All existing functionality preserved
