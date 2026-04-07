import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class LassoTool implements DrawingTool {
  @override String get id => 'lasso';
  @override String get name => 'Lasso';
  @override String get description => 'Freeform selection tool';
  @override ToolCategory get category => ToolCategory.utility;
  @override IconData get icon => Icons.select_all;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => false;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    final path = Path()..moveTo(points[0].x, points[0].y);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }
    canvas.drawPath(path, paint);
    canvas.drawPath(path, Paint()
      ..color = const Color(0x332196F3)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver);
  }

  @override
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings) {}

  @override
  Path buildStrokePath(List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return Path();
    final path = Path()..moveTo(points[0].x, points[0].y);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }
    return path;
  }

  @override
  double getWidth(PointData point, ToolSettings settings) => settings.size;

  @override
  Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints) => settings.color;

  @override
  double getOpacity(PointData point, ToolSettings settings) => settings.opacity;

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {}

  @override
  List<ToolSettingDefinition> get settingsSchema => const [];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 2.0, opacity: 1.0);
}
