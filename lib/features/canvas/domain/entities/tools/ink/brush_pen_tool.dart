import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class BrushPenTool extends BaseFreehandTool {
  @override String get id => 'brush_pen';
  @override String get name => 'Brush Pen';
  @override String get description => 'Pressure-sensitive brush pen with spring dynamics';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.brush;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final springiness = (settings.custom['springiness'] as double?) ?? 0.3;
    final inkPooling = (settings.custom['inkPooling'] as double?) ?? 0.5;

    final avgVelocity = points.fold<double>(0.0, (s, p) => s + p.velocity) / points.length;
    final dynamicThinning = (0.5 + 0.4 * (avgVelocity / 10.0)).clamp(0.4, 0.95);

    final path = buildFreehandPath(points, settings,
      thinning: dynamicThinning,
      smoothing: 0.4 + springiness * 0.4,
      streamline: 0.3 + springiness * 0.3,
    );
    canvas.drawPath(path, Paint()
      ..color = settings.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);

    // Ink pooling at stroke start and end
    if (inkPooling > 0.1 && points.length >= 2) {
      final poolPaint = Paint()
        ..color = settings.color.withOpacity(0.3 * inkPooling)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      final start = points.first;
      canvas.drawCircle(Offset(start.x, start.y), settings.size * 0.6 * inkPooling * start.pressure, poolPaint);
      final end = points.last;
      canvas.drawCircle(Offset(end.x, end.y), settings.size * 0.5 * inkPooling * end.pressure, poolPaint);
    }
  }

  @override
  double getWidth(PointData point, ToolSettings settings) {
    final pressureRange = (settings.custom['pressureRange'] as double?) ?? 5.0;
    final springiness = (settings.custom['springiness'] as double?) ?? 0.3;
    final velocityDamping = 1.0 - (point.velocity / 20.0).clamp(0.0, 0.5) * springiness;
    return settings.size * (0.5 + pressureRange * point.pressure * 0.1).clamp(0.5, 4.0) * velocityDamping;
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 3) return;
    final inkPooling = (settings.custom['inkPooling'] as double?) ?? 0.5;
    if (inkPooling < 0.2) return;
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];
      final a1 = math.atan2(curr.y - prev.y, curr.x - prev.x);
      final a2 = math.atan2(next.y - curr.y, next.x - curr.x);
      var diff = (a2 - a1).abs();
      if (diff > math.pi) diff = 2 * math.pi - diff;
      if (diff > math.pi * 0.4) {
        canvas.drawCircle(
          Offset(curr.x, curr.y),
          settings.size * 0.3 * inkPooling,
          Paint()..color = settings.color.withOpacity(0.15 * inkPooling),
        );
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'springiness', label: 'Springiness', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'pressureRange', label: 'Pressure Range', type: ToolSettingType.slider, defaultValue: 5.0, min: 1.0, max: 10.0),
    ToolSettingDefinition(key: 'inkPooling', label: 'Ink Pooling', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 6.0, opacity: 1.0, custom: {'springiness': 0.3, 'pressureRange': 5.0, 'inkPooling': 0.5});
}
