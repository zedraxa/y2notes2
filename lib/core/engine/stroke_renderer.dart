import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/drawing_tool.dart';
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
  void renderStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
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
    final options = _buildOptionsFromParams(baseWidth, tool, isLast: false);
    final outlinePoints = getStroke(freehandPoints, options: options);
    final path = _buildPathFromOutline(outlinePoints);
    final paint = _buildPaintFromParams(color, tool);
    canvas.drawPath(path, paint);
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  List<PointVector> _toFreehandPoints(List<PointData> points) =>
      points.map((p) => PointVector(p.x, p.y, p.pressure)).toList();

  StrokeOptions _buildOptions(Stroke stroke) =>
      _buildOptionsFromParams(stroke.baseWidth, stroke.tool);

  StrokeOptions _buildOptionsFromParams(
    double baseWidth,
    StrokeTool tool, {
    bool isLast = true,
  }) {
    switch (tool) {
      case StrokeTool.highlighter:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.0,
          smoothing: 0.4,
          streamline: 0.5,
          simulatePressure: false,
          last: isLast,
        );
      case StrokeTool.eraser:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.0,
          smoothing: 0.2,
          streamline: 0.4,
          simulatePressure: false,
          last: isLast,
        );
      case StrokeTool.fountainPen:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.6,
          smoothing: 0.5,
          streamline: 0.5,
          simulatePressure: true,
          last: isLast,
        );
      case StrokeTool.ballpoint:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.3,
          smoothing: 0.5,
          streamline: 0.5,
          simulatePressure: true,
          last: isLast,
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

  Path _buildPathFromOutline(List<PointVector> outlinePoints) {
    if (outlinePoints.isEmpty) return Path();
    final path = Path()
      ..moveTo(outlinePoints[0].x, outlinePoints[0].y);
    for (int i = 1; i < outlinePoints.length; i++) {
      path.lineTo(outlinePoints[i].x, outlinePoints[i].y);
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
