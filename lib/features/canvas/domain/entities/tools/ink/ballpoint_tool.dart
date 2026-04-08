import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class BallpointTool extends BaseFreehandTool {
  @override String get id => 'ballpoint';
  @override String get name => 'Ballpoint';
  @override String get description => 'Reliable ballpoint pen with ink density variation';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.edit;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final inkDensity = (settings.custom['inkDensity'] as double?) ?? 0.8;
    final skipThreshold = (settings.custom['skipThreshold'] as double?) ?? 0.7;
    final thinning = (settings.custom['thinning'] as double?) ?? 0.3;
    final smoothing = (settings.custom['smoothing'] as double?) ?? 0.5;

    final path = buildFreehandPath(points, settings, thinning: thinning, smoothing: smoothing);
    canvas.drawPath(path, Paint()
      ..color = settings.color.withOpacity(settings.opacity * inkDensity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);

    // Velocity-based skip gaps at high speed
    final rng = math.Random(points.first.timestamp);
    for (int i = 1; i < points.length; i++) {
      final vel = points[i].velocity;
      if (vel > skipThreshold * 15.0 && rng.nextDouble() > 0.6) {
        final p = points[i];
        final gapSize = settings.size * 0.3 * (vel / 20.0).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(p.x, p.y), gapSize,
          Paint()..color = Colors.white.withOpacity(0.3 * (1.0 - inkDensity))..blendMode = BlendMode.srcOver,
        );
      }
    }
  }

  @override
  Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints) {
    final pressureFactor = 0.7 + 0.3 * point.pressure;
    return settings.color.withOpacity(settings.opacity * pressureFactor);
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final rng = math.Random(points.first.timestamp + 42);
    final grainColor = settings.color.withOpacity(0.08);
    for (final p in points) {
      if (rng.nextDouble() > 0.6) {
        final ox = (rng.nextDouble() - 0.5) * settings.size * 0.8;
        final oy = (rng.nextDouble() - 0.5) * settings.size * 0.8;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.4, Paint()..color = grainColor);
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'inkDensity', label: 'Ink Density', type: ToolSettingType.slider, defaultValue: 0.8, min: 0.3, max: 1.0),
    ToolSettingDefinition(key: 'skipThreshold', label: 'Skip Threshold', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.2, max: 1.0),
    ToolSettingDefinition(key: 'smoothing', label: 'Smoothing', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'thinning', label: 'Thinning', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 2.0, opacity: 1.0, custom: {'inkDensity': 0.8, 'skipThreshold': 0.7, 'smoothing': 0.5, 'thinning': 0.3});
}
