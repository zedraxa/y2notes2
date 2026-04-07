import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class FountainPenTool extends BaseFreehandTool {
  @override String get id => 'fountain_pen';
  @override String get name => 'Fountain Pen';
  @override String get description => 'Classic fountain pen with pressure sensitivity';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.create;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final thinning = (settings.custom['thinning'] as double?) ?? 0.7;
    final smoothing = (settings.custom['smoothing'] as double?) ?? 0.5;
    final path = buildFreehandPath(points, settings, thinning: thinning, smoothing: smoothing);
    canvas.drawPath(path, Paint()
      ..color = settings.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'inkFlow', label: 'Ink Flow', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'thinning', label: 'Thinning', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'smoothing', label: 'Smoothing', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 1.0, custom: {'inkFlow': 0.7, 'thinning': 0.7, 'smoothing': 0.5});
}
