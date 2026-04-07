import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class GradientHighlighterTool extends BaseFreehandTool {
  @override String get id => 'gradient_highlighter';
  @override String get name => 'Gradient Highlighter';
  @override String get description => 'Fading gradient highlighter with direction-aware opacity';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.gradient;
  @override BlendMode get blendMode => BlendMode.multiply;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final gradientAngle = (settings.custom['gradientAngle'] as double?) ?? 0.0;
    final fadeStrength = (settings.custom['fadeStrength'] as double?) ?? 0.7;
    final softEdge = (settings.custom['softEdge'] as double?) ?? 0.3;

    // Layer 1: Soft outer edge
    if (softEdge > 0.1) {
      final edgePath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.8, streamline: 0.8, simulatePressure: false);
      canvas.drawPath(edgePath, Paint()
        ..color = settings.color.withOpacity(settings.opacity * 0.1 * softEdge)
        ..style = PaintingStyle.stroke..strokeWidth = settings.size * (1.0 + softEdge * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * 0.2 * softEdge)..blendMode = blendMode);
    }

    // Layer 2: Gradient fading segments
    final angleRad = gradientAngle * math.pi / 180.0;
    double minProj = double.infinity; double maxProj = -double.infinity;
    for (final p in points) {
      final proj = p.x * math.cos(angleRad) + p.y * math.sin(angleRad);
      if (proj < minProj) minProj = proj;
      if (proj > maxProj) maxProj = proj;
    }
    final range = maxProj - minProj;
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1]; final p2 = points[i];
      final proj = p2.x * math.cos(angleRad) + p2.y * math.sin(angleRad);
      final t = range > 0 ? ((proj - minProj) / range).clamp(0.0, 1.0) : 0.5;
      final segOpacity = settings.opacity * (1.0 - t * fadeStrength);
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), Paint()
        ..color = settings.color.withOpacity(segOpacity.clamp(0.01, 1.0))
        ..strokeWidth = settings.size..strokeCap = StrokeCap.round..blendMode = blendMode);
    }

    // Layer 3: Smooth fill path
    final fillPath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.7, streamline: 0.8, simulatePressure: false);
    canvas.drawPath(fillPath, Paint()
      ..color = settings.color.withOpacity(settings.opacity * 0.2)
      ..style = PaintingStyle.fill..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'gradientAngle', label: 'Gradient Angle', type: ToolSettingType.slider, defaultValue: 0.0, min: 0.0, max: 360.0),
    ToolSettingDefinition(key: 'fadeStrength', label: 'Fade Strength', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'softEdge', label: 'Soft Edge', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 18.0, opacity: 0.4, custom: {'gradientAngle': 0.0, 'fadeStrength': 0.7, 'softEdge': 0.3});
}
