import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class GouacheTool extends BaseFreehandTool {
  @override String get id => 'gouache';
  @override String get name => 'Gouache';
  @override String get description => 'Flat opaque gouache paint';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.brush;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.4, streamline: 0.7);
    canvas.drawPath(path, Paint()
      ..color = settings.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'flatness', label: 'Flatness', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'coverage', label: 'Coverage', type: ToolSettingType.slider, defaultValue: 0.8, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 10.0, opacity: 1.0, custom: {'flatness': 0.7, 'coverage': 0.8});
}
