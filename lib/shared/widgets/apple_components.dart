/// Apple-style UI Components for Biscuits
///
/// A collection of polished, iOS-inspired UI components that follow
/// Apple's Human Interface Guidelines.
///
/// All components feature:
/// - Smooth spring animations
/// - Proper haptic feedback integration points
/// - Dark mode support
/// - Accessibility considerations
/// - 44pt minimum touch targets
///
/// ## Available Components
///
/// ### Buttons
/// - `AppleButton` - Primary button with variants (filled, tinted, outlined, ghost)
/// - `AppleIconButton` - Icon button with press feedback and badge support
/// - `AppleBackButton` - Chevron-style back button
///
/// ### Lists & Cards
/// - `AppleCard` - Card container with elevation and press animation
/// - `AppleListTile` - iOS Settings-style list item
/// - `AppleInsetGroup` - Grouped list container with header/footer
///
/// ### Input
/// - `AppleTextField` - Text field with smooth focus animations
/// - `AppleSearchField` - Search field with magnifying glass icon
///
/// ### Navigation
/// - `AppleNavigationBar` - Frosted navigation bar with large title support
/// - `AppleScrollableNavigationBar` - Collapsible navigation bar
///
/// ### Overlays
/// - `showAppleBottomSheet()` - Frosted bottom sheet
/// - `showAppleDialog()` - Alert dialog with blur
/// - `showAppleActionSheet()` - iOS-style action sheet
/// - `AppleBottomSheetContainer` - Reusable bottom sheet container
///
/// ### Utilities
/// - `FrostedContainer` - Frosted glass container (enhanced)
/// - `SpringContainer` - Container with spring animation
/// - `AppleFade` - Fade animation
/// - `AppleFadeScale` - Combined fade and scale
/// - `AppleSlide` - Slide animation
/// - `AppleShimmer` - Skeleton loading shimmer
///
/// ## Usage Examples
///
/// ### Button
/// ```dart
/// AppleButton(
///   onPressed: () {},
///   variant: AppleButtonVariant.filled,
///   size: AppleButtonSize.medium,
///   icon: Icons.add,
///   child: Text('Add Item'),
/// )
/// ```
///
/// ### List Tile
/// ```dart
/// AppleListTile(
///   title: Text('Settings'),
///   subtitle: Text('Configure your preferences'),
///   leading: Icon(Icons.settings),
///   onTap: () {},
/// )
/// ```
///
/// ### Bottom Sheet
/// ```dart
/// showAppleBottomSheet(
///   context: context,
///   builder: (context) => Column(
///     children: [
///       // Your content
///     ],
///   ),
/// )
/// ```
library apple_components;

// Buttons
export 'package:biscuits/shared/widgets/apple_button.dart';

// Lists and Cards
export 'package:biscuits/shared/widgets/apple_list_tile.dart';

// Input
export 'package:biscuits/shared/widgets/apple_text_field.dart';

// Navigation
export 'package:biscuits/shared/widgets/apple_navigation_bar.dart';

// Overlays
export 'package:biscuits/shared/widgets/apple_sheet.dart';

// Utilities
export 'package:biscuits/shared/widgets/frosted_container.dart';
export 'package:biscuits/app/theme/motion_widgets.dart';
