import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class CrayonTool extends BaseFreehandTool {
  @override String get id => 'crayon';
  @override String get name => 'Crayon';
  @override String get description => 'Waxy crayon with paper texture';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.format_color_text;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final waxiness = (settings.custom['waxiness'] as double?) ?? 0.6;
    final c = settings.color;
    final path = buildFreehandPath(points, settings, thinning: 0.1, smoothing: 0.3, simulatePressure: true);

    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB((waxiness * 180).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);

    final rng = math.Random(99);
    for (int i = 0; i < points.length; i += 3) {
      final p = points[i];
      canvas.drawCircle(
        Offset(p.x + (rng.nextDouble() - 0.5) * settings.size, p.y + (rng.nextDouble() - 0.5) * settings.size),
        rng.nextDouble() * 1.5,
        Paint()
          ..color = const Color.fromARGB(20, 255, 255, 255)
          ..blendMode = BlendMode.srcOver,
      );
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'waxiness', label: 'Waxiness', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'pressure', label: 'Pressure', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 8.0, opacity: 0.8, custom: {'waxiness': 0.6, 'pressure': 0.5});
}
