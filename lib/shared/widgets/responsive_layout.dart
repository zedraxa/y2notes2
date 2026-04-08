import 'package:flutter/material.dart';

/// Responsive layout breakpoints for phone, tablet, and large tablet.
///
/// Usage:
/// ```dart
/// if (Breakpoints.isTablet(context)) { ... }
/// Breakpoints.responsive(context, phone: ..., tablet: ..., largeTablet: ...);
/// ```
abstract class Breakpoints {
  Breakpoints._();

  /// Phone max width (< 600).
  static const double phoneMax = 600;

  /// Tablet max width (600–1024).
  static const double tabletMax = 1024;

  /// Large tablet / landscape iPad Pro / MatePad.
  static const double largeTabletMax = 1400;

  /// Returns true if the screen width is phone-sized.
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phoneMax;

  /// Returns true if the screen width is tablet-sized (600–1024).
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= phoneMax && w < tabletMax;
  }

  /// Returns true if the screen width is large-tablet or wider.
  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  /// Returns the value for the current breakpoint.
  ///
  /// [largeTablet] falls back to [tablet] if not provided.
  /// [tablet] falls back to [phone] if not provided.
  static T responsive<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? largeTablet,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= tabletMax) return largeTablet ?? tablet ?? phone;
    if (w >= phoneMax) return tablet ?? phone;
    return phone;
  }

  /// Returns horizontal content padding appropriate for the screen size.
  static double contentPadding(BuildContext context) => responsive(
        context,
        phone: 16.0,
        tablet: 24.0,
        largeTablet: 32.0,
      );
}

/// A convenience widget that builds different layouts based on screen size.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.largeTablet,
  });

  final Widget phone;
  final Widget? tablet;
  final Widget? largeTablet;

  @override
  Widget build(BuildContext context) => Breakpoints.responsive(
        context,
        phone: phone,
        tablet: tablet,
        largeTablet: largeTablet,
      );
}
