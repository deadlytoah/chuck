# Floating Hamburger Menu Walkthrough

I have removed the AppBar and implemented a floating hamburger menu in the top-right corner.

## Changes

### `src/lib/screens/home_page.dart`

- Removed `Scaffold.appBar`.
- Wrapped `Scaffold.body` in a `Stack`.
- Added `HamburgerMenu` as a `Positioned` widget in the top-right corner.
- Wrapped `HamburgerMenu` in `SafeArea`, `Padding`, and `Material` for proper positioning and visual styling (elevation, background).

### `src/lib/widgets/hamburger_menu.dart`

- Updated `_createOverlayEntry` to position the menu relative to the floating icon using `CompositedTransformFollower` with an adjusted offset.
- Removed manual `top`/`right` positioning that relied on `kToolbarHeight`.

## Verification

The application should now display the content full-screen without an AppBar. The hamburger menu icon should appear floating in the top-right corner. Tapping it should open the menu positioned correctly relative to the icon.
