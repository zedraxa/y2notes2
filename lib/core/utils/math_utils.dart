import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Geometry and math utility helpers for the canvas engine.
abstract class MathUtils {
  MathUtils._();

  /// Distance between two [Offset] points.
  static double distance(Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Angle in radians from [a] to [b].
  static double angle(Offset a, Offset b) =>
      math.atan2(b.dy - a.dy, b.dx - a.dx);

  /// Linear interpolation between two doubles.
  static double lerp(double a, double b, double t) => a + (b - a) * t;

  /// Clamp [value] between [min] and [max].
  static double clamp(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  /// Map a value from one range to another.
  static double remap(
    double value,
    double inMin,
    double inMax,
    double outMin,
    double outMax,
  ) {
    if (inMax == inMin) return outMin;
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin);
  }

  /// Simple deterministic pseudo-random float in [0, 1) seeded by position.
  static double pseudoRandom(double x, double y, [int seed = 0]) {
    // Fast hash-based pseudo-random — no dart:math Random needed per point.
    final xi = (x * 127.1 + y * 311.7 + seed * 74.9).truncate();
    final frac = ((xi * 1664525 + 1013904223) & 0x7FFFFFFF) / 0x7FFFFFFF;
    return frac.toDouble();
  }

  /// Returns a [Color] from HSV hue [hue] (0-360), saturation, value.
  static Color colorFromHue(
    double hue, {
    double saturation = 0.8,
    double value = 0.9,
    double opacity = 1.0,
  }) =>
      HSVColor.fromAHSV(opacity, hue % 360, saturation, value).toColor();

  /// Adjust the saturation of a [Color] by [factor] (1.0 = unchanged).
  static Color adjustSaturation(Color color, double factor) {
    final hsv = HSVColor.fromColor(color);
    return hsv
        .withSaturation(clamp(hsv.saturation * factor, 0, 1))
        .toColor();
  }

  /// Cumulative distance along a list of [Offset] points.
  static double cumulativeDistance(List<Offset> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += distance(points[i - 1], points[i]);
    }
    return total;
  }

  /// Per-segment cumulative distances (length == points.length).
  static List<double> cumulativeDistances(List<Offset> points) {
    final result = List<double>.filled(points.length, 0);
    for (int i = 1; i < points.length; i++) {
      result[i] = result[i - 1] + distance(points[i - 1], points[i]);
    }
    return result;
  }

  /// Rotate an [Offset] vector by [angle] radians.
  static Offset rotateOffset(Offset offset, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(
      offset.dx * cos - offset.dy * sin,
      offset.dx * sin + offset.dy * cos,
    );
  }
}
