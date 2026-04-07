import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class ColoredPencilTool extends BaseFreehandTool {
  @override String get id => 'colored_pencil';
  @override String get name => 'Colored Pencil';
  @override String get description => 'Semi-transparent colored pencil';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.colorize;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final layering = (settings.custom['layering'] as double?) ?? 0.4;
    final grainFine = (settings.custom['grainFine'] as double?) ?? 0.4;
    final opacity = (0.2 + layering * 0.4).clamp(0.2, 0.6);
    final c = settings.color;
    final path = buildFreehandPath(points, settings, thinning: 0.3, smoothing: 0.6);
    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB((opacity * 255).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);

    if (grainFine > 0) {
      final rng = math.Random(55);
      for (int i = 0; i < points.length; i += 3) {
        final p = points[i];
        canvas.drawCircle(
          Offset(p.x + (rng.nextDouble() - 0.5) * settings.size * 0.8, p.y + (rng.nextDouble() - 0.5) * settings.size * 0.8),
          rng.nextDouble() * grainFine * 0.8,
          Paint()
            ..color = const Color.fromARGB(10, 255, 255, 255)
            ..blendMode = BlendMode.srcOver,
        );
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'layering', label: 'Layering', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'grainFine', label: 'Fine Grain', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 0.5, custom: {'layering': 0.4, 'grainFine': 0.4});
}
