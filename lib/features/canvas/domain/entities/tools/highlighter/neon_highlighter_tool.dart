import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class NeonHighlighterTool extends BaseFreehandTool {
  @override String get id => 'neon_highlighter';
  @override String get name => 'Neon Highlight';
  @override String get description => 'Saturated neon highlighter with glow';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.bolt;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final glowAmount = (settings.custom['glowAmount'] as double?) ?? 0.5;
    final c = settings.color;
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.4, simulatePressure: false);

    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB((glowAmount * 80).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowAmount * 6)
      ..blendMode = blendMode);

    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB(115, c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'glowAmount', label: 'Glow Amount', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 20.0, opacity: 0.45, custom: {'glowAmount': 0.5});
}
