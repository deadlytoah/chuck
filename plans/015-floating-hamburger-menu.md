# Remove AppBar, Add Floating Hamburger Menu

## Prompt

I want the AppBar removed, but want the hamburger menu icon to "hover"
over the top right corner. Record your plan.

## Plan

- Remove AppBar from `home_page.dart` Scaffold
- Add Stack wrapper around body to enable layering
- Position HamburgerMenu as floating element in top-right corner
- Update HamburgerMenu overlay positioning logic to account for
  missing AppBar (remove kToolbarHeight offset)
- Use SafeArea to respect device notches/status bar
- Add padding/margin to floating hamburger for visual spacing
- Ensure hamburger icon has proper background/elevation to stand out
  over content
