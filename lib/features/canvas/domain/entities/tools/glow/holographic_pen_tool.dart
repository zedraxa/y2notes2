import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class HolographicPenTool extends BaseFreehandTool {
  @override String get id => 'holographic_pen';
  @override String get name => 'Holographic';
  @override String get description => 'Rainbow hue-shifting holographic pen';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.blur_on;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final shiftSpeed = (settings.custom['shiftSpeed'] as double?) ?? 1.0;
    final saturation = (settings.custom['saturation'] as double?) ?? 1.0;

    double cumulativeDist = 0.0;
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;
      cumulativeDist += math.sqrt(dx * dx + dy * dy);
      final hue = (cumulativeDist * 1.8 * shiftSpeed) % 360;
      final color = HSVColor.fromAHSV(1.0, hue, saturation, 1.0).toColor();
      final segPath = buildFreehandPath([p1, p2], settings.copyWith(color: color), thinning: 0.4, smoothing: 0.5);
      canvas.drawPath(segPath, Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..blendMode = blendMode);
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'shiftSpeed', label: 'Shift Speed', type: ToolSettingType.slider, defaultValue: 1.0, min: 0.0, max: 5.0),
    ToolSettingDefinition(key: 'saturation', label: 'Saturation', type: ToolSettingType.slider, defaultValue: 1.0, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 1.0, custom: {'shiftSpeed': 1.0, 'saturation': 1.0});
}
