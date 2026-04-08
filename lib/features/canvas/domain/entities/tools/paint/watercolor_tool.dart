import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class WatercolorTool extends BaseFreehandTool {
  @override String get id => 'watercolor';
  @override String get name => 'Watercolor';
  @override String get description => 'Translucent watercolor with wet blending and granulation';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.water_drop;
  @override BlendMode get blendMode => BlendMode.multiply;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final wetness = (settings.custom['wetness'] as double?) ?? 0.6;
    final granulation = (settings.custom['granulation'] as double?) ?? 0.4;
    final bleedSpread = (settings.custom['bleedSpread'] as double?) ?? 0.5;
    final edgeDarkening = (settings.custom['edgeDarkening'] as double?) ?? 0.3;
    final pigmentDensity = (settings.custom['pigmentDensity'] as double?) ?? 0.5;

    // Layer 1: Soft wet bleed
    if (bleedSpread > 0.1) {
      final bleedPath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.8, streamline: 0.8, simulatePressure: false);
      canvas.drawPath(bleedPath, Paint()
        ..color = settings.color.withOpacity(settings.opacity * 0.15 * bleedSpread)
        ..style = PaintingStyle.stroke
        ..strokeWidth = settings.size * (1.0 + bleedSpread * 0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * bleedSpread * 0.3)
        ..blendMode = blendMode);
    }

    // Layer 2: Main watercolor body
    final mainPath = buildFreehandPath(points, settings, thinning: 0.15 * (1.0 - wetness), smoothing: 0.6, streamline: 0.7);
    canvas.drawPath(mainPath, Paint()
      ..color = settings.color.withOpacity(settings.opacity * (0.3 + pigmentDensity * 0.4))
      ..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 3: Edge darkening
    if (edgeDarkening > 0.1) {
      final edgePath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.5);
      canvas.drawPath(edgePath, Paint()
        ..color = settings.color.withOpacity(settings.opacity * 0.2 * edgeDarkening)
        ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.15..isAntiAlias = true..blendMode = blendMode);
    }

    // Layer 4: Wet-in-wet bloom
    if (wetness > 0.5) {
      final rng = math.Random(points.first.timestamp);
      for (int i = 0; i < points.length; i += 3) {
        final p = points[i];
        if (rng.nextDouble() < wetness * 0.4) {
          final bloomR = settings.size * (0.3 + rng.nextDouble() * 0.5) * wetness;
          canvas.drawCircle(
            Offset(p.x + (rng.nextDouble() - 0.5) * settings.size * 0.5, p.y + (rng.nextDouble() - 0.5) * settings.size * 0.5),
            bloomR,
            Paint()..color = settings.color.withOpacity(settings.opacity * 0.08 * wetness)..maskFilter = MaskFilter.blur(BlurStyle.normal, bloomR * 0.6),
          );
        }
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final granulation = (settings.custom['granulation'] as double?) ?? 0.4;
    if (granulation < 0.1) return;
    final rng = math.Random(points.first.timestamp + 7);
    final particleCount = (points.length * granulation * 2.0).round();
    for (int i = 0; i < particleCount && i < points.length; i++) {
      final idx = rng.nextInt(points.length);
      final p = points[idx];
      final ox = (rng.nextDouble() - 0.5) * settings.size * 0.9;
      final oy = (rng.nextDouble() - 0.5) * settings.size * 0.9;
      canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.3 + rng.nextDouble() * 0.8, Paint()..color = settings.color.withOpacity(granulation * 0.15 * rng.nextDouble()));
    }
    // Cauliflower edges
    if (granulation > 0.3) {
      for (int i = 0; i < points.length; i += 8) {
        if (rng.nextDouble() > 0.7) {
          final p = points[i];
          final dir = rng.nextDouble() * math.pi * 2;
          final dist = settings.size * 0.5;
          canvas.drawCircle(
            Offset(p.x + math.cos(dir) * dist, p.y + math.sin(dir) * dist),
            settings.size * 0.2 * granulation,
            Paint()..color = settings.color.withOpacity(0.06 * granulation)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
          );
        }
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'wetness', label: 'Wetness', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'granulation', label: 'Granulation', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'bleedSpread', label: 'Bleed Spread', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'edgeDarkening', label: 'Edge Darkening', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'pigmentDensity', label: 'Pigment Density', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.1, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 15.0, opacity: 0.4, custom: {'wetness': 0.6, 'granulation': 0.4, 'bleedSpread': 0.5, 'edgeDarkening': 0.3, 'pigmentDensity': 0.5});
}
