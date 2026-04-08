import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:biscuits/core/engine/stroke_smoother.dart';
import 'package:biscuits/core/engine/stylus/pressure_curve.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/canvas/domain/entities/tool.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_registry.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

/// Renders strokes using the `perfect_freehand` algorithm.
class StrokeRenderer {
  /// Build a [Path] from [stroke] using perfect_freehand outline points.
  ///
  /// Applies Catmull-Rom interpolation to fill gaps in fast strokes and
  /// velocity-based end tapering for natural stroke endings.
  Path buildStrokePath(Stroke stroke) {
    if (stroke.points.isEmpty) return Path();
    // Interpolate to fill gaps from fast pen movement.
    var smoothed = StrokeSmoother.interpolate(stroke.points);
    // Apply natural pressure taper at stroke end.
    smoothed = StrokeSmoother.applyEndTaper(smoothed);
    final points = _toFreehandPoints(smoothed);
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
  ///
  /// Applies Catmull-Rom interpolation for gap-filling during fast drawing.
  void renderActiveStroke(
    Canvas canvas,
    List<PointData> points,
    Color color,
    double baseWidth,
    StrokeTool tool,
  ) {
    if (points.isEmpty) return;
    final smoothed = StrokeSmoother.interpolate(points);
    final freehandPoints = _toFreehandPoints(smoothed);
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
      // Delegates to the shared StylusWidthCalculator implementation.
      final tiltMul = StylusWidthCalculator.tiltMultiplier(p.altitude);
      final modulatedPressure = (p.pressure * tiltMul).clamp(0.0, 1.0);
      return PointVector(p.x, p.y, modulatedPressure);
    }).toList();
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
          smoothing: 0.55,
          streamline: 0.6,
          simulatePressure: true,
        );
      case StrokeTool.ballpoint:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.3,
          smoothing: 0.55,
          streamline: 0.6,
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

  /// Builds a smooth closed [Path] from perfect_freehand [outlinePoints].
  ///
  /// Uses quadratic Bézier curves between midpoints of consecutive segments
  /// instead of straight lineTo() calls, producing much smoother rendered
  /// edges — especially visible on thick strokes and highlights.
  Path _buildPathFromOutline(List<Offset> outlinePoints) {
    if (outlinePoints.isEmpty) return Path();
    if (outlinePoints.length < 3) {
      // Not enough points for Bézier — fall back to simple lines.
      final path = Path()
        ..moveTo(outlinePoints[0].dx, outlinePoints[0].dy);
      for (int i = 1; i < outlinePoints.length; i++) {
        path.lineTo(outlinePoints[i].dx, outlinePoints[i].dy);
      }
      path.close();
      return path;
    }

    final path = Path();
    // Start at the midpoint between the first and second outline point.
    final firstMid = Offset(
      (outlinePoints[0].dx + outlinePoints[1].dx) / 2,
      (outlinePoints[0].dy + outlinePoints[1].dy) / 2,
    );
    path.moveTo(firstMid.dx, firstMid.dy);

    for (int i = 1; i < outlinePoints.length - 1; i++) {
      final mid = Offset(
        (outlinePoints[i].dx + outlinePoints[i + 1].dx) / 2,
        (outlinePoints[i].dy + outlinePoints[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(
        outlinePoints[i].dx,
        outlinePoints[i].dy,
        mid.dx,
        mid.dy,
      );
    }

    // Final segment back to close the path.
    final last = outlinePoints.last;
    path.quadraticBezierTo(last.dx, last.dy, firstMid.dx, firstMid.dy);
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
