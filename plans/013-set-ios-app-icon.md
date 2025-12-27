# Plan: Set iOS App Icon

## Prompt

```
I'd like to set the iOS app's icon to @[src/icon.jpeg]. Record your
plan to set the icon for the iOS app in `./src`.
```

## Source File

- `src/icon.jpeg`: JPEG image, 1024x1024, baseline precision 8

## Current State

iOS app icons stored in
`src/ios/Runner/Assets.xcassets/AppIcon.appiconset/`:
- `Contents.json`: defines required icon sizes for iPhone/iPad
- 15 PNG files: various sizes (20x20 to 1024x1024) at different scales

## Approach: flutter_launcher_icons Package

Automated generation of all required icon sizes using
`flutter_launcher_icons` package. This makes future icon updates
straightforward.

**Benefits**:
- Automated generation of all 15 required icon sizes
- Standard Flutter solution
- Easy to update icon in future (just change image_path and rerun)
- Handles iPhone, iPad, and App Store icons

## Implementation Steps

1. Add to `pubspec.yaml` dev_dependencies:
   ```yaml
   flutter_launcher_icons: ^0.14.2
   ```

2. Add configuration to `pubspec.yaml`:
   ```yaml
   flutter_launcher_icons:
     ios: true
     image_path: "icon.jpeg"
   ```

3. Run commands:
   ```bash
   cd src
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

4. Verify generated icons in
   `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

5. Rebuild iOS app:
   ```bash
   flutter clean
   flutter build ios
   ```

## Required Icon Sizes (from Contents.json)

- iPhone: 20x20@2x, 20x20@3x, 29x29@1x/2x/3x, 40x40@2x/3x,
  60x60@2x/3x
- iPad: 20x20@1x/2x, 29x29@1x/2x, 40x40@1x/2x, 76x76@1x/2x,
  83.5x83.5@2x
- App Store: 1024x1024@1x

## Verification

- Check icon appears correctly on iOS simulator/device
- Verify all required sizes generated
- Confirm no build warnings about missing icons
