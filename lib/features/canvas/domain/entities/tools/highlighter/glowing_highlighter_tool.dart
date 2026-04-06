import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class GlowingHighlighterTool extends BaseFreehandTool {
  @override String get id => 'glowing_highlighter';
  @override String get name => 'Glowing Hi';
  @override String get description => 'Pulsating glowing highlighter';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.lens_blur;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final minOpacity = (settings.custom['minOpacity'] as double?) ?? 0.2;
    final maxOpacity = (settings.custom['maxOpacity'] as double?) ?? 0.4;
    final pulseSpeed = (settings.custom['pulseSpeed'] as double?) ?? 2.0;
    final c = settings.color;

    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final pulse = (math.sin(t * pulseSpeed) + 1) / 2;
    final opacity = minOpacity + (maxOpacity - minOpacity) * pulse;

    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.4, simulatePressure: false);

    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB((opacity * 100).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..blendMode = blendMode);

    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB((opacity * 255).round(), c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'pulseSpeed', label: 'Pulse Speed', type: ToolSettingType.slider, defaultValue: 2.0, min: 0.5, max: 5.0),
    ToolSettingDefinition(key: 'minOpacity', label: 'Min Opacity', type: ToolSettingType.slider, defaultValue: 0.2, min: 0.0, max: 0.5),
    ToolSettingDefinition(key: 'maxOpacity', label: 'Max Opacity', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 20.0, opacity: 0.4, custom: {'pulseSpeed': 2.0, 'minOpacity': 0.2, 'maxOpacity': 0.4});
}
