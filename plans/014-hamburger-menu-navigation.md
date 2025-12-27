# Hamburger Menu Navigation

Replace TabBar navigation with hamburger menu in top-right corner.

## Prompt

I would like a hamburger menu at the top right corner, which would
replace the tap bar. So the hamburger menu would include links for
home and admin screens. When activated, the menu would be a small
sized overlay menu that fades with a backdrop. Menu items would be
simple text links with icons, and the current screen would be
highlighted with an accent color. After selecting a screen, the menu
would auto-close. The hamburger icon would animate to an 'X' when the
menu is open, which can be clicked to close the menu.

## Changes

### Navigation Structure

- Remove TabBar and TabController from `home_page.dart`
- Replace TabBarView with direct screen rendering based on state
- Add state management for current screen selection
- Remove SingleTickerProviderStateMixin (no longer needed)

### Hamburger Menu Widget

Create `widgets/hamburger_menu.dart`:
- AnimatedIcon widget for hamburger-to-X animation
- Overlay menu with backdrop (semi-transparent black)
- Menu positioned in top-right area (small overlay)
- Two menu items: Home (MainView) and Admin (AdminPage)
- Icons: home icon and admin/settings icon
- Current screen highlighted with accent color
- Auto-close on item selection
- Close on backdrop tap or X icon tap

### AppBar Integration

Update `home_page.dart`:
- Add AppBar with hamburger icon button in top-right (actions)
- Handle menu open/close state
- Manage overlay visibility
- Track current screen selection

### Visual Design

- Backdrop: semi-transparent black overlay (0.5 opacity)
- Menu: compact card/container in top-right
- Fade-in animation for menu and backdrop
- Menu items: icon + text label in row layout
- Accent color: use theme's primary color for highlight
- Padding and spacing for touch-friendly targets

## Implementation Steps

1. Create `widgets/hamburger_menu.dart` with menu overlay widget
2. Update `home_page.dart`:
   - Remove TabController and tab-related code
   - Add state for current screen and menu visibility
   - Add AppBar with hamburger button
   - Implement screen switching logic
   - Wire up menu callbacks
3. Test navigation flow and animations
4. Verify auto-close behavior
5. Verify current screen highlighting
