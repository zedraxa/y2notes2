import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_registry.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

/// Renders strokes using the `perfect_freehand` algorithm.
class StrokeRenderer {
  /// Build a [Path] from [stroke] using perfect_freehand outline points.
  Path buildStrokePath(Stroke stroke) {
    if (stroke.points.isEmpty) return Path();
    final points = _toFreehandPoints(stroke.points);
    final options = _buildOptions(stroke);
    final outlinePoints = getStroke(points, options: options);
    return _buildPathFromOutline(outlinePoints);
  }

  /// Render [stroke] onto [canvas].
  ///
  /// If the stroke has a [Stroke.toolId] referencing a registered [DrawingTool],
  /// delegates to that tool's [DrawingTool.renderStroke]. Otherwise falls back
  /// to the legacy perfect_freehand path.
  void renderStroke(Canvas canvas, Stroke stroke, [ToolSettings? overrideSettings]) {
    if (stroke.points.isEmpty) return;

    final pluginTool = stroke.toolId != null ? ToolRegistry.get(stroke.toolId!) : null;
    if (pluginTool != null) {
      final settings = overrideSettings ??
          pluginTool.defaultSettings.copyWith(
            color: stroke.color,
            size: stroke.baseWidth,
          );
      pluginTool.renderStroke(canvas, stroke.points, settings);
      pluginTool.postProcess(canvas, stroke.points, settings);
      return;
    }

    // Legacy path
    final path = buildStrokePath(stroke);
    final paint = _buildPaint(stroke);
    canvas.drawPath(path, paint);
  }

  /// Render the active (in-progress) stroke from raw [points].
  void renderActiveStroke(
    Canvas canvas,
    List<PointData> points,
    Color color,
    double baseWidth,
    StrokeTool tool,
  ) {
    if (points.isEmpty) return;
    final freehandPoints = _toFreehandPoints(points);
    final options = _buildOptionsFromParams(baseWidth, tool);
    final outlinePoints = getStroke(freehandPoints, options: options);
    final path = _buildPathFromOutline(outlinePoints);
    final paint = _buildPaintFromParams(color, tool);
    canvas.drawPath(path, paint);
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  List<PointVector> _toFreehandPoints(List<PointData> points) {
    return points.map((p) {
      // Apply tilt-to-width: altitude modulates the pressure passed to
      // perfect_freehand, so very flat strokes produce wider marks.
      final tiltMultiplier = _tiltMultiplier(p.altitude);
      final modulatedPressure = (p.pressure * tiltMultiplier).clamp(0.0, 1.0);
      return PointVector(p.x, p.y, modulatedPressure);
    }).toList();
  }

  /// Returns a width multiplier based on the pen altitude angle [radians].
  ///
  /// | Altitude  | Multiplier | Description          |
  /// |-----------|------------|----------------------|
  /// | < 30°     | 2.0        | Flat — shading mode  |
  /// | 30° – 60° | 1.0        | Normal writing       |
  /// | > 60°     | 0.5        | Upright — fine detail|
  static double _tiltMultiplier(double radians) {
    const flat = 30.0 * math.pi / 180.0;   // 30°
    const normal = 60.0 * math.pi / 180.0; // 60°
    if (radians < flat) return 2.0;
    if (radians > normal) return 0.5;
    final t = (radians - flat) / (normal - flat);
    return 2.0 - 1.5 * t;
  }

  StrokeOptions _buildOptions(Stroke stroke) =>
      _buildOptionsFromParams(stroke.baseWidth, stroke.tool);

  StrokeOptions _buildOptionsFromParams(
    double baseWidth,
    StrokeTool tool,
  ) {
    switch (tool) {
      case StrokeTool.highlighter:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.0,
          smoothing: 0.4,
          streamline: 0.5,
          simulatePressure: false,
        );
      case StrokeTool.eraser:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.0,
          smoothing: 0.2,
          streamline: 0.4,
          simulatePressure: false,
        );
      case StrokeTool.fountainPen:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.6,
          smoothing: 0.5,
          streamline: 0.5,
          simulatePressure: true,
        );
      case StrokeTool.ballpoint:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.3,
          smoothing: 0.5,
          streamline: 0.5,
          simulatePressure: true,
        );
    }
  }

  Paint _buildPaint(Stroke stroke) =>
      _buildPaintFromParams(stroke.color, stroke.tool);

  Paint _buildPaintFromParams(Color color, StrokeTool tool) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (tool) {
      case StrokeTool.highlighter:
        paint.color = Color.fromARGB(115, color.red, color.green, color.blue);
        paint.blendMode = BlendMode.multiply;
      case StrokeTool.eraser:
        paint.color = Colors.white;
        paint.blendMode = BlendMode.srcOver;
      default:
        paint.color = color;
        paint.blendMode = BlendMode.srcOver;
    }
    return paint;
  }

  Path _buildPathFromOutline(List<Offset> outlinePoints) {
    if (outlinePoints.isEmpty) return Path();
    final path = Path()
      ..moveTo(outlinePoints[0].dx, outlinePoints[0].dy);
    for (int i = 1; i < outlinePoints.length; i++) {
      path.lineTo(outlinePoints[i].dx, outlinePoints[i].dy);
    }
    path.close();
    return path;
  }

  /// Render a stroke using a plugin-based [DrawingTool] if provided.
  void renderStrokeWithTool(
    Canvas canvas,
    List<PointData> points,
    DrawingTool tool,
    ToolSettings settings,
  ) {
    tool.renderStroke(canvas, points, settings);
    tool.postProcess(canvas, points, settings);
  }
}
