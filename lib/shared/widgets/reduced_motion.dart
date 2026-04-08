import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/animation_curves.dart';

/// Utility for respecting the system's reduced-motion accessibility setting.
///
/// When the user has enabled "Reduce Motion" in their OS accessibility
/// settings, animations should be replaced with instant transitions or
/// simple fades to avoid discomfort.
///
/// Usage:
/// ```dart
/// AnimatedContainer(
///   duration: ReducedMotion.duration(context, AppleDurations.standard),
///   curve: ReducedMotion.curve(context, AppleCurves.gentleSpring),
///   // ...
/// )
/// ```
class ReducedMotion {
  ReducedMotion._();

  /// Returns true if the user has requested reduced motion.
  static bool isEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Returns [Duration.zero] if reduced motion is enabled,
  /// otherwise returns the provided [duration].
  static Duration duration(BuildContext context, Duration duration) {
    return isEnabled(context) ? Duration.zero : duration;
  }

  /// Returns [Curves.linear] if reduced motion is enabled,
  /// otherwise returns the provided [curve].
  static Curve curve(BuildContext context, Curve curve) {
    return isEnabled(context) ? Curves.linear : curve;
  }

  /// Returns 1.0 (no scaling) if reduced motion is enabled,
  /// otherwise returns the provided [scale].
  static double scale(BuildContext context, double scale) {
    return isEnabled(context) ? 1.0 : scale;
  }

  /// Wraps a child widget with an animated opacity that respects reduced motion.
  /// If reduced motion is enabled, shows the child immediately without animation.
  static Widget fade({
    required BuildContext context,
    required bool visible,
    required Widget child,
    Duration? animDuration,
  }) {
    if (isEnabled(context)) {
      return Visibility(
        visible: visible,
        child: child,
      );
    }
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: animDuration ?? AppleDurations.standard,
      curve: AppleCurves.standard,
      child: child,
    );
  }
}
