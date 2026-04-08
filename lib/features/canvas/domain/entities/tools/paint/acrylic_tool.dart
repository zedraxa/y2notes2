import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class AcrylicTool extends BaseFreehandTool {
  @override String get id => 'acrylic';
  @override String get name => 'Acrylic';
  @override String get description => 'Thick acrylic paint with impasto texture';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.format_paint;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final textureIntensity = (settings.custom['textureIntensity'] as double?) ?? 0.5;
    final impasto = (settings.custom['impasto'] as double?) ?? 0.5;
    final dryBrush = (settings.custom['dryBrush'] as double?) ?? 0.0;

    // Layer 1: Base opaque body
    final path = buildFreehandPath(points, settings, thinning: 0.05, smoothing: 0.3, streamline: 0.5);
    canvas.drawPath(path, Paint()
      ..color = settings.color.withOpacity(settings.opacity * (1.0 - dryBrush * 0.4))
      ..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 2: Impasto highlights
    if (impasto > 0.2) {
      final rng = math.Random(points.first.timestamp);
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i];
        if (rng.nextDouble() < impasto * 0.6) {
          final highlight = settings.size * 0.15 * impasto * p.pressure;
          final ox = (rng.nextDouble() - 0.5) * settings.size * 0.3;
          final oy = (rng.nextDouble() - 0.5) * settings.size * 0.3;
          canvas.drawCircle(Offset(p.x + ox, p.y + oy - highlight * 0.5), highlight + 0.3, Paint()..color = Colors.white.withOpacity(0.12 * impasto));
        }
      }
    }

    // Layer 3: Palette knife edge
    if (impasto > 0.3) {
      final edgePath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.3);
      canvas.drawPath(edgePath, Paint()
        ..color = settings.color.withOpacity(0.15 * impasto)
        ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.08 * impasto..isAntiAlias = true);
    }

    // Layer 4: Dry brush streaks
    if (dryBrush > 0.2) {
      final rng = math.Random(points.first.timestamp + 99);
      for (final p in points) {
        if (rng.nextDouble() < dryBrush * 0.5) {
          final ox = (rng.nextDouble() - 0.5) * settings.size * 0.6;
          canvas.drawRect(
            Rect.fromCenter(center: Offset(p.x + ox, p.y), width: settings.size * 0.2 * dryBrush, height: 1.0),
            Paint()..color = Colors.white.withOpacity(0.25 * dryBrush)..blendMode = BlendMode.srcOver,
          );
        }
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final textureIntensity = (settings.custom['textureIntensity'] as double?) ?? 0.5;
    if (textureIntensity < 0.1) return;
    final rng = math.Random(points.first.timestamp + 13);
    for (final p in points) {
      if (rng.nextDouble() < textureIntensity * 0.4) {
        final ox = (rng.nextDouble() - 0.5) * settings.size;
        final oy = (rng.nextDouble() - 0.5) * settings.size;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.3 + rng.nextDouble() * 0.4, Paint()..color = Colors.white.withOpacity(0.06 * textureIntensity));
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'textureIntensity', label: 'Texture', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'impasto', label: 'Impasto', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'dryBrush', label: 'Dry Brush', type: ToolSettingType.slider, defaultValue: 0.0, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 10.0, opacity: 1.0, custom: {'textureIntensity': 0.5, 'impasto': 0.5, 'dryBrush': 0.0});
}
