import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class FountainPenTool extends BaseFreehandTool {
  @override String get id => 'fountain_pen';
  @override String get name => 'Fountain Pen';
  @override String get description => 'Classic fountain pen with ink flow dynamics';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.create;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final thinning = (settings.custom['thinning'] as double?) ?? 0.7;
    final smoothing = (settings.custom['smoothing'] as double?) ?? 0.5;
    final inkFlow = (settings.custom['inkFlow'] as double?) ?? 0.7;
    final nibCatch = (settings.custom['nibCatch'] as double?) ?? 0.4;

    final path = buildFreehandPath(points, settings, thinning: thinning, smoothing: smoothing);
    canvas.drawPath(path, Paint()..color = settings.color..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Ink flow depletion along long strokes
    if (points.length > 20) {
      final fadeStart = (points.length * inkFlow).round();
      for (int i = fadeStart; i < points.length; i++) {
        final fadeFactor = 1.0 - ((i - fadeStart) / (points.length - fadeStart)) * (1.0 - inkFlow) * 0.3;
        final p = points[i];
        canvas.drawCircle(
          Offset(p.x, p.y), settings.size * 0.2,
          Paint()..color = Colors.white.withOpacity((1.0 - fadeFactor) * 0.15)..blendMode = BlendMode.srcOver,
        );
      }
    }

    // Nib catch: ink pools at very slow points
    if (nibCatch > 0.1) {
      for (final p in points) {
        if (p.velocity < 1.5) {
          canvas.drawCircle(Offset(p.x, p.y), settings.size * 0.35 * nibCatch, Paint()..color = settings.color.withOpacity(0.2 * nibCatch));
        }
      }
    }

    // Entry swelling
    if (points.length > 3) {
      for (int i = 0; i < 4; i++) {
        final p = points[i];
        final swell = (4 - i) / 4.0 * 0.5;
        canvas.drawCircle(Offset(p.x, p.y), settings.size * (0.5 + swell), Paint()..color = settings.color.withOpacity(0.1));
      }
    }
  }

  @override
  double getWidth(PointData point, ToolSettings settings) {
    final tiltFactor = (point.tilt / (math.pi / 2)).clamp(0.3, 1.0);
    return settings.size * tiltFactor;
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'inkFlow', label: 'Ink Flow', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'thinning', label: 'Thinning', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'smoothing', label: 'Smoothing', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'nibCatch', label: 'Nib Catch', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 1.0, custom: {'inkFlow': 0.7, 'thinning': 0.7, 'smoothing': 0.5, 'nibCatch': 0.4});
}
