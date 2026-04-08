import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class ChalkTool extends BaseFreehandTool {
  @override String get id => 'chalk';
  @override String get name => 'Chalk';
  @override String get description => 'Dusty chalk with surface grip and smudge';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.dashboard;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final dustAmount = (settings.custom['dustAmount'] as double?) ?? 0.5;
    final coverage = (settings.custom['coverage'] as double?) ?? 0.6;
    final surfaceGrip = (settings.custom['surfaceGrip'] as double?) ?? 0.5;
    final rng = math.Random(points.first.timestamp);

    // Layer 1: Scattered circle coverage
    for (final p in points) {
      for (int c = 0; c < (coverage * 20).round(); c++) {
        final ox = (rng.nextDouble() - 0.5) * settings.size;
        final oy = (rng.nextDouble() - 0.5) * settings.size;
        final r = 0.4 + rng.nextDouble() * (settings.size * 0.15);
        final cov = settings.opacity * (0.15 + 0.2 * coverage) * p.pressure;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), r, Paint()..color = settings.color.withOpacity(cov.clamp(0.01, 0.5)));
      }
    }

    // Layer 2: Surface grip edges
    if (surfaceGrip > 0.2) {
      for (int i = 1; i < points.length; i++) {
        final p = points[i]; final prev = points[i - 1];
        final angle = math.atan2(p.y - prev.y, p.x - prev.x);
        final perp = Offset(-math.sin(angle), math.cos(angle));
        for (int s = 0; s < 3; s++) {
          final ed = (rng.nextDouble() - 0.5) * settings.size * 0.8 * surfaceGrip;
          canvas.drawCircle(Offset(p.x + perp.dx * ed, p.y + perp.dy * ed), 0.3 + rng.nextDouble() * 0.5, Paint()..color = settings.color.withOpacity(0.08 * surfaceGrip));
        }
      }
    }

    // Layer 3: Dust scatter
    if (dustAmount > 0.2) {
      final dc = (points.length * dustAmount * 1.5).round();
      for (int d = 0; d < dc; d++) {
        final idx = rng.nextInt(points.length); final p = points[idx];
        final angle = rng.nextDouble() * math.pi * 2;
        final dist = settings.size * (0.5 + rng.nextDouble() * 1.5) * dustAmount;
        canvas.drawCircle(Offset(p.x + math.cos(angle) * dist, p.y + math.sin(angle) * dist), 0.2 + rng.nextDouble() * 0.6, Paint()..color = settings.color.withOpacity(0.04 * dustAmount));
      }
    }

    // Layer 4: Smudge trail
    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      if (p.pressure > 0.6) {
        final sr = settings.size * 0.35 * p.pressure;
        canvas.drawCircle(Offset(p.x, p.y), sr, Paint()..color = settings.color.withOpacity(0.04 * p.pressure)..maskFilter = MaskFilter.blur(BlurStyle.normal, sr * 0.4));
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'dustAmount', label: 'Dust Amount', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'coverage', label: 'Coverage', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.2, max: 1.0),
    ToolSettingDefinition(key: 'surfaceGrip', label: 'Surface Grip', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 10.0, opacity: 1.0, custom: {'dustAmount': 0.5, 'coverage': 0.6, 'surfaceGrip': 0.5});
}
