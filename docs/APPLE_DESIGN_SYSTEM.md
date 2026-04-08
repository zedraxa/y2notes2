# Apple Design System for Biscuits

A comprehensive design system implementation following Apple's Human Interface Guidelines, bringing the polish and refinement of iOS/macOS to the Biscuits note-taking app.

## Overview

This design system provides a complete set of design tokens, components, and patterns that embody Apple's design philosophy:

- **Smooth Motion**: Spring-based animations with carefully tuned easing curves
- **Visual Depth**: Multi-layer shadows and frosted glass effects
- **Consistent Spacing**: 8pt grid system for perfect alignment
- **Clear Hierarchy**: Typography scales with negative letter spacing
- **Adaptive Colors**: Semantic color system optimized for both light and dark modes

## Design Tokens

### Animation Curves (`AppleCurves`)

Pre-configured easing curves matching iOS animations:

```dart
AppleCurves.standard        // Balanced, smooth (default)
AppleCurves.gentleSpring    // Subtle bounce for buttons
AppleCurves.livelySpring    // Noticeable bounce for alerts
AppleCurves.decelerate      // Slides to rest naturally
```

### Durations (`AppleDurations`)

Standard timing values for consistency:

```dart
AppleDurations.quick        // 150ms - Micro interactions
AppleDurations.standard     // 300ms - Most transitions
AppleDurations.medium       // 350ms - Modal presentations
```

### Elevation (`AppleElevation`)

Shadow system with dual-layer shadows (ambient + directional):

```dart
AppleElevation.card         // Subtle lift for cards
AppleElevation.fab          // Floating action buttons
AppleElevation.dialog       // Modal dialogs
```

### Spacing (`AppleSpacing`)

8pt grid system with semantic names:

```dart
AppleSpacing.xs   // 4pt  - Tight spacing
AppleSpacing.sm   // 8pt  - Minimum touch spacing
AppleSpacing.lg   // 16pt - Standard spacing (most common)
AppleSpacing.xxl  // 24pt - Generous spacing
```

### Radius (`AppleRadius`)

Corner radius values:

```dart
AppleRadius.sm    // 8pt  - Small elements
AppleRadius.md    // 12pt - Text fields
AppleRadius.lg    // 16pt - Cards (most common)
AppleRadius.pill  // 999pt - Fully rounded
```

## Components

### Buttons

#### `AppleButton`
Primary button with smooth animations and multiple variants:

```dart
AppleButton(
  onPressed: () {},
  variant: AppleButtonVariant.filled,  // filled, tinted, outlined, ghost
  size: AppleButtonSize.medium,        // small, medium, large
  icon: Icons.add,
  fullWidth: false,
  child: Text('Add Item'),
)
```

#### `AppleIconButton`
Icon button with press feedback:

```dart
AppleIconButton(
  icon: Icons.settings,
  onPressed: () {},
  tooltip: 'Settings',
  badge: '3',  // Optional notification badge
)
```

### Lists & Cards

#### `AppleCard`
Card with elevation and optional press animation:

```dart
AppleCard(
  onTap: () {},
  showChevron: true,
  elevation: AppleElevation.level2,
  child: Text('Card content'),
)
```

#### `AppleListTile`
iOS Settings-style list item:

```dart
AppleListTile(
  title: Text('Account'),
  subtitle: Text('user@example.com'),
  leading: Icon(Icons.person),
  trailing: Switch(value: true, onChanged: (v) {}),
  onTap: () {},
)
```

#### `AppleInsetGroup`
Grouped list container (like iOS Settings):

```dart
AppleInsetGroup(
  header: Text('ACCOUNT'),
  footer: Text('Manage your account settings'),
  children: [
    AppleListTile(...),
    AppleListTile(...),
  ],
)
```

### Input Fields

#### `AppleTextField`
Text field with smooth focus animations:

```dart
AppleTextField(
  placeholder: 'Enter text',
  showClearButton: true,
  prefix: Icon(Icons.search),
  onChanged: (value) {},
)
```

#### `AppleSearchField`
Pre-configured search field:

```dart
AppleSearchField(
  placeholder: 'Search notes',
  onChanged: (query) {},
)
```

### Navigation

#### `AppleNavigationBar`
Frosted navigation bar with optional large title:

```dart
AppleNavigationBar(
  useLargeTitle: true,
  largeTitle: 'Notes',
  leading: AppleBackButton(),
  actions: [
    AppleIconButton(icon: Icons.add, onPressed: () {}),
  ],
)
```

