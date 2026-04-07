import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class CalligraphyTool extends BaseFreehandTool {
  @override String get id => 'calligraphy';
  @override String get name => 'Calligraphy';
  @override String get description => 'Angle-sensitive calligraphy nib';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.create;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final nibAngle = ((settings.custom['nibAngle'] as double?) ?? 45.0) * math.pi / 180.0;
    final paint = Paint()
      ..color = settings.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode;

    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;
      final angle = math.atan2(dy, dx);
      final angleDiff = (angle - nibAngle).abs();
      final width = settings.size * (0.15 + 0.85 * math.sin(angleDiff).abs().clamp(0.0, 1.0));
      final perp = Offset(-math.sin(angle) * width * 0.5, math.cos(angle) * width * 0.5);
      final path = Path()
        ..moveTo(p1.x + perp.dx, p1.y + perp.dy)
        ..lineTo(p2.x + perp.dx, p2.y + perp.dy)
        ..lineTo(p2.x - perp.dx, p2.y - perp.dy)
        ..lineTo(p1.x - perp.dx, p1.y - perp.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'nibAngle', label: 'Nib Angle', type: ToolSettingType.slider, defaultValue: 45.0, min: 0.0, max: 180.0),
    ToolSettingDefinition(key: 'flexibility', label: 'Flexibility', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 4.0, opacity: 1.0, custom: {'nibAngle': 45.0, 'flexibility': 0.5});
}
