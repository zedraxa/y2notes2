import 'package:flutter/animation.dart';

/// Apple-style animation curves and timing constants.
///
/// These curves are inspired by iOS/macOS motion design principles:
/// - Spring-based animations for natural, physics-driven feel
/// - Precise easing curves that match Apple's Human Interface Guidelines
/// - Timing durations that feel responsive yet deliberate
///
/// References:
/// - Apple HIG: Motion
/// - iOS UIView animation curves
class AppleCurves {
  AppleCurves._();

  // ─── Standard Curves ─────────────────────────────────────────────────────

  /// Standard iOS easing curve — smooth and balanced.
  /// Equivalent to UIView's curveEaseInOut.
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);

  /// Accelerating curve — starts slow, ends fast.
  /// Equivalent to UIView's curveEaseIn.
  static const Curve accelerate = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Decelerating curve — starts fast, ends slow.
  /// Equivalent to UIView's curveEaseOut.
  static const Curve decelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Sharp curve for quick, decisive movements.
  static const Curve sharp = Cubic(0.4, 0.0, 0.6, 1.0);

  // ─── Spring Curves ───────────────────────────────────────────────────────

  /// Gentle spring — subtle bounce, feels organic.
  /// Good for: buttons, toggles, small interactions
  static const Curve gentleSpring = Cubic(0.5, 1.1, 0.89, 1.0);

  /// Lively spring — noticeable bounce, playful.
  /// Good for: alerts, confirmations, success states
  static const Curve livelySpring = Cubic(0.68, -0.6, 0.32, 1.6);

  /// Bouncy spring — pronounced bounce, attention-grabbing.
  /// Good for: notifications, important UI changes
  static const Curve bouncySpring = Cubic(0.68, -0.55, 0.265, 1.55);

  // ─── Special Purpose ─────────────────────────────────────────────────────

  /// For expanding/revealing content smoothly.
  static const Curve expansion = Cubic(0.2, 0.0, 0.0, 1.0);

  /// For collapsing/hiding content smoothly.
  static const Curve collapse = Cubic(0.4, 0.0, 1.0, 1.0);

  /// For draggable elements that follow your finger.
  static const Curve interactive = Cubic(0.2, 0.0, 0.0, 1.0);

  /// For morphing shapes or transitioning layouts.
  static const Curve morph = Cubic(0.7, 0.0, 0.3, 1.0);
}

/// Apple-style animation durations.
///
/// These match the timing feel of iOS/macOS animations:
/// - Quick for micro-interactions (100-200ms)
/// - Standard for most transitions (250-350ms)
/// - Deliberate for major changes (400-600ms)
class AppleDurations {
  AppleDurations._();

  // ─── Micro Interactions ──────────────────────────────────────────────────

  /// Instant — for immediate feedback (75ms)
  static const Duration instant = Duration(milliseconds: 75);

  /// Quick — for button presses, toggles (150ms)
  static const Duration quick = Duration(milliseconds: 150);

  /// Snappy — for small UI changes (200ms)
  static const Duration snappy = Duration(milliseconds: 200);

  // ─── Standard Transitions ────────────────────────────────────────────────

  /// Short — for tooltips, small overlays (250ms)
  static const Duration short = Duration(milliseconds: 250);

  /// Standard — most UI transitions (300ms)
  static const Duration standard = Duration(milliseconds: 300);

  /// Medium — for modal presentations (350ms)
  static const Duration medium = Duration(milliseconds: 350);

  // ─── Complex Transitions ─────────────────────────────────────────────────

  /// Long — for page transitions (400ms)
  static const Duration long = Duration(milliseconds: 400);

  /// Deliberate — for major layout changes (500ms)
  static const Duration deliberate = Duration(milliseconds: 500);

  /// Slow — for emphasis, rarely used (600ms)
  static const Duration slow = Duration(milliseconds: 600);
}

/// Helper class for creating spring-based animations matching iOS physics.
class SpringSimulationHelper {
  SpringSimulationHelper._();

  /// Creates a gentle spring simulation for subtle interactions.
  static SpringDescription get gentle => const SpringDescription(
        mass: 1.0,
        stiffness: 180.0,
        damping: 12.0,
      );

  /// Creates a lively spring with more bounce.
  static SpringDescription get lively => const SpringDescription(
        mass: 1.0,
        stiffness: 200.0,
        damping: 10.0,
      );

  /// Creates a bouncy spring for attention-grabbing animations.
  static SpringDescription get bouncy => const SpringDescription(
        mass: 1.0,
        stiffness: 250.0,
        damping: 8.0,
      );

  /// Creates a smooth spring with no bounce (critically damped).
  static SpringDescription get smooth => const SpringDescription(
        mass: 1.0,
        stiffness: 100.0,
        damping: 20.0,
      );
}
