import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class ColoredPencilTool extends BaseFreehandTool {
  @override String get id => 'colored_pencil';
  @override String get name => 'Colored Pencil';
  @override String get description => 'Vivid colored pencil with wax bloom and burnishing';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.color_lens;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final layering = (settings.custom['layering'] as double?) ?? 0.5;
    final grainFine = (settings.custom['grainFine'] as double?) ?? 0.5;
    final burnishing = (settings.custom['burnishing'] as double?) ?? 0.3;

    // Layer 1: Semi-transparent base
    final path = buildFreehandPath(points, settings, thinning: 0.35, smoothing: 0.5, streamline: 0.5);
    canvas.drawPath(path, Paint()..color = settings.color.withOpacity(settings.opacity * (0.3 + layering * 0.4))..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 2: Second layering pass
    if (layering > 0.4) {
      canvas.drawPath(path, Paint()..color = settings.color.withOpacity(settings.opacity * (layering - 0.4) * 0.5)..style = PaintingStyle.fill..isAntiAlias = true);
    }

    // Layer 3: Fine grain texture
    final rng = math.Random(points.first.timestamp);
    for (final p in points) {
      for (int g = 0; g < (grainFine * 6).round(); g++) {
        final ox = (rng.nextDouble() - 0.5) * settings.size * 0.8;
        final oy = (rng.nextDouble() - 0.5) * settings.size * 0.8;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.15 + rng.nextDouble() * 0.35 * grainFine, Paint()..color = settings.color.withOpacity(0.05 * grainFine * p.pressure));
      }
    }

    // Layer 4: Wax bloom
    if (layering > 0.6) {
      for (int i = 0; i < points.length; i += 4) {
        final p = points[i];
        canvas.drawCircle(Offset(p.x, p.y), settings.size * 0.3, Paint()..color = Colors.white.withOpacity(0.02 * (layering - 0.6) / 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0));
      }
    }

    // Layer 5: Burnishing
    if (burnishing > 0.2) {
      for (final p in points) {
        if (p.pressure > 0.7) {
          final bi = (p.pressure - 0.7) / 0.3 * burnishing;
          canvas.drawCircle(Offset(p.x, p.y), settings.size * 0.3, Paint()..color = settings.color.withOpacity(0.08 * bi)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8));
          canvas.drawCircle(Offset(p.x, p.y), settings.size * 0.15, Paint()..color = Colors.white.withOpacity(0.03 * bi));
        }
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final rng = math.Random(points.first.timestamp + 19);
    for (int i = 0; i < points.length; i += 3) {
      final p = points[i];
      if (p.pressure < 0.5 && rng.nextDouble() > 0.5) {
        final ox = (rng.nextDouble() - 0.5) * settings.size;
        final oy = (rng.nextDouble() - 0.5) * settings.size;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.2 + rng.nextDouble() * 0.3, Paint()..color = Colors.white.withOpacity(0.06 * (1.0 - p.pressure)));
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'layering', label: 'Layering', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'grainFine', label: 'Grain Fine', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'burnishing', label: 'Burnishing', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 0.5, custom: {'layering': 0.5, 'grainFine': 0.5, 'burnishing': 0.3});
}
