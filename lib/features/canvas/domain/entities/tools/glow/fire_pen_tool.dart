import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class FirePenTool extends BaseFreehandTool {
  @override String get id => 'fire_pen';
  @override String get name => 'Fire Pen';
  @override String get description => 'Fiery gradient pen';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.whatshot;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final flameIntensity = (settings.custom['flameIntensity'] as double?) ?? 0.7;

    for (int i = 1; i < points.length; i++) {
      final t = i / (points.length - 1);
      final hue = t * 40.0;
      final color = HSVColor.fromAHSV(1.0, hue, 1.0, flameIntensity + (1 - flameIntensity) * t).toColor();
      final p1 = points[i - 1];
      final p2 = points[i];
      final segPath = buildFreehandPath([p1, p2], settings.copyWith(color: color), thinning: 0.5, smoothing: 0.4);
      canvas.drawPath(segPath, Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..blendMode = blendMode);
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'flameIntensity', label: 'Flame Intensity', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'flameHeight', label: 'Flame Height', type: ToolSettingType.slider, defaultValue: 40.0, min: 10.0, max: 100.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 4.0, opacity: 1.0, custom: {'flameIntensity': 0.7, 'flameHeight': 40.0});
}
