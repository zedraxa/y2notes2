import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class EraserTool extends BaseFreehandTool {
  @override String get id => 'eraser';
  @override String get name => 'Eraser';
  @override String get description => 'Erases strokes';
  @override ToolCategory get category => ToolCategory.utility;
  @override IconData get icon => Icons.backspace_outlined;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.2, streamline: 0.4, simulatePressure: false);
    canvas.drawPath(path, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'eraserMode', label: 'Mode', type: ToolSettingType.dropdown, defaultValue: 'stroke', options: ['stroke', 'pixel']),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 25.0, opacity: 1.0, custom: {'eraserMode': 'stroke'});
}
