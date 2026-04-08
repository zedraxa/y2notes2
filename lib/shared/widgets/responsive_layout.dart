import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Responsive layout breakpoints for phone, tablet, large tablet, and desktop.
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

  /// Large tablet / landscape iPad Pro / MatePad (1024–1400).
  static const double largeTabletMax = 1400;

  /// Desktop / large monitor (≥ 1400).
  /// Covers Ubuntu Linux windows and Chrome browser at full width.
  static const double desktopMin = 1400;

  /// Returns true if the screen width is phone-sized.
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phoneMax;

  /// Returns true if the screen width is tablet-sized (600–1024).
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= phoneMax && w < tabletMax;
  }

  /// Returns true if the screen width is large-tablet or wider (≥ 1024).
  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  /// Returns true when running on a desktop or large-screen platform
  /// (Linux, macOS, Windows, or a wide web browser window).
  static bool isDesktop(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.sizeOf(context).width >= desktopMin;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return true;
      default:
        return MediaQuery.sizeOf(context).width >= desktopMin;
    }
  }

  /// Returns the value for the current breakpoint.
  ///
  /// [desktop] falls back to [largeTablet] if not provided.
  /// [largeTablet] falls back to [tablet] if not provided.
  /// [tablet] falls back to [phone] if not provided.
  static T responsive<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? largeTablet,
    T? desktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktopMin || isDesktop(context)) {
      return desktop ?? largeTablet ?? tablet ?? phone;
    }
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
        desktop: 48.0,
      );
}

/// A convenience widget that builds different layouts based on screen size.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.largeTablet,
    this.desktop,
  });

  final Widget phone;
  final Widget? tablet;
  final Widget? largeTablet;

  /// Layout for Ubuntu Linux / wide browser windows (≥ 1400 px or a desktop OS).
  final Widget? desktop;

  @override
  Widget build(BuildContext context) => Breakpoints.responsive(
        context,
        phone: phone,
        tablet: tablet,
        largeTablet: largeTablet,
        desktop: desktop,
      );
}

