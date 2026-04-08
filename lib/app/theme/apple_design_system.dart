/// Apple Design System for Biscuits
///
/// A comprehensive design system following Apple's Human Interface Guidelines,
/// bringing the polish and attention to detail of iOS/macOS to Flutter.
///
/// ## Core Principles
///
/// 1. **Motion**: Smooth, spring-based animations that feel natural and responsive
/// 2. **Depth**: Subtle shadows and blur effects creating visual hierarchy
/// 3. **Spacing**: Consistent 8pt grid system for perfect alignment
/// 4. **Typography**: Clear hierarchy with negative letter spacing
/// 5. **Color**: Semantic color system that adapts beautifully to dark mode
///
/// ## Usage
///
/// Import the design system:
/// ```dart
/// import 'package:biscuits/app/theme/apple_design_system.dart';
/// ```
///
/// Use animation curves:
/// ```dart
/// AnimatedContainer(
///   duration: AppleDurations.standard,
///   curve: AppleCurves.gentleSpring,
///   // ...
/// )
/// ```
///
/// Apply elevation:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppleElevation.card,
///     borderRadius: AppleRadius.lgRadius,
///   ),
/// )
/// ```
///
/// Use spacing:
/// ```dart
/// Padding(
///   padding: AppleSpacing.listItemPadding,
///   child: // ...
/// )
/// ```
///
/// ## Components
///
/// All components follow Apple's design patterns:
/// - `AppleButton` - Buttons with spring animations
/// - `AppleCard` - Cards with proper elevation
/// - `AppleListTile` - iOS Settings-style list items
/// - `AppleInsetGroup` - Grouped list containers
/// - `AppleNavigationBar` - Frosted navigation bars
/// - `AppleTextField` - Smooth text inputs
/// - Bottom sheets, dialogs, and action sheets
///
/// See individual component documentation for detailed usage.
library apple_design_system;

// Core design tokens
export 'animation_curves.dart';
export 'elevation.dart';
export 'motion_widgets.dart';

// Note: Colors are exported via app/theme/colors.dart
// which is already used throughout the app
