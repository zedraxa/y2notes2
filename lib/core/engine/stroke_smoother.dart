import 'dart:math' as math;
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';

/// Utilities for smoothing raw stylus input into natural-feeling strokes.
///
/// Provides:
/// - **Catmull-Rom interpolation** to fill gaps between sampled points during
///   fast pen movement, eliminating the "chicken scratch" look.
/// - **Velocity-based end tapering** to produce natural stroke endings that
///   trail off instead of ending abruptly.
/// - **Adaptive point reduction** using a Ramer–Douglas–Peucker simplification
///   for committed strokes to keep storage lean.
class StrokeSmoother {
  const StrokeSmoother._();

  // ─── Catmull-Rom interpolation ──────────────────────────────────────────

  /// Minimum pixel distance between consecutive points before interpolation
  /// kicks in.  Points closer than this are passed through unchanged.
  static const double _interpolationThreshold = 8.0;

  /// Maximum number of mid-points inserted between two samples.
  static const int _maxInsertedPoints = 4;

  /// Returns a list with Catmull-Rom interpolated mid-points inserted wherever
  /// the gap between consecutive raw samples exceeds [_interpolationThreshold].
  ///
  /// The returned list always contains the original [points] in order, plus
  /// smoothly interpolated fill-in points.  Calling this on an already-dense
  /// stroke is cheap because the threshold test short-circuits.
  static List<PointData> interpolate(List<PointData> points) {
    if (points.length < 3) return points;
    final result = <PointData>[points.first];

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final dx = curr.x - prev.x;
      final dy = curr.y - prev.y;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist > _interpolationThreshold) {
        // Determine how many mid-points to insert (proportional to gap size).
        final count = math.min(
          (dist / _interpolationThreshold).floor(),
          _maxInsertedPoints,
        );
        // Gather the 4 control points for the Catmull-Rom segment.
        final p0 = i >= 2 ? points[i - 2] : prev;
        final p1 = prev;
        final p2 = curr;
        final p3 = i + 1 < points.length ? points[i + 1] : curr;

        for (int j = 1; j <= count; j++) {
          final t = j / (count + 1);
          result.add(_catmullRom(p0, p1, p2, p3, t));
        }
      }
      result.add(curr);
    }
    return result;
  }

  /// Evaluates the Catmull-Rom spline defined by four control points at
  /// parameter [t] ∈ [0, 1].  Also interpolates pressure, tilt, azimuth,
  /// altitude, and timestamp for a seamless feel.
  static PointData _catmullRom(
    PointData p0,
    PointData p1,
    PointData p2,
    PointData p3,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;

    // Standard Catmull-Rom basis (α = 0.5, uniform parameterisation).
    double cr(double v0, double v1, double v2, double v3) =>
        0.5 *
        ((2.0 * v1) +
            (-v0 + v2) * t +
            (2.0 * v0 - 5.0 * v1 + 4.0 * v2 - v3) * t2 +
            (-v0 + 3.0 * v1 - 3.0 * v2 + v3) * t3);

    return PointData(
      x: cr(p0.x, p1.x, p2.x, p3.x),
      y: cr(p0.y, p1.y, p2.y, p3.y),
      pressure: _lerp(p1.pressure, p2.pressure, t),
      tilt: _lerp(p1.tilt, p2.tilt, t),
      velocity: _lerp(p1.velocity, p2.velocity, t),
      timestamp: (p1.timestamp + ((p2.timestamp - p1.timestamp) * t)).round(),
      azimuth: _lerp(p1.azimuth, p2.azimuth, t),
      altitude: _lerp(p1.altitude, p2.altitude, t),
      hoverDistance: _lerp(p1.hoverDistance, p2.hoverDistance, t),
    );
  }

  // ─── Velocity-based end tapering ────────────────────────────────────────

  /// Number of tail points to apply tapering over.
  static const int _taperPointCount = 6;

  /// Applies a smooth pressure taper to the last [_taperPointCount] points of
  /// [points], so the stroke trails off naturally when the pen lifts.
  ///
  /// Uses a cubic ease-out curve for the taper shape.
  static List<PointData> applyEndTaper(List<PointData> points) {
    if (points.length < _taperPointCount + 2) return points;

    final result = List<PointData>.of(points);
    final taperStart = result.length - _taperPointCount;

    for (int i = taperStart; i < result.length; i++) {
      // t goes from 1.0 at taperStart to 0.0 at the last point.
      final t = (result.length - 1 - i) / _taperPointCount;
      // Cubic ease-out: fast entry, slow tail.
      final factor = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
      final p = result[i];
      result[i] = p.copyWith(pressure: p.pressure * factor);
    }
    return result;
  }

  // ─── Point reduction (Ramer–Douglas–Peucker) ───────────────────────────

  /// Simplifies [points] by removing points that deviate less than [epsilon]
  /// pixels from the line between their neighbours.
  ///
  /// Useful for reducing storage size of committed strokes without visible
  /// quality loss.  Default [epsilon] = 0.5 px is imperceptible.
  static List<PointData> simplify(List<PointData> points,
      {double epsilon = 0.5}) {
    if (points.length < 3) return points;
    return _rdp(points, 0, points.length - 1, epsilon);
  }

  static List<PointData> _rdp(
      List<PointData> points, int start, int end, double epsilon) {
    double maxDist = 0;
    int maxIndex = start;

    final p1 = points[start];
    final p2 = points[end];

    for (int i = start + 1; i < end; i++) {
      final d = _perpendicularDistance(points[i], p1, p2);
      if (d > maxDist) {
        maxDist = d;
        maxIndex = i;
      }
    }

    if (maxDist > epsilon) {
      final left = _rdp(points, start, maxIndex, epsilon);
      final right = _rdp(points, maxIndex, end, epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    }
    return [points[start], points[end]];
  }

  static double _perpendicularDistance(
      PointData point, PointData lineStart, PointData lineEnd) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;
    final lengthSq = dx * dx + dy * dy;
    if (lengthSq == 0) {
      final ddx = point.x - lineStart.x;
      final ddy = point.y - lineStart.y;
      return math.sqrt(ddx * ddx + ddy * ddy);
    }
    final crossProduct =
        ((point.x - lineStart.x) * dy - (point.y - lineStart.y) * dx).abs();
    return crossProduct / math.sqrt(lengthSq);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
