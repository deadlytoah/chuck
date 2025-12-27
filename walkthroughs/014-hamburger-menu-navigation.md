# Hamburger Menu Navigation Walkthrough

I have replaced the TabBar navigation with a hamburger menu in the top-right corner.

## Changes

### `src/lib/widgets/hamburger_menu.dart`
- Created `HamburgerMenu` widget.
- Implemented `AnimatedIcon` for the menu button (hamburger <-> close).
- Implemented overlay menu with semi-transparent backdrop.
- Added "Home" and "Admin" navigation items.
- Implemented auto-close on selection and backdrop tap.

### `src/lib/screens/home_page.dart`
- Removed `TabController` and `TabBar`.
- Added `AppBar` with `HamburgerMenu`.
- Implemented state-based screen switching using `IndexedStack`.

### `src/test/hamburger_menu_test.dart`
- Added widget tests for `HamburgerMenu`.
- Verified rendering, menu opening, and item selection.

### `src/test/widget_test.dart` & `src/test/unit_test.dart`
- Updated imports to use correct package name `chuck`.
- Verified that existing tests pass.

## Verification Results

### Automated Tests
Ran `flutter test` and all tests passed:
- `hamburger_menu_test.dart`: Verified menu interaction.
- `widget_test.dart`: Verified AdminPage rendering.
- `unit_test.dart`: Verified Item model parsing.

```
00:07 +15: ... passed!
```
