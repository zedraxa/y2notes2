import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

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
    final freehandPoints =
        points.map((p) => PointVector(p.x, p.y, p.pressure)).toList();
    final outlinePoints = getStroke(
      freehandPoints,
      options: StrokeOptions(
        size: settings.size,
        thinning: thinning,
        smoothing: smoothing,
        streamline: streamline,
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
