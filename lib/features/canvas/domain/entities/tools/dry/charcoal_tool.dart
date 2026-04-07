import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class CharcoalTool extends BaseFreehandTool {
  @override String get id => 'charcoal';
  @override String get name => 'Charcoal';
  @override String get description => 'Heavy crumbly charcoal stick';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.texture;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final grainDensity = (settings.custom['grainDensity'] as double?) ?? 0.7;
    final spread = (settings.custom['spread'] as double?) ?? 0.5;
    final c = settings.color;
    final path = buildFreehandPath(points, settings, thinning: 0.1, smoothing: 0.3);
    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB(180, c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);

    final rng = math.Random(13);
    final grainCount = (grainDensity * points.length * 2).round();
    for (int i = 0; i < grainCount; i++) {
      final p = points[rng.nextInt(points.length)];
      final s = settings.size * spread;
      canvas.drawCircle(
        Offset(p.x + (rng.nextDouble() - 0.5) * s, p.y + (rng.nextDouble() - 0.5) * s),
        rng.nextDouble() * 2.0 + 0.3,
        Paint()
          ..color = Color.fromARGB((grainDensity * 120).round(), c.red, c.green, c.blue)
          ..blendMode = blendMode,
      );
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'grainDensity', label: 'Grain Density', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'spread', label: 'Spread', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 8.0, opacity: 0.9, custom: {'grainDensity': 0.7, 'spread': 0.5});
}
