import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class PastelTool extends BaseFreehandTool {
  @override String get id => 'pastel';
  @override String get name => 'Pastel';
  @override String get description => 'Soft pastel with luminous blending and layering';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.auto_awesome;
  @override BlendMode get blendMode => BlendMode.screen;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final chalkiness = (settings.custom['chalkiness'] as double?) ?? 0.5;
    final spread = (settings.custom['spread'] as double?) ?? 0.6;
    final layering = (settings.custom['layering'] as double?) ?? 0.5;

    // Layer 1: Soft blurred base
    final path = buildFreehandPath(points, settings, thinning: 0.05, smoothing: 0.5, streamline: 0.6);
    final blur = settings.size * 0.15 * (1.0 + spread * 0.5);
    canvas.drawPath(path, Paint()
      ..color = settings.color.withOpacity(settings.opacity * (0.4 + layering * 0.3))
      ..style = PaintingStyle.fill..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)..blendMode = blendMode);

    // Layer 2: Solid core
    if (layering > 0.3) {
      final corePath = buildFreehandPath(points, settings, thinning: 0.1, smoothing: 0.5);
      canvas.drawPath(corePath, Paint()..color = settings.color.withOpacity(settings.opacity * layering * 0.4)..style = PaintingStyle.fill..blendMode = blendMode);
    }

    // Layer 3: Chalky particles
    if (chalkiness > 0.2) {
      final rng = math.Random(points.first.timestamp);
      for (final p in points) {
        for (int g = 0; g < (chalkiness * 8).round(); g++) {
          final ox = (rng.nextDouble() - 0.5) * settings.size * (1.0 + spread * 0.5);
          final oy = (rng.nextDouble() - 0.5) * settings.size * (1.0 + spread * 0.5);
          canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.3 + rng.nextDouble() * 0.8, Paint()..color = settings.color.withOpacity(0.06 * chalkiness));
        }
      }
    }

    // Layer 4: Luminous edge glow
    if (spread > 0.3) {
      for (int i = 0; i < points.length; i += 3) {
        final p = points[i]; final glowR = settings.size * 0.6 * spread;
        canvas.drawCircle(Offset(p.x, p.y), glowR, Paint()..color = settings.color.withOpacity(0.03 * spread)..maskFilter = MaskFilter.blur(BlurStyle.normal, glowR * 0.4));
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final chalkiness = (settings.custom['chalkiness'] as double?) ?? 0.5;
    if (chalkiness < 0.2) return;
    final rng = math.Random(points.first.timestamp + 5);
    for (int i = 0; i < points.length; i += 5) {
      final p = points[i];
      for (int d = 0; d < 3; d++) {
        final dir = rng.nextDouble() * math.pi * 2;
        final dist = settings.size * (0.5 + rng.nextDouble() * 0.8);
        canvas.drawCircle(Offset(p.x + math.cos(dir) * dist, p.y + math.sin(dir) * dist), 0.3 + rng.nextDouble() * 0.4, Paint()..color = settings.color.withOpacity(0.025 * chalkiness));
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'chalkiness', label: 'Chalkiness', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'spread', label: 'Spread', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'layering', label: 'Layering', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 12.0, opacity: 0.7, custom: {'chalkiness': 0.5, 'spread': 0.6, 'layering': 0.5});
}
