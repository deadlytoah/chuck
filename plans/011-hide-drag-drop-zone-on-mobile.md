# Plan: Hide Drag & Drop Zone on Mobile Devices

## Prompt

> @[src/lib/widgets/upload_zone.dart] I would like the large space saying
> "Drag & drop images here" that allow user to drop images using a mouse to
> not appear for mobile phones. For mobile phones, just "Choose Images"
> button without the space that you can drop images. Record your plan please.

## Analysis

### Current Implementation
- [`upload_zone.dart:71-136`](file:///Users/hcs/Sync/Code/chuck/src/lib/widgets/upload_zone.dart#L71-L136): 
  200px height Container with drag & drop zone and centered content
- [`upload_zone.dart:84-102`](file:///Users/hcs/Sync/Code/chuck/src/lib/widgets/upload_zone.dart#L84-L102): 
  DropzoneView widget handles drag & drop functionality
- [`upload_zone.dart:103-133`](file:///Users/hcs/Sync/Code/chuck/src/lib/widgets/upload_zone.dart#L103-L133): 
  Centered Column with icon, text, and "Choose Files" button

### Issue
- Drag & drop is desktop-only functionality (requires mouse)
- Mobile users don't need the large 200px zone
- Wastes screen space on mobile devices

## Proposed Changes

### 1. Add Platform Detection
- Import `dart:io` for Platform class or use `MediaQuery` for responsive
  detection
- Determine if device is mobile (phone/tablet) vs desktop

### 2. Conditional Rendering
- **Desktop**: Show current 200px Container with DropzoneView + centered
  content
- **Mobile**: Show only "Choose Images" button without large container

### 3. Implementation Options

**Option A: Platform-based (dart:io)**
- Use `Platform.isAndroid || Platform.isIOS`
- Simple boolean check
- Works for native mobile apps

**Option B: Responsive (MediaQuery)**
- Use screen width breakpoint (e.g., < 600px = mobile)
- More flexible for tablets and web
- Better for Flutter web deployment

**Recommendation: Option B (MediaQuery)**
- More flexible across platforms
- Handles tablets appropriately
- Works on web, mobile, and desktop

### 4. Code Structure

```dart
Widget build(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  
  return Column(
    children: [
      if (isMobile)
        // Just the button
        ElevatedButton.icon(...)
      else
        // Current 200px Container with DropzoneView
        Container(...),
      if (hasUploads) ...[
        // Upload progress list
      ],
    ],
  );
}
```

## Files to Modify

- [`upload_zone.dart`](file:///Users/hcs/Sync/Code/chuck/src/lib/widgets/upload_zone.dart)
  - Add MediaQuery check for mobile detection
  - Wrap Container in conditional (desktop only)
  - Add mobile-only button layout
  - Adjust spacing/padding for mobile view

## Testing

- Test on desktop: verify drag & drop zone appears
- Test on mobile: verify only button appears
- Test on tablet: verify appropriate layout based on breakpoint
- Test drag & drop functionality on desktop
- Test file picker on all platforms
