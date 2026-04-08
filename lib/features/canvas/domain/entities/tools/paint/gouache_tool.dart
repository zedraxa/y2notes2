import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class GouacheTool extends BaseFreehandTool {
  @override String get id => 'gouache';
  @override String get name => 'Gouache';
  @override String get description => 'Flat opaque gouache with matte finish and rewetting';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.format_paint;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final coverage = (settings.custom['coverage'] as double?) ?? 0.9;
    final matteFinish = (settings.custom['matteFinish'] as double?) ?? 0.7;
    final rewetting = (settings.custom['rewetting'] as double?) ?? 0.3;
    final flatness = (settings.custom['flatness'] as double?) ?? 0.7;
    final streamline = 0.5 + flatness * 0.3;

    // Layer 1: Flat opaque base
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.4, streamline: streamline);
    canvas.drawPath(path, Paint()
      ..color = settings.color.withOpacity(settings.opacity * coverage)
      ..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 2: Double-pass for full coverage
    if (coverage > 0.7) {
      canvas.drawPath(path, Paint()..color = settings.color.withOpacity(settings.opacity * (coverage - 0.7) * 0.8)..style = PaintingStyle.fill..isAntiAlias = true);
    }

    // Layer 3: Matte grain texture
    if (matteFinish > 0.3) {
      final rng = math.Random(points.first.timestamp);
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i];
        for (int j = 0; j < 3; j++) {
          final ox = (rng.nextDouble() - 0.5) * settings.size * 0.8;
          final oy = (rng.nextDouble() - 0.5) * settings.size * 0.8;
          canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.2 + rng.nextDouble() * 0.3, Paint()..color = Colors.white.withOpacity(0.03 * matteFinish));
        }
      }
    }

    // Layer 4: Rewetting marks
    if (rewetting > 0.1) {
      for (int i = 1; i < points.length; i++) {
        final p = points[i];
        if (p.velocity < 2.0 && p.pressure > 0.5) {
          final rr = settings.size * 0.3 * rewetting;
          canvas.drawCircle(Offset(p.x, p.y), rr, Paint()..color = settings.color.withOpacity(0.08 * rewetting)..maskFilter = MaskFilter.blur(BlurStyle.normal, rr * 0.5));
        }
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final matteFinish = (settings.custom['matteFinish'] as double?) ?? 0.7;
    if (matteFinish < 0.4) return;
    final rng = math.Random(points.first.timestamp + 21);
    for (int i = 0; i < points.length; i += 5) {
      final p = points[i];
      final dir = rng.nextDouble() * math.pi * 2;
      final dist = settings.size * 0.5;
      canvas.drawCircle(Offset(p.x + math.cos(dir) * dist, p.y + math.sin(dir) * dist), 0.4, Paint()..color = settings.color.withOpacity(0.04 * matteFinish));
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'coverage', label: 'Coverage', type: ToolSettingType.slider, defaultValue: 0.9, min: 0.4, max: 1.0),
    ToolSettingDefinition(key: 'matteFinish', label: 'Matte Finish', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'rewetting', label: 'Rewetting', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'flatness', label: 'Flatness', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 10.0, opacity: 1.0, custom: {'coverage': 0.9, 'matteFinish': 0.7, 'rewetting': 0.3, 'flatness': 0.7});
}
