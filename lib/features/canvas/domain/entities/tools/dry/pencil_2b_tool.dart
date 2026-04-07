import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class Pencil2bTool extends BaseFreehandTool {
  @override String get id => 'pencil_2b';
  @override String get name => 'Pencil 2B';
  @override String get description => 'Soft dark 2B pencil';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.edit;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final grainSize = (settings.custom['grainSize'] as double?) ?? 0.3;
    final c = settings.color;
    final path = buildFreehandPath(points, settings, thinning: 0.5, smoothing: 0.4, simulatePressure: true);
    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB(220, c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);

    if (grainSize > 0) {
      final rng = math.Random(7);
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i];
        canvas.drawCircle(
          Offset(p.x + (rng.nextDouble() - 0.5) * settings.size * 1.2, p.y + (rng.nextDouble() - 0.5) * settings.size * 1.2),
          rng.nextDouble() * grainSize * 1.5,
          Paint()
            ..color = const Color.fromARGB(15, 255, 255, 255)
            ..blendMode = BlendMode.srcOver,
        );
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'grainSize', label: 'Grain Size', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'hardness', label: 'Hardness', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 4.0, opacity: 0.9, custom: {'grainSize': 0.3, 'hardness': 0.3});
}
