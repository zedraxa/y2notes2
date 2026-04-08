import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class NeonPenTool extends BaseFreehandTool {
  @override String get id => 'neon_pen';
  @override String get name => 'Neon Pen';
  @override String get description => 'Multi-layer neon glow with electric flicker';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.light_mode;
  @override BlendMode get blendMode => BlendMode.screen;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final glowIntensity = (settings.custom['glowIntensity'] as double?) ?? 0.8;
    final glowSpread = (settings.custom['glowSpread'] as double?) ?? 0.6;
    final flicker = (settings.custom['flicker'] as double?) ?? 0.2;
    final rng = math.Random(points.first.timestamp);

    // Outer glow layers (5x, 3x, 2x, 1.5x)
    for (final mult in [5.0, 3.0, 2.0, 1.5]) {
      final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.7, streamline: 0.7, simulatePressure: false);
      final glowSize = settings.size * mult * glowSpread;
      final glowOpacity = settings.opacity * 0.08 / mult * glowIntensity;
      canvas.drawPath(path, Paint()
        ..color = settings.color.withOpacity(glowOpacity.clamp(0.005, 0.4))
        ..style = PaintingStyle.stroke..strokeWidth = glowSize..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSize * 0.35)..blendMode = blendMode);
    }

    // Core stroke
    final corePath = buildFreehandPath(points, settings, thinning: 0.1, smoothing: 0.6, streamline: 0.6);
    canvas.drawPath(corePath, Paint()
      ..color = Color.lerp(settings.color, Colors.white, 0.5)!.withOpacity(settings.opacity * 0.9)
      ..style = PaintingStyle.fill..blendMode = blendMode);

    // White-hot center
    final centerPath = buildFreehandPath(points, settings, thinning: 0.15, smoothing: 0.6, streamline: 0.7);
    canvas.drawPath(centerPath, Paint()
      ..color = Colors.white.withOpacity(settings.opacity * 0.6 * glowIntensity)
      ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.2..strokeCap = StrokeCap.round..blendMode = blendMode);

    // Flicker points
    if (flicker > 0.05) {
      for (int i = 0; i < points.length; i += 3) {
        final p = points[i];
        if (rng.nextDouble() < flicker * 0.8) {
          final flickerR = settings.size * (0.3 + rng.nextDouble() * 0.6) * flicker;
          canvas.drawCircle(Offset(p.x, p.y), flickerR, Paint()..color = Colors.white.withOpacity(0.15 * flicker)..maskFilter = MaskFilter.blur(BlurStyle.normal, flickerR * 0.5)..blendMode = blendMode);
        }
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final glowSpread = (settings.custom['glowSpread'] as double?) ?? 0.6;
    if (glowSpread < 0.3) return;
    final rng = math.Random(points.first.timestamp + 77);
    for (int i = 0; i < points.length; i += 6) {
      final p = points[i];
      final dir = rng.nextDouble() * math.pi * 2;
      final dist = settings.size * 2.0 * glowSpread;
      canvas.drawCircle(Offset(p.x + math.cos(dir) * dist, p.y + math.sin(dir) * dist), settings.size * 0.3, Paint()..color = settings.color.withOpacity(0.015 * glowSpread)..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * 0.4)..blendMode = blendMode);
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'glowIntensity', label: 'Glow Intensity', type: ToolSettingType.slider, defaultValue: 0.8, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'glowSpread', label: 'Glow Spread', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'flicker', label: 'Flicker', type: ToolSettingType.slider, defaultValue: 0.2, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 4.0, opacity: 1.0, custom: {'glowIntensity': 0.8, 'glowSpread': 0.6, 'flicker': 0.2});
}
