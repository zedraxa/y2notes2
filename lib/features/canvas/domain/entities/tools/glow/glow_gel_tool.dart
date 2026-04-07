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
  @override String get description => 'Smooth gel pen with soft glow';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.star;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final glitterEnabled = (settings.custom['glitterEnabled'] as bool?) ?? false;
    final glitterDensity = (settings.custom['glitterDensity'] as double?) ?? 0.5;
    final c = settings.color;

    final glowPath = buildFreehandPath(points, settings.copyWith(size: settings.size * 2), thinning: 0.3, smoothing: 0.5);
    canvas.drawPath(glowPath, Paint()
      ..color = Color.fromARGB(51, c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..blendMode = blendMode);

    final corePath = buildFreehandPath(points, settings, thinning: 0.4, smoothing: 0.5);
    canvas.drawPath(corePath, Paint()
      ..color = c
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);

    if (glitterEnabled && points.length > 1) {
      final rng = math.Random(points.first.x.toInt());
      for (int i = 0; i < points.length; i += 2) {
        if (rng.nextDouble() < glitterDensity * 0.3) {
          final p = points[i];
          canvas.drawCircle(
            Offset(p.x + (rng.nextDouble() - 0.5) * settings.size, p.y + (rng.nextDouble() - 0.5) * settings.size),
            rng.nextDouble() * 1.5 + 0.3,
            Paint()..color = const Color(0xFFFFFFFF)..blendMode = BlendMode.srcOver,
          );
        }
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'glitterEnabled', label: 'Glitter', type: ToolSettingType.toggle, defaultValue: false),
    ToolSettingDefinition(key: 'glitterDensity', label: 'Glitter Density', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 1.0, custom: {'glitterEnabled': false, 'glitterDensity': 0.5});
}
