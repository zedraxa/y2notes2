import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class CrayonTool extends BaseFreehandTool {
  @override String get id => 'crayon';
  @override String get name => 'Crayon';
  @override String get description => 'Waxy crayon with paper texture and broken edges';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.auto_fix_high;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final waxiness = (settings.custom['waxiness'] as double?) ?? 0.6;
    final paperTexture = (settings.custom['paperTexture'] as double?) ?? 0.5;

    // Layer 1: Main waxy stroke
    final path = buildFreehandPath(points, settings, thinning: 0.05, smoothing: 0.3, streamline: 0.4, simulatePressure: true);
    canvas.drawPath(path, Paint()
      ..color = settings.color.withOpacity(settings.opacity * (0.5 + waxiness * 0.5))
      ..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 2: Paper texture noise
    if (paperTexture > 0.1) {
      final rng = math.Random(points.first.timestamp);
      for (final p in points) {
        for (int g = 0; g < (paperTexture * 8).round(); g++) {
          final ox = (rng.nextDouble() - 0.5) * settings.size;
          final oy = (rng.nextDouble() - 0.5) * settings.size;
          canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.3 + rng.nextDouble() * 0.5 * paperTexture, Paint()..color = Colors.white.withOpacity(0.1 * paperTexture * (1.0 - p.pressure)));
        }
      }
    }

    // Layer 3: Broken edge fragments
    final rng = math.Random(points.first.timestamp + 3);
    for (int i = 0; i < points.length; i += 3) {
      final p = points[i];
      if (rng.nextDouble() > 0.6) {
        final dir = rng.nextDouble() * math.pi * 2;
        final dist = settings.size * (0.4 + rng.nextDouble() * 0.3);
        canvas.drawCircle(Offset(p.x + math.cos(dir) * dist, p.y + math.sin(dir) * dist), 0.5 + rng.nextDouble() * 1.0 * waxiness, Paint()..color = settings.color.withOpacity(0.12 * waxiness));
      }
    }

    // Layer 4: Wax buildup at slow points
    for (final p in points) {
      if (p.velocity < 2.0 && p.pressure > 0.5) {
        canvas.drawCircle(Offset(p.x, p.y), settings.size * 0.2 * waxiness, Paint()..color = settings.color.withOpacity(0.08 * waxiness));
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    for (int i = 0; i < points.length; i += 5) {
      final p = points[i];
      if (p.pressure > 0.7) {
        canvas.drawCircle(Offset(p.x, p.y), settings.size * 0.15, Paint()..color = Colors.white.withOpacity(0.03 * p.pressure));
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'waxiness', label: 'Waxiness', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'paperTexture', label: 'Paper Texture', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 8.0, opacity: 1.0, custom: {'waxiness': 0.6, 'paperTexture': 0.5});
}
