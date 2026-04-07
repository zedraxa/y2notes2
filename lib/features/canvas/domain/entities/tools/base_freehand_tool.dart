import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

abstract class BaseFreehandTool implements DrawingTool {
  Path buildFreehandPath(
    List<PointData> points,
    ToolSettings settings, {
    double thinning = 0.5,
    double smoothing = 0.5,
    double streamline = 0.5,
    bool simulatePressure = true,
  }) {
    if (points.isEmpty) return Path();

    // ── Apply tiltSensitivity to modulate altitude-based width ────────────
    // tiltSensitivity = 1.0 → full tilt range; 0.0 → tilt ignored.
    final tiltSens = settings.tiltSensitivity.clamp(0.0, 2.0);
    final freehandPoints = points.map((p) {
      final rawTiltMultiplier = _tiltMultiplier(p.altitude);
      // Blend toward 1.0 based on tiltSensitivity:
      //   effective = 1.0 + (raw - 1.0) * tiltSens
      final effective = 1.0 + (rawTiltMultiplier - 1.0) * tiltSens;
      final modulatedPressure = (p.pressure * effective).clamp(0.0, 1.0);
      return PointVector(p.x, p.y, modulatedPressure);
    }).toList();

    // ── Velocity-based dynamic streamline ─────────────────────────────────
    // Faster strokes produce smoother paths (more streamline) to reduce
    // jagged artifacts during quick writing.
    double adjustedStreamline = streamline;
    if (points.length >= 3) {
      double avgVelocity = 0.0;
      for (final p in points) {
        avgVelocity += p.velocity;
      }
      avgVelocity /= points.length;
      // Increase streamline for faster strokes (capped)
      adjustedStreamline =
          (streamline + avgVelocity.clamp(0.0, 1.5) * 0.15).clamp(0.0, 0.95);
    }

    final outlinePoints = getStroke(
      freehandPoints,
      options: StrokeOptions(
        size: settings.size,
        thinning: thinning,
        smoothing: smoothing,
        streamline: adjustedStreamline,
        simulatePressure: simulatePressure,
      ),
    );
    if (outlinePoints.isEmpty) return Path();
    final path = Path()
      ..moveTo(outlinePoints[0].dx, outlinePoints[0].dy);
    for (int i = 1; i < outlinePoints.length; i++) {
      path.lineTo(outlinePoints[i].dx, outlinePoints[i].dy);
    }
    path.close();
    return path;
  }

  /// Returns a width multiplier based on the pen altitude angle [radians].
  static double _tiltMultiplier(double radians) {
    const flat = 30.0 * math.pi / 180.0; // 30°
    const normal = 60.0 * math.pi / 180.0; // 60°
    if (radians < flat) return 2.0;
    if (radians > normal) return 0.5;
    final t = (radians - flat) / (normal - flat);
    return 2.0 - 1.5 * t;
  }

  @override
  Path buildStrokePath(List<PointData> points, ToolSettings settings) =>
      buildFreehandPath(points, settings);

  @override
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings) {
    final paint = Paint()
      ..color = settings.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(point.x, point.y), settings.size * 0.5, paint);
  }

  @override
  double getWidth(PointData point, ToolSettings settings) => settings.size;

  @override
  Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints) =>
      settings.color;

  @override
  double getOpacity(PointData point, ToolSettings settings) => settings.opacity;

  @override
  bool get hasTexture => false;

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {}
}
