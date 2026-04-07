import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class LaserPenTool extends BaseFreehandTool {
  @override String get id => 'laser_pen';
  @override String get name => 'Laser Pen';
  @override String get description => 'Thin bright laser beam';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.horizontal_rule;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final beamWidth = (settings.custom['beamWidth'] as double?) ?? 1.0;
    final c = settings.color;

    final glowPath = buildFreehandPath(points, settings.copyWith(size: settings.size * beamWidth * 3), thinning: 0.1, smoothing: 0.6);
    canvas.drawPath(glowPath, Paint()
      ..color = Color.fromARGB(40, c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..blendMode = blendMode);

    final corePath = buildFreehandPath(points, settings.copyWith(size: settings.size * beamWidth * 0.5), thinning: 0.0, smoothing: 0.7);
    canvas.drawPath(corePath, Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'fadeTime', label: 'Fade Time', type: ToolSettingType.slider, defaultValue: 2.0, min: 0.5, max: 10.0),
    ToolSettingDefinition(key: 'beamWidth', label: 'Beam Width', type: ToolSettingType.slider, defaultValue: 1.0, min: 0.5, max: 5.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 2.0, opacity: 1.0, custom: {'fadeTime': 2.0, 'beamWidth': 1.0});
}
