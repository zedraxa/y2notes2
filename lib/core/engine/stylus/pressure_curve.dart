import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Preset shapes for mapping raw stylus pressure to a perceived intensity.
///
/// Each preset corresponds to a cubic Bézier curve defined by two control
/// points ([controlPoint1] and [controlPoint2]) in the unit square.
enum PressureCurvePreset {
  /// 1:1 linear mapping — raw pressure is used unchanged.
  linear,

  /// Gentle start — more responsive at low pressure, suitable for light
  /// sketching and note-taking.
  soft,

  /// Firm — requires more pressure for visible width variation. Useful for
  /// deliberate calligraphy strokes.
  firm,

  /// Emphasises light touches while keeping heavy-pressure strokes consistent.
  sketching,

  /// Extreme variation from hairline to very wide — ideal for brush calligraphy.
  calligraphy,

  /// User-defined curve with arbitrary control points.
  custom,
}

/// Maps raw stylus pressure [0.0 – 1.0] through a cubic Bézier curve so that
/// the perceived pen feel matches the user's preferences.
///
/// The Bézier is defined by two interior control points ([controlPoint1] and
/// [controlPoint2]) anchored at (0, 0) and (1, 1), identical to the CSS
/// `cubic-bezier()` convention.
///
/// ```dart
/// final curve = PressureCurve.soft;
/// final width = baseWidth * curve.apply(rawPressure);
/// ```
class PressureCurve {
  /// Creates a cubic Bézier pressure curve with the given control points.
  ///
  /// Both points must have components in [0.0, 1.0].
  const PressureCurve({
    required this.controlPoint1,
    required this.controlPoint2,
    this.preset = PressureCurvePreset.custom,
  });

  /// First interior control point (x1, y1) of the cubic Bézier.
  final Offset controlPoint1;

  /// Second interior control point (x2, y2) of the cubic Bézier.
  final Offset controlPoint2;

  /// Which preset this curve corresponds to (informational).
  final PressureCurvePreset preset;

  // ─── Built-in presets ─────────────────────────────────────────────────────

  /// Linear 1:1 mapping — output equals input.
  static const PressureCurve linear = PressureCurve(
    controlPoint1: Offset(0.0, 0.0),
    controlPoint2: Offset(1.0, 1.0),
    preset: PressureCurvePreset.linear,
  );

  /// Gentle start — extra responsiveness at low pressure.
  static const PressureCurve soft = PressureCurve(
    controlPoint1: Offset(0.1, 0.6),
    controlPoint2: Offset(0.4, 1.0),
    preset: PressureCurvePreset.soft,
  );

  /// Firm — requires noticeable pressure before width changes.
  static const PressureCurve firm = PressureCurve(
    controlPoint1: Offset(0.6, 0.1),
    controlPoint2: Offset(0.9, 0.7),
    preset: PressureCurvePreset.firm,
  );

  /// Sketching — emphasises light-touch variation.
  static const PressureCurve sketching = PressureCurve(
    controlPoint1: Offset(0.05, 0.5),
    controlPoint2: Offset(0.5, 0.95),
    preset: PressureCurvePreset.sketching,
  );

  /// Calligraphy — extreme thin-to-thick contrast.
  static const PressureCurve calligraphy = PressureCurve(
    controlPoint1: Offset(0.2, 0.0),
    controlPoint2: Offset(0.8, 1.0),
    preset: PressureCurvePreset.calligraphy,
  );

  // ─── Application ──────────────────────────────────────────────────────────

  /// Maps [rawPressure] ∈ [0.0, 1.0] through the curve, returning a value in
  /// the same range.
  ///
  /// Uses Newton–Raphson iteration to invert the parametric t → x Bézier and
  /// then evaluates t → y.  Falls back to the linear value after 8 iterations
  /// or if the curve is degenerate (both control points on the diagonal).
  double apply(double rawPressure) {
    final x = rawPressure.clamp(0.0, 1.0);

    // Fast path: linear curve.
    if (preset == PressureCurvePreset.linear ||
        (controlPoint1.dx == controlPoint1.dy &&
            controlPoint2.dx == controlPoint2.dy)) {
      return x;
    }

    // Solve for t such that bezierX(t) ≈ x using Newton–Raphson.
    double t = x; // initial guess
    for (int i = 0; i < 8; i++) {
      final currentX = _bezierValue(t, controlPoint1.dx, controlPoint2.dx);
      final slope = _bezierSlope(t, controlPoint1.dx, controlPoint2.dx);
      if (slope.abs() < 1e-6) break;
      t -= (currentX - x) / slope;
      t = t.clamp(0.0, 1.0);
    }

    return _bezierValue(t, controlPoint1.dy, controlPoint2.dy).clamp(0.0, 1.0);
  }

  // ─── Static helpers ───────────────────────────────────────────────────────

