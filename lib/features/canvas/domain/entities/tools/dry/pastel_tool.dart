import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class PastelTool extends BaseFreehandTool {
  @override String get id => 'pastel';
  @override String get name => 'Pastel';
  @override String get description => 'Soft chalky pastel stick';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.gradient;
  @override BlendMode get blendMode => BlendMode.screen;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final chalkiness = (settings.custom['chalkiness'] as double?) ?? 0.6;
    final spread = (settings.custom['spread'] as double?) ?? 0.4;
    final c = settings.color;

    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.5);
    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB((chalkiness * 150).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, spread * 3));
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'chalkiness', label: 'Chalkiness', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'spread', label: 'Spread', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 12.0, opacity: 0.7, custom: {'chalkiness': 0.6, 'spread': 0.4});
}
