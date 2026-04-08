import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class CharcoalTool extends BaseFreehandTool {
  @override String get id => 'charcoal';
  @override String get name => 'Charcoal';
  @override String get description => 'Rich charcoal with smear and pressure breakpoint';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.gesture;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final grainDensity = (settings.custom['grainDensity'] as double?) ?? 0.6;
    final spread = (settings.custom['spread'] as double?) ?? 0.5;
    final breakpoint = (settings.custom['breakpoint'] as double?) ?? 0.7;

    // Layer 1: Base charcoal stroke
    final path = buildFreehandPath(points, settings, thinning: 0.2, smoothing: 0.3, streamline: 0.3);
    canvas.drawPath(path, Paint()..color = settings.color.withOpacity(settings.opacity * 0.8)..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 2: Dense particle grain
    final rng = math.Random(points.first.timestamp);
    for (final p in points) {
      for (int g = 0; g < (grainDensity * 15).round(); g++) {
        final ox = (rng.nextDouble() - 0.5) * settings.size * (1.0 + spread);
        final oy = (rng.nextDouble() - 0.5) * settings.size * (1.0 + spread);
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.3 + rng.nextDouble() * 1.0, Paint()..color = settings.color.withOpacity(0.08 * grainDensity * p.pressure));
      }
    }

    // Layer 3: Pressure breakpoint shattering
    for (final p in points) {
      if (p.pressure > breakpoint && breakpoint < 1.0) {
        final excess = (p.pressure - breakpoint) / (1.0 - breakpoint);
        for (int c = 0; c < (excess * 8).round(); c++) {
          final angle = rng.nextDouble() * math.pi * 2;
          final dist = settings.size * (0.3 + rng.nextDouble() * 0.8);
          canvas.drawCircle(Offset(p.x + math.cos(angle) * dist, p.y + math.sin(angle) * dist), 0.5 + rng.nextDouble() * 1.5 * excess, Paint()..color = settings.color.withOpacity(0.15 * excess));
        }
      }
    }

    // Layer 4: Smear effect
    if (spread > 0.3) {
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i]; final sr = settings.size * 0.5 * spread;
        canvas.drawCircle(Offset(p.x, p.y), sr, Paint()..color = settings.color.withOpacity(0.06 * spread)..maskFilter = MaskFilter.blur(BlurStyle.normal, sr * 0.5));
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final rng = math.Random(points.first.timestamp + 9);
    final spread = (settings.custom['spread'] as double?) ?? 0.5;
    for (int i = 0; i < points.length; i += 4) {
      final p = points[i]; final dir = rng.nextDouble() * math.pi * 2;
      final dist = settings.size * (0.6 + rng.nextDouble() * 0.8) * spread;
      canvas.drawCircle(Offset(p.x + math.cos(dir) * dist, p.y + math.sin(dir) * dist), 0.3 + rng.nextDouble() * 0.5, Paint()..color = settings.color.withOpacity(0.03 * spread));
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'grainDensity', label: 'Grain Density', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'spread', label: 'Spread', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'breakpoint', label: 'Breakpoint', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.3, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 8.0, opacity: 1.0, custom: {'grainDensity': 0.6, 'spread': 0.5, 'breakpoint': 0.7});
}
