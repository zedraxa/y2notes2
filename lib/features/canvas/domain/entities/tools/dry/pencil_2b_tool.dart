import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class Pencil2bTool extends BaseFreehandTool {
  @override String get id => 'pencil_2b';
  @override String get name => 'Pencil 2B';
  @override String get description => 'Soft dark pencil with rich graphite layering';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.edit;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final grainSize = (settings.custom['grainSize'] as double?) ?? 0.6;
    final smudge = (settings.custom['smudgePotential'] as double?) ?? 0.4;

    // Layer 1: Base soft stroke
    final path = buildFreehandPath(points, settings, thinning: 0.4, smoothing: 0.5, streamline: 0.4);
    canvas.drawPath(path, Paint()..color = settings.color.withOpacity(settings.opacity * 0.85)..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 2: Dense graphite grain
    final rng = math.Random(points.first.timestamp);
    for (final p in points) {
      for (int g = 0; g < (grainSize * 10).round(); g++) {
        final ox = (rng.nextDouble() - 0.5) * settings.size * 1.4;
        final oy = (rng.nextDouble() - 0.5) * settings.size * 1.4;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.3 + rng.nextDouble() * 0.7 * grainSize, Paint()..color = settings.color.withOpacity(0.05 + rng.nextDouble() * 0.1 * p.pressure));
      }
    }

    // Layer 3: Graphite sheen at heavy pressure
    for (int i = 0; i < points.length; i += 4) {
      final p = points[i];
      if (p.pressure > 0.6) {
        canvas.drawCircle(Offset(p.x, p.y), settings.size * 0.25, Paint()..color = Colors.white.withOpacity(0.04 * p.pressure));
      }
    }

    // Layer 4: Smudge halo
    if (smudge > 0.2) {
      for (int i = 0; i < points.length; i += 3) {
        final p = points[i]; final sr = settings.size * 0.4 * smudge;
        canvas.drawCircle(Offset(p.x, p.y), sr, Paint()..color = settings.color.withOpacity(0.04 * smudge)..maskFilter = MaskFilter.blur(BlurStyle.normal, sr * 0.6));
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final rng = math.Random(points.first.timestamp + 17);
    for (int i = 0; i < points.length; i += 4) {
      final p = points[i];
      if (rng.nextDouble() > 0.7) {
        final ox = (rng.nextDouble() - 0.5) * settings.size;
        final oy = (rng.nextDouble() - 0.5) * settings.size;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.2 + rng.nextDouble() * 0.3, Paint()..color = Colors.white.withOpacity(0.05));
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'grainSize', label: 'Grain Size', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'smudgePotential', label: 'Smudge Potential', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 4.0, opacity: 1.0, custom: {'grainSize': 0.6, 'smudgePotential': 0.4});
}
