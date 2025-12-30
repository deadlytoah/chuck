# Plan 029: Cupertino UI Redesign

## User Prompt
"Can we use cupertino widgets to make the UI look more apple?"
"Generate a plan first"

## Objective
Convert app from Material Design to Cupertino (iOS-style) widgets
for native Apple look and feel.

## Implementation Steps

### 1. Update Main App (main.dart:14)
- Replace `MaterialApp` with `CupertinoApp`
- Remove Material theme configuration
- Add Cupertino theme if needed
- Update primary color scheme

### 2. Convert Core Navigation (home_page.dart)
- Replace `Scaffold` with `CupertinoPageScaffold`
- Replace `FloatingActionButton` with positioned `CupertinoButton`
- Update navigation transitions to `CupertinoPageRoute`
- Convert hamburger menu to iOS-style presentation

### 3. Convert Item Card (item_card.dart)
- Replace `Card` with custom container using iOS shadows
- Replace `Chip` with custom iOS-style badge widget
- Replace `AlertDialog` with `CupertinoAlertDialog`
- Replace `TextField` with `CupertinoTextField`
- Replace `DropdownButtonFormField` with `CupertinoPicker`
- Update button styles to `CupertinoButton`

### 4. Convert Camera Screen (camera_screen.dart)
- Replace `Scaffold` with `CupertinoPageScaffold`
- Replace `CircularProgressIndicator` with
  `CupertinoActivityIndicator`
- Replace `AlertDialog` with `CupertinoAlertDialog`
- Replace `IconButton` with `CupertinoButton`
- Update back button to iOS chevron style

### 5. Convert Other Screens
- main_view.dart: Scaffold → CupertinoPageScaffold
- admin_page.dart: Scaffold → CupertinoPageScaffold
- queue_review_screen.dart: Material widgets → Cupertino

### 6. Convert Widgets
- hamburger_menu.dart: Update to iOS-style menu
- queue_status_button.dart: Convert to CupertinoButton
- failed_upload_banner.dart: Update styling
- filter_bar.dart: Convert to Cupertino tabs/segmented control
- bulk_actions.dart: Update button styles
- upload_zone.dart: Update styling
- items_grid.dart: Verify grid works with Cupertino

### 7. Update Icons
- Replace Material Icons with Cupertino icons
- Icons.camera_alt → CupertinoIcons.camera
- Icons.archive → CupertinoIcons.archivebox
- Icons.arrow_back → CupertinoIcons.back
- Icons.broken_image → CupertinoIcons.photo

### 8. Navigation Transitions
- Replace all `MaterialPageRoute` with `CupertinoPageRoute`
- Update Navigator.push calls throughout codebase

### 9. Typography & Colors
- Update text styles to iOS typography
- Adjust color scheme to iOS standards
- Remove Material elevation, use iOS shadows

### 10. Testing
- Test all screens render correctly
- Verify navigation transitions work
- Test dialogs and pickers
- Verify camera functionality
- Test on iOS simulator/device

## Files to Modify

### Core
- src/lib/main.dart (lines 1-23)
- src/lib/screens/home_page.dart (lines 1-109)
- src/lib/screens/camera_screen.dart (lines 1-286)

### Screens
- src/lib/screens/main_view.dart
- src/lib/screens/admin_page.dart
- src/lib/screens/queue_review_screen.dart

### Widgets
- src/lib/widgets/item_card.dart (lines 1-378)
- src/lib/widgets/hamburger_menu.dart
- src/lib/widgets/queue_status_button.dart
- src/lib/widgets/failed_upload_banner.dart
- src/lib/widgets/filter_bar.dart
- src/lib/widgets/bulk_actions.dart
- src/lib/widgets/upload_zone.dart

## Dependencies
- Existing: flutter/cupertino.dart (already available)
- No new packages required
- Remove/reduce Material dependencies where possible

## Key Excerpts

### main.dart:14-21
```dart
return MaterialApp(
  title: 'Chuck',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  ),
  home: const HomePage(),
);
```
→ Convert to CupertinoApp

### home_page.dart:46-76
```dart
return Scaffold(
  body: Stack(...),
  floatingActionButton: _selectedIndex == 0
      ? Row(...)
      : null,
);
```
→ Convert to CupertinoPageScaffold with positioned buttons

### item_card.dart:49-133
```dart
return Card(
  clipBehavior: Clip.antiAlias,
  child: InkWell(...),
);
```
→ Replace with iOS-styled container

### item_card.dart:255-315
```dart
return AlertDialog(
  title: const Text('Edit Item'),
  content: SingleChildScrollView(...),
  actions: [...],
);
```
→ Convert to CupertinoAlertDialog

## Risks & Considerations
- Android users will see iOS UI (acceptable for this app)
- Some Material widgets have no direct Cupertino equivalent
- Custom widgets needed for certain components
- May need platform checks if supporting both styles later

## Success Criteria
- All screens use Cupertino widgets
- Navigation uses iOS-style transitions
- Dialogs use Cupertino style
- Icons use CupertinoIcons
- App feels native on iOS
