import 'dart:math' as math;

/// Custom easing functions for animation effects.
///
/// Provides spring, bounce, elastic, and other advanced curves that go
/// beyond the standard [Curves] library. All functions take a normalised
/// time [t] in 0..1 and return a normalised output, though some may
/// overshoot (e.g. spring / elastic).
abstract class EasingCurves {
  EasingCurves._();

  // ── Spring ──────────────────────────────────────────────────────────────

  /// Critically-damped spring ease-out: fast start, gentle overshoot, settle.
  ///
  /// [damping] controls how quickly the oscillation decays (higher = less
  /// bounce). Default 8.0 gives a subtle single overshoot.
  static double springOut(double t, {double damping = 8.0}) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return 1.0 -
        math.exp(-damping * t) *
            math.cos(2.0 * math.pi * t);
  }

  /// Spring ease-in-out: gentle start, overshoot through midpoint, settle.
  static double springInOut(double t, {double damping = 8.0}) {
    if (t < 0.5) {
      return 0.5 * springOut(t * 2, damping: damping);
    }
    return 0.5 + 0.5 * springOut((t - 0.5) * 2, damping: damping);
  }

  // ── Bounce ──────────────────────────────────────────────────────────────

  /// Bounce ease-out: falls and bounces at the end.
  static double bounceOut(double t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      final t2 = t - 1.5 / 2.75;
      return 7.5625 * t2 * t2 + 0.75;
    } else if (t < 2.5 / 2.75) {
      final t2 = t - 2.25 / 2.75;
      return 7.5625 * t2 * t2 + 0.9375;
    } else {
      final t2 = t - 2.625 / 2.75;
      return 7.5625 * t2 * t2 + 0.984375;
    }
  }

  /// Bounce ease-in: bounces at the start, then accelerates.
  static double bounceIn(double t) => 1.0 - bounceOut(1.0 - t);

  // ── Elastic ─────────────────────────────────────────────────────────────

  /// Elastic ease-out: snaps past 1.0 then settles with dampened oscillation.
  ///
  /// [amplitude] and [period] control the overshoot magnitude and wave
  /// frequency.
  static double elasticOut(
    double t, {
    double amplitude = 1.0,
    double period = 0.4,
  }) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    final s = period / (2 * math.pi) * math.asin(1.0 / amplitude);
    return amplitude *
            math.pow(2, -10 * t) *
            math.sin((t - s) * (2 * math.pi) / period) +
        1.0;
  }

  /// Elastic ease-in: oscillates at the start before snapping to the target.
  static double elasticIn(
    double t, {
    double amplitude = 1.0,
    double period = 0.4,
  }) =>
      1.0 - elasticOut(1.0 - t, amplitude: amplitude, period: period);

  // ── Back ────────────────────────────────────────────────────────────────

  /// Back ease-out: overshoots then returns. [overshoot] defaults to 1.70158.
  static double backOut(double t, {double overshoot = 1.70158}) {
    final s = t - 1;
    return s * s * ((overshoot + 1) * s + overshoot) + 1;
  }

  // ── Smooth step ─────────────────────────────────────────────────────────

  /// Hermite smooth-step: S-curve with zero first-derivative at 0 and 1.
  static double smoothStep(double t) => t * t * (3 - 2 * t);

  /// Smoother Hermite interpolation (Ken Perlin's variation).
  static double smootherStep(double t) =>
      t * t * t * (t * (t * 6 - 15) + 10);

  // ── Exponential ─────────────────────────────────────────────────────────

  /// Exponential ease-out: fast start, decelerating to zero velocity.
  static double expoOut(double t) =>
      t >= 1 ? 1 : 1 - math.pow(2, -10 * t);
}
