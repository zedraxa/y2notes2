import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class FeltTipTool extends BaseFreehandTool {
  @override String get id => 'felt_tip';
  @override String get name => 'Felt Tip';
  @override String get description => 'Bold felt tip marker';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.brush;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final path = buildFreehandPath(points, settings, thinning: 0.1, smoothing: 0.4, streamline: 0.6);
    canvas.drawPath(path, Paint()
      ..color = settings.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'chiselMode', label: 'Chisel Mode', type: ToolSettingType.toggle, defaultValue: false),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 5.0, opacity: 1.0, custom: {'chiselMode': false});
}
