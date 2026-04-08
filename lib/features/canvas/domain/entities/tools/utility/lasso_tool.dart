import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class LassoTool implements DrawingTool {
  @override String get id => 'lasso';
  @override String get name => 'Lasso';
  @override String get description => 'Freeform selection with marching ants and snapping';
  @override ToolCategory get category => ToolCategory.utility;
  @override IconData get icon => Icons.lasso;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => false;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final showFill = (settings.custom['showFill'] as bool?) ?? true;
    final snapToEdge = (settings.custom['snapToEdge'] as bool?) ?? false;
    final marchSpeed = (settings.custom['marchSpeed'] as double?) ?? 4.0;

    final path = Path();
    path.moveTo(points.first.x, points.first.y);
    for (int i = 1; i < points.length; i++) { path.lineTo(points[i].x, points[i].y); }
    path.close();

    // Layer 1: Selection fill
    if (showFill) {
      canvas.drawPath(path, Paint()..color = const Color(0x182196F3)..style = PaintingStyle.fill);
    }

    // Layer 2: Marching ants
    final dashPhase = (DateTime.now().millisecondsSinceEpoch / (200 / marchSpeed)) % 12.0;
    canvas.drawPath(path, Paint()
      ..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0..isAntiAlias = true);
    // Dashed overlay (approximation)
    double totalLen = 0.0;
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x; final dy = points[i].y - points[i - 1].y;
      totalLen += math.sqrt(dx * dx + dy * dy);
    }
    double cumLen = 0.0;
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1]; final p2 = points[i];
      final dx = p2.x - p1.x; final dy = p2.y - p1.y;
      final segLen = math.sqrt(dx * dx + dy * dy);
      final dashPos = (cumLen + dashPhase) % 12.0;
      if (dashPos < 6.0) {
        canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), Paint()..color = const Color(0xFF2196F3)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
      }
      cumLen += segLen;
    }

    // Layer 3: Corner handles
    if (points.length > 4) {
      for (int i = 0; i < points.length; i += math.max(1, points.length ~/ 8)) {
        final p = points[i];
        canvas.drawCircle(Offset(p.x, p.y), 3.0, Paint()..color = Colors.white..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(p.x, p.y), 3.0, Paint()..color = const Color(0xFF2196F3)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }
    }

    // Layer 4: Snap indicator
    if (snapToEdge && points.length > 3) {
      final first = points.first; final last = points.last;
      final snapDist = math.sqrt(math.pow(last.x - first.x, 2) + math.pow(last.y - first.y, 2));
      if (snapDist < 30.0) {
        canvas.drawCircle(Offset(first.x, first.y), 6.0, Paint()..color = const Color(0xFF4CAF50).withOpacity(0.5)..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(first.x, first.y), 6.0, Paint()..color = const Color(0xFF4CAF50)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }
  }

  @override
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings) {
    canvas.drawCircle(Offset(point.x, point.y), 4.0, Paint()..color = const Color(0xFF2196F3)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(point.x, point.y), 4.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  Path buildStrokePath(List<PointData> points, ToolSettings settings) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.x, points.first.y);
    for (int i = 1; i < points.length; i++) { path.lineTo(points[i].x, points[i].y); }
    path.close();
    return path;
  }

  @override double getWidth(PointData point, ToolSettings settings) => 1.5;
  @override Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints) => const Color(0xFF2196F3);
  @override double getOpacity(PointData point, ToolSettings settings) => 1.0;
  @override void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {}

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'showFill', label: 'Show Fill', type: ToolSettingType.toggle, defaultValue: true),
    ToolSettingDefinition(key: 'snapToEdge', label: 'Snap to Close', type: ToolSettingType.toggle, defaultValue: false),
    ToolSettingDefinition(key: 'marchSpeed', label: 'March Speed', type: ToolSettingType.slider, defaultValue: 4.0, min: 1.0, max: 10.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 1.5, opacity: 1.0, custom: {'showFill': true, 'snapToEdge': false, 'marchSpeed': 4.0});
}
