import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class GlowGelTool extends BaseFreehandTool {
  @override String get id => 'glow_gel';
  @override String get name => 'Glow Gel';
  @override String get description => 'Smooth gel with luminous glow and glitter sparkle';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.auto_awesome;
  @override BlendMode get blendMode => BlendMode.screen;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final glowSoftness = (settings.custom['glowSoftness'] as double?) ?? 0.6;
    final glitter = (settings.custom['glitter'] as bool?) ?? true;
    final gelThickness = (settings.custom['gelThickness'] as double?) ?? 0.5;

    // Layer 1: Soft outer glow
    final glowPath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.7, streamline: 0.7, simulatePressure: false);
    final outerBlur = settings.size * 1.5 * glowSoftness;
    canvas.drawPath(glowPath, Paint()
      ..color = settings.color.withOpacity(settings.opacity * 0.12 * glowSoftness)
      ..style = PaintingStyle.stroke..strokeWidth = settings.size * 2.5 * glowSoftness..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, outerBlur)..blendMode = blendMode);

    // Layer 2: Main gel body
    final corePath = buildFreehandPath(points, settings, thinning: 0.1 * (1.0 - gelThickness), smoothing: 0.5, streamline: 0.6);
    canvas.drawPath(corePath, Paint()
      ..color = settings.color.withOpacity(settings.opacity * (0.6 + gelThickness * 0.3))
      ..style = PaintingStyle.fill..blendMode = blendMode);

    // Layer 3: White-hot core highlight
    final highlightPath = buildFreehandPath(points, settings, thinning: 0.2, smoothing: 0.6, streamline: 0.7);
    canvas.drawPath(highlightPath, Paint()
      ..color = Colors.white.withOpacity(settings.opacity * 0.3 * gelThickness)
      ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.2..strokeCap = StrokeCap.round..blendMode = blendMode);

    // Layer 4: Gel specular spots
    for (int i = 0; i < points.length; i += 5) {
      final p = points[i];
      canvas.drawCircle(Offset(p.x, p.y - settings.size * 0.1), settings.size * 0.15 * gelThickness, Paint()..color = Colors.white.withOpacity(0.15 * gelThickness)..blendMode = blendMode);
    }

    // Layer 5: Glitter sparkle
    if (glitter) {
      final rng = math.Random(points.first.timestamp);
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i];
        if (rng.nextDouble() > 0.7) {
          final ox = (rng.nextDouble() - 0.5) * settings.size * 0.8;
          final oy = (rng.nextDouble() - 0.5) * settings.size * 0.8;
          final sparkleSize = 0.4 + rng.nextDouble() * 1.2;
          canvas.drawCircle(Offset(p.x + ox, p.y + oy), sparkleSize, Paint()..color = Colors.white.withOpacity(0.4 + rng.nextDouble() * 0.5)..blendMode = blendMode);
        }
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final glowSoftness = (settings.custom['glowSoftness'] as double?) ?? 0.6;
    if (glowSoftness < 0.3) return;
    final rng = math.Random(points.first.timestamp + 12);
    for (int i = 0; i < points.length; i += 8) {
      final p = points[i];
      final dir = rng.nextDouble() * math.pi * 2;
      final dist = settings.size * 1.5 * glowSoftness;
      canvas.drawCircle(Offset(p.x + math.cos(dir) * dist, p.y + math.sin(dir) * dist), settings.size * 0.4, Paint()..color = settings.color.withOpacity(0.02 * glowSoftness)..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * 0.5)..blendMode = blendMode);
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'glowSoftness', label: 'Glow Softness', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'gelThickness', label: 'Gel Thickness', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'glitter', label: 'Glitter', type: ToolSettingType.toggle, defaultValue: true),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 5.0, opacity: 1.0, custom: {'glowSoftness': 0.6, 'gelThickness': 0.5, 'glitter': true});
}
