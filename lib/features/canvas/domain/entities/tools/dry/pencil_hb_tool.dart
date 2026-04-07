import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class PencilHbTool extends BaseFreehandTool {
  @override String get id => 'pencil_hb';
  @override String get name => 'Pencil HB';
  @override String get description => 'Standard HB pencil with paper grain';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.edit_outlined;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final grainSize = (settings.custom['grainSize'] as double?) ?? 0.5;
    final hardness = (settings.custom['hardness'] as double?) ?? 0.5;
    final c = settings.color;

    final path = buildFreehandPath(points, settings, thinning: 0.4, smoothing: 0.5, simulatePressure: true);
    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB(((0.4 + hardness * 0.4) * 255).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);

    if (grainSize > 0 && points.length > 1) {
      final rng = math.Random(42);
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i];
        canvas.drawCircle(
          Offset(p.x + (rng.nextDouble() - 0.5) * settings.size, p.y + (rng.nextDouble() - 0.5) * settings.size),
          rng.nextDouble() * grainSize,
          Paint()
            ..color = Color.fromARGB((grainSize * 30).round(), 255, 255, 255)
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.srcOver,
        );
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'grainSize', label: 'Grain Size', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'hardness', label: 'Hardness', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 0.8, custom: {'grainSize': 0.5, 'hardness': 0.5});
}