  /// Returns a [PressureCurve] for the given [preset].
  static PressureCurve fromPreset(PressureCurvePreset preset) {
    switch (preset) {
      case PressureCurvePreset.linear:
        return linear;
      case PressureCurvePreset.soft:
        return soft;
      case PressureCurvePreset.firm:
        return firm;
      case PressureCurvePreset.sketching:
        return sketching;
      case PressureCurvePreset.calligraphy:
        return calligraphy;
      case PressureCurvePreset.custom:
        return linear; // fallback
    }
  }

  // ─── Bézier internals ─────────────────────────────────────────────────────

  /// Evaluates a 1D cubic Bézier at parameter [t] with the given interior
  /// control value (anchored at 0 and 1).
  static double _bezierValue(double t, double c1, double c2) {
    final mt = 1.0 - t;
    return 3.0 * mt * mt * t * c1 +
        3.0 * mt * t * t * c2 +
        t * t * t;
  }

  /// Evaluates the derivative of the 1D cubic Bézier at [t].
  static double _bezierSlope(double t, double c1, double c2) {
    final mt = 1.0 - t;
    return 3.0 * mt * mt * c1 +
        6.0 * mt * t * (c2 - c1) +
        3.0 * t * t * (1.0 - c2);
  }

  /// Returns an approximate display name for this curve.
  String get displayName {
    switch (preset) {
      case PressureCurvePreset.linear:
        return 'Linear';
      case PressureCurvePreset.soft:
        return 'Soft';
      case PressureCurvePreset.firm:
        return 'Firm';
      case PressureCurvePreset.sketching:
        return 'Sketching';
      case PressureCurvePreset.calligraphy:
        return 'Calligraphy';
      case PressureCurvePreset.custom:
        return 'Custom';
    }
  }

  /// Serialises control points to a plain map for persistence.
  Map<String, double> toJson() => {
        'x1': controlPoint1.dx,
        'y1': controlPoint1.dy,
        'x2': controlPoint2.dx,
        'y2': controlPoint2.dy,
      };

  /// Deserialises from the map produced by [toJson].
  factory PressureCurve.fromJson(Map<String, dynamic> json) => PressureCurve(
        controlPoint1: Offset(
          (json['x1'] as num).toDouble(),
          (json['y1'] as num).toDouble(),
        ),
        controlPoint2: Offset(
          (json['x2'] as num).toDouble(),
          (json['y2'] as num).toDouble(),
        ),
      );

  // ─── Paint helper ─────────────────────────────────────────────────────────

  /// Paints a visual preview of the curve into [canvas] within [rect].
  ///
  /// Useful for the pressure curve editor in settings UI.
  void paintPreview(Canvas canvas, Rect rect, {Paint? curvePaint}) {
    final paint = curvePaint ??
        (Paint()
          ..color = const Color(0xFF4A90D9)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true);

    final path = Path();
    const steps = 64;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final mappedY = apply(t);
      final px = rect.left + t * rect.width;
      final py = rect.bottom - mappedY * rect.height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool operator ==(Object other) =>
      other is PressureCurve &&
      controlPoint1 == other.controlPoint1 &&
      controlPoint2 == other.controlPoint2;

  @override
  int get hashCode => Object.hash(controlPoint1, controlPoint2);
}

/// Utility that computes the final stroke width from multiple inputs.
///
/// ```dart
/// final width = StylusWidthCalculator.compute(
///   baseWidth: 3.0,
///   pressure: 0.7,
///   tiltRadians: 0.4,
///   curve: PressureCurve.soft,
/// );
/// ```
abstract final class StylusWidthCalculator {
  StylusWidthCalculator._();

  /// Computes the final rendered width combining pressure curve and tilt
  /// modulation.
  ///
  /// [tiltRadians] is the altitude angle (0 = flat/horizontal, π/2 = vertical).
  /// When [tiltRadians] is 0 (pen held flat) the multiplier is 2.0 (shading
  /// mode).  At π/2 (pen upright) the multiplier is 0.5 (fine detail).
  static double compute({
    required double baseWidth,
    required double pressure,
    double tiltRadians = math.pi / 2,
    PressureCurve curve = PressureCurve.linear,
    double toolMultiplier = 1.0,
  }) {
    final mappedPressure = curve.apply(pressure.clamp(0.0, 1.0));
    final tiltMultiplier = _tiltMultiplier(tiltRadians);
    return (baseWidth * mappedPressure * tiltMultiplier * toolMultiplier)
        .clamp(0.5, 60.0);
  }

  /// Returns a width multiplier based on tilt altitude [radians].
  ///
  /// | Tilt angle | Multiplier | Description         |
  /// |------------|------------|---------------------|
  /// | < 30°      | 2.0        | Shading (flat hold) |
  /// | 30° – 60°  | 1.0        | Normal writing      |
  /// | > 60°      | 0.5        | Fine detail         |
  static double _tiltMultiplier(double radians) {
    const flat = 30.0 * math.pi / 180.0;   // 30°
    const normal = 60.0 * math.pi / 180.0; // 60°

    if (radians < flat) return 2.0;
    if (radians > normal) return 0.5;

    // Smooth interpolation between flat and upright.
    final t = (radians - flat) / (normal - flat);
    return 2.0 - 1.5 * t; // 2.0 → 0.5
  }
}
