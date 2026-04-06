import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class ChalkTool extends BaseFreehandTool {
  @override String get id => 'chalk';
  @override String get name => 'Chalk';
  @override String get description => 'Dusty chalk with noise gaps';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.fiber_manual_record_outlined;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final dustAmount = (settings.custom['dustAmount'] as double?) ?? 0.5;
    final coverage = (settings.custom['coverage'] as double?) ?? 0.6;
    final c = settings.color;
    final rng = math.Random(77);

    for (int i = 0; i < points.length; i++) {
      if (rng.nextDouble() > coverage) continue;
      final p = points[i];
      canvas.drawCircle(
        Offset(p.x + (rng.nextDouble() - 0.5) * dustAmount * 3, p.y + (rng.nextDouble() - 0.5) * dustAmount * 3),
        settings.size * 0.4 * (0.5 + rng.nextDouble() * 0.5),
        Paint()
          ..color = Color.fromARGB((coverage * 200).round(), c.red, c.green, c.blue)
          ..style = PaintingStyle.fill
          ..blendMode = blendMode,
      );
    }

    for (int i = 0; i < points.length; i += 5) {
      final p = points[i];
      for (int d = 0; d < (dustAmount * 5).round(); d++) {
        canvas.drawCircle(
          Offset(p.x + (rng.nextDouble() - 0.5) * settings.size * 3, p.y + (rng.nextDouble() - 0.5) * settings.size * 3),
          rng.nextDouble() * 0.8,
          Paint()
            ..color = Color.fromARGB(30, c.red, c.green, c.blue)
            ..blendMode = blendMode,
        );
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'dustAmount', label: 'Dust Amount', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'coverage', label: 'Coverage', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 10.0, opacity: 0.8, custom: {'dustAmount': 0.5, 'coverage': 0.6});
}
