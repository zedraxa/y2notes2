import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class AcrylicTool extends BaseFreehandTool {
  @override String get id => 'acrylic';
  @override String get name => 'Acrylic';
  @override String get description => 'Opaque acrylic paint';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.palette;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final path = buildFreehandPath(points, settings, thinning: 0.2, smoothing: 0.4);
    final textureIntensity = (settings.custom['textureIntensity'] as double?) ?? 0.5;

    canvas.drawPath(path, Paint()
      ..color = settings.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);

    if (textureIntensity > 0) {
      canvas.drawPath(path, Paint()
        ..color = Color.fromARGB((textureIntensity * 30).round(), 255, 255, 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = settings.size * 0.15
        ..isAntiAlias = true
        ..blendMode = BlendMode.srcOver);
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'textureIntensity', label: 'Texture', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'impasto', label: 'Impasto', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 10.0, opacity: 1.0, custom: {'textureIntensity': 0.5, 'impasto': 0.3});
}
