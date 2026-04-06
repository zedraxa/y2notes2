import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class NeonPenTool extends BaseFreehandTool {
  @override String get id => 'neon_pen';
  @override String get name => 'Neon Pen';
  @override String get description => 'Glowing neon pen with multiple glow layers';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.light_mode;
  @override BlendMode get blendMode => BlendMode.srcOver;

  Path _buildLayerPath(List<PointData> points, double sizeFactor, ToolSettings settings) =>
      buildFreehandPath(
        points,
        settings.copyWith(size: settings.size * sizeFactor),
        thinning: 0.3,
        smoothing: 0.5,
      );

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final glowIntensity = (settings.custom['glowIntensity'] as double?) ?? 0.7;
    final glowSpread = (settings.custom['glowSpread'] as double?) ?? 5.0;
    final c = settings.color;

    canvas.drawPath(_buildLayerPath(points, 5.0, settings), Paint()
      ..color = Color.fromARGB((glowIntensity * 13).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSpread * 2)
      ..blendMode = blendMode);

    canvas.drawPath(_buildLayerPath(points, 3.0, settings), Paint()
      ..color = Color.fromARGB((glowIntensity * 38).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSpread)
      ..blendMode = blendMode);

    canvas.drawPath(_buildLayerPath(points, 1.5, settings), Paint()
      ..color = Color.fromARGB((glowIntensity * 102).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSpread * 0.5)
      ..blendMode = blendMode);

    final coreColor = Color.fromARGB(
      255,
      (c.red + (255 - c.red) * 0.6).round(),
      (c.green + (255 - c.green) * 0.6).round(),
      (c.blue + (255 - c.blue) * 0.6).round(),
    );
    canvas.drawPath(_buildLayerPath(points, 0.6, settings), Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'glowIntensity', label: 'Glow Intensity', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'glowSpread', label: 'Glow Spread', type: ToolSettingType.slider, defaultValue: 5.0, min: 1.0, max: 10.0),
    ToolSettingDefinition(key: 'flicker', label: 'Flicker', type: ToolSettingType.toggle, defaultValue: false),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 1.0, custom: {'glowIntensity': 0.7, 'glowSpread': 5.0, 'flicker': false});
}
