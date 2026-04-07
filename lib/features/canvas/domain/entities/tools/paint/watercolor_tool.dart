import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class WatercolorTool extends BaseFreehandTool {
  @override String get id => 'watercolor';
  @override String get name => 'Watercolor';
  @override String get description => 'Wet watercolor paint';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.opacity;
  @override BlendMode get blendMode => BlendMode.multiply;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final wetness = (settings.custom['wetness'] as double?) ?? 0.5;
    final baseOpacity = (0.15 + wetness * 0.3).clamp(0.15, 0.45);
    final c = settings.color;

    final mainPath = buildFreehandPath(points, settings, thinning: 0.2, smoothing: 0.6);
    canvas.drawPath(mainPath, Paint()
      ..color = Color.fromARGB((baseOpacity * 255).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..blendMode = blendMode
      ..isAntiAlias = true);

    canvas.drawPath(mainPath, Paint()
      ..color = Color.fromARGB(((baseOpacity * 2).clamp(0.0, 1.0) * 255).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = blendMode
      ..isAntiAlias = true);

    final granulation = (settings.custom['granulation'] as double?) ?? 0.4;
    if (granulation > 0.1 && points.length > 1) {
      final rng = math.Random(points.first.x.toInt() ^ points.first.y.toInt());
      final dotPaint = Paint()
        ..color = Color.fromARGB((granulation * 60).round(), c.red, c.green, c.blue)
        ..style = PaintingStyle.fill
        ..blendMode = blendMode;
      final step = math.max(1, (points.length / (granulation * 20)).round());
      for (int i = 0; i < points.length; i += step) {
        final p = points[i];
        final spread = settings.size * ((settings.custom['bleedSpread'] as double?) ?? 0.3) * 2;
        canvas.drawCircle(
          Offset(p.x + (rng.nextDouble() - 0.5) * spread, p.y + (rng.nextDouble() - 0.5) * spread),
          rng.nextDouble() * 2 + 0.5,
          dotPaint,
        );
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'wetness', label: 'Wetness', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'granulation', label: 'Granulation', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'bleedSpread', label: 'Bleed Spread', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'edgeDarkening', label: 'Edge Darkening', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 15.0, opacity: 0.4, custom: {'wetness': 0.5, 'granulation': 0.4, 'bleedSpread': 0.3, 'edgeDarkening': 0.5});
}
