import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class SoftHighlighterTool extends BaseFreehandTool {
  @override String get id => 'soft_highlighter';
  @override String get name => 'Soft Highlight';
  @override String get description => 'Feathered soft highlighter';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.blur_on;
  @override BlendMode get blendMode => BlendMode.multiply;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final featherAmount = (settings.custom['featherAmount'] as double?) ?? 0.5;
    final c = settings.color;
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.5, simulatePressure: false);
    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB(64, c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, featherAmount * 4)
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'featherAmount', label: 'Feather', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 20.0, opacity: 0.25, custom: {'featherAmount': 0.5});
}
