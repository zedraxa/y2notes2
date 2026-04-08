import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class PencilHbTool extends BaseFreehandTool {
  @override String get id => 'pencil_hb';
  @override String get name => 'Pencil HB';
  @override String get description => 'Standard HB pencil with graphite grain and tilt shading';
  @override ToolCategory get category => ToolCategory.dry;
  @override IconData get icon => Icons.edit;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final hardness = (settings.custom['hardness'] as double?) ?? 0.6;
    final grainSize = (settings.custom['grainSize'] as double?) ?? 0.5;
    final tiltShading = (settings.custom['tiltShading'] as bool?) ?? true;

    for (int i = 1; i < points.length; i++) {
      final p = points[i]; final prev = points[i - 1];
      final tiltFactor = tiltShading ? (1.0 - (p.tilt / (math.pi / 2)).clamp(0.0, 1.0)) : 0.0;
      final effectiveSize = settings.size * (1.0 + tiltFactor * 2.0);
      final opacityBase = 0.3 + 0.7 * (1.0 - hardness * 0.5);
      final pressureOpacity = opacityBase * (0.3 + 0.7 * p.pressure);
      canvas.drawLine(Offset(prev.x, prev.y), Offset(p.x, p.y), Paint()
        ..color = settings.color.withOpacity(settings.opacity * pressureOpacity)
        ..strokeWidth = effectiveSize..strokeCap = StrokeCap.round..isAntiAlias = true);
    }

    // Graphite grain overlay
    final rng = math.Random(points.first.timestamp);
    for (final p in points) {
      for (int g = 0; g < (grainSize * 6).round(); g++) {
        final ox = (rng.nextDouble() - 0.5) * settings.size * 1.2;
        final oy = (rng.nextDouble() - 0.5) * settings.size * 1.2;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.2 + rng.nextDouble() * 0.5 * grainSize, Paint()..color = settings.color.withOpacity(0.06 * grainSize * p.pressure));
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final hardness = (settings.custom['hardness'] as double?) ?? 0.6;
    final rng = math.Random(points.first.timestamp + 31);
    for (int i = 0; i < points.length; i += 3) {
      final p = points[i];
      if (rng.nextDouble() < hardness * 0.4) {
        final ox = (rng.nextDouble() - 0.5) * settings.size;
        final oy = (rng.nextDouble() - 0.5) * settings.size;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.3 + rng.nextDouble() * 0.3, Paint()..color = Colors.white.withOpacity(0.08 * hardness));
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'grainSize', label: 'Grain Size', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'hardness', label: 'Hardness', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'tiltShading', label: 'Tilt Shading', type: ToolSettingType.toggle, defaultValue: true),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 1.0, custom: {'grainSize': 0.5, 'hardness': 0.6, 'tiltShading': true});
}
