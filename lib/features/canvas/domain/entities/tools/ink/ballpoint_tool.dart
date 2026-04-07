import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class BallpointTool extends BaseFreehandTool {
  @override String get id => 'ballpoint';
  @override String get name => 'Ballpoint';
  @override String get description => 'Reliable ballpoint pen';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.edit;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final thinning = (settings.custom['thinning'] as double?) ?? 0.3;
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
    ToolSettingDefinition(key: 'smoothing', label: 'Smoothing', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'thinning', label: 'Thinning', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 2.0, opacity: 1.0, custom: {'smoothing': 0.5, 'thinning': 0.3});
}
