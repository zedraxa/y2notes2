import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Extension methods on [Offset] for canvas geometry helpers.
extension OffsetExtensions on Offset {
  /// Distance to another [Offset].
  double distanceTo(Offset other) {
    final dx = other.dx - this.dx;
    final dy = other.dy - this.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Angle (radians) toward another [Offset].
  double angleTo(Offset other) =>
      math.atan2(other.dy - dy, other.dx - dx);

  /// Linear interpolation toward [other] by factor [t].
  Offset lerpTo(Offset other, double t) =>
      Offset(dx + (other.dx - dx) * t, dy + (other.dy - dy) * t);

  /// Normalized direction vector toward [other].
  Offset directionTo(Offset other) {
    final d = distanceTo(other);
    if (d == 0) return Offset.zero;
    return Offset((other.dx - dx) / d, (other.dy - dy) / d);
  }

  /// Returns a perpendicular offset (rotated 90°).
  Offset get perpendicular => Offset(-dy, dx);

  /// Dot product with another [Offset].
  double dot(Offset other) => dx * other.dx + dy * other.dy;

  /// Magnitude (length) of this vector.
  double get magnitude => math.sqrt(dx * dx + dy * dy);

  /// Normalized unit vector.
  Offset get normalized {
    final m = magnitude;
    if (m == 0) return Offset.zero;
    return Offset(dx / m, dy / m);
  }

  /// Scale this offset by [factor].
  Offset scaled(double factor) => Offset(dx * factor, dy * factor);
}