#### `AppleScrollableNavigationBar`
Auto-collapsing navigation bar that shrinks on scroll:

```dart
AppleScrollableNavigationBar(
  title: 'Settings',
  scrollController: scrollController,
  actions: [
    AppleIconButton(icon: Icons.done, onPressed: () {}),
  ],
)
```

### Overlays

#### Bottom Sheets

```dart
showAppleBottomSheet(
  context: context,
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Your content
    ],
  ),
)
```

#### Dialogs

```dart
showAppleDialog(
  context: context,
  title: 'Delete Note?',
  content: 'This action cannot be undone.',
  actions: [
    AppleDialogAction(
      label: 'Cancel',
      onPressed: () {},
    ),
    AppleDialogAction(
      label: 'Delete',
      isDestructive: true,
      onPressed: () {},
    ),
  ],
)
```

#### Action Sheets

```dart
showAppleActionSheet(
  context: context,
  title: 'Choose an action',
  actions: [
    AppleActionSheetAction(
      label: 'Share',
      icon: Icons.share,
      onPressed: () {},
    ),
    AppleActionSheetAction(
      label: 'Delete',
      isDestructive: true,
      onPressed: () {},
    ),
  ],
  cancelAction: AppleActionSheetAction(
    label: 'Cancel',
  ),
)
```

## Animation Utilities

### `SpringContainer`
Scales down on press with spring animation:

```dart
SpringContainer(
  isPressed: _isPressed,
  pressedScale: 0.95,
  child: YourWidget(),
)
```

### `AppleFadeScale`
Combined fade and scale (like iOS alerts):

```dart
AppleFadeScale(
  visible: _isVisible,
  scaleBegin: 0.8,
  child: AlertContent(),
)
```

### `AppleShimmer`
Skeleton loading effect:

```dart
AppleShimmer(
  child: Container(
    width: 200,
    height: 20,
    color: Colors.white,
  ),
)
```

## Migration Guide

### Updating Existing Components

Replace Material buttons with Apple buttons:

```dart
// Before
ElevatedButton(
  onPressed: () {},
  child: Text('Submit'),
)

// After
AppleButton(
  onPressed: () {},
  variant: AppleButtonVariant.filled,
  child: Text('Submit'),
)
```

Replace ListTile with AppleListTile:

```dart
// Before
ListTile(
  title: Text('Settings'),
  onTap: () {},
)

// After
AppleListTile(
  title: Text('Settings'),
  onTap: () {},
)
```

### Using Design Tokens

Replace hardcoded values with tokens:

```dart
// Before
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
  ),
)

// After
Container(
  padding: AppleSpacing.cardPadding,
  decoration: BoxDecoration(
    borderRadius: AppleRadius.mdRadius,
  ),
)
```

## Best Practices

1. **Always use design tokens** - Use `AppleSpacing`, `AppleRadius`, etc. instead of hardcoded values
2. **Match animation durations** - Use `AppleDurations` constants for consistency
3. **Apply spring curves to interactive elements** - Buttons, toggles, cards should use `AppleCurves.gentleSpring`
4. **Use elevation appropriately** - Don't overuse shadows; follow the elevation hierarchy
5. **Respect the 44pt minimum touch target** - All interactive elements should be at least 44pt
6. **Test in both light and dark mode** - All components are designed for both modes

## File Structure

```
lib/
├── app/theme/
│   ├── animation_curves.dart      # Animation timing and curves
│   ├── elevation.dart             # Shadow and spacing tokens
│   ├── motion_widgets.dart        # Animation utility widgets
│   └── apple_design_system.dart   # Main export file
└── shared/widgets/
    ├── apple_button.dart          # Button components
    ├── apple_list_tile.dart       # List and card components
    ├── apple_text_field.dart      # Input components
    ├── apple_navigation_bar.dart  # Navigation components
    ├── apple_sheet.dart           # Bottom sheets and dialogs
    ├── frosted_container.dart     # Enhanced frosted glass
    └── apple_components.dart      # Main export file
```

## Integration Status

- [x] Core design tokens (animations, elevation, spacing)
- [x] Button components
- [x] List and card components
- [x] Input fields
- [x] Navigation bars
- [x] Bottom sheets and dialogs
- [x] Animation utilities
- [ ] Integration into existing pages (in progress)
- [ ] Migration of legacy components
- [ ] Comprehensive testing

## References

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [iOS Design Themes](https://developer.apple.com/design/human-interface-guidelines/ios/overview/themes/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
