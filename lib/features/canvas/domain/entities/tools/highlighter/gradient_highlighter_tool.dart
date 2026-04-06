import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class GradientHighlighterTool extends BaseFreehandTool {
  @override String get id => 'gradient_highlighter';
  @override String get name => 'Gradient Hi';
  @override String get description => 'Opacity-fading gradient highlighter';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.gradient;
  @override BlendMode get blendMode => BlendMode.multiply;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final gradientAngle = ((settings.custom['gradientAngle'] as double?) ?? 90.0) * math.pi / 180.0;
    final c = settings.color;

    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.4, simulatePressure: false);

    double minX = points[0].x, maxX = points[0].x, minY = points[0].y, maxY = points[0].y;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    final bounds = Rect.fromLTRB(minX, minY, maxX + 1, maxY + 1);

    final gradPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.fromARGB(102, c.red, c.green, c.blue),
          Color.fromARGB(0, c.red, c.green, c.blue),
        ],
        begin: Alignment(math.cos(gradientAngle), math.sin(gradientAngle)),
        end: Alignment(-math.cos(gradientAngle), -math.sin(gradientAngle)),
      ).createShader(bounds)
      ..style = PaintingStyle.fill
      ..blendMode = blendMode;

    canvas.drawPath(path, gradPaint);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'gradientAngle', label: 'Gradient Angle', type: ToolSettingType.slider, defaultValue: 90.0, min: 0.0, max: 360.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 20.0, opacity: 0.4, custom: {'gradientAngle': 90.0});
}
