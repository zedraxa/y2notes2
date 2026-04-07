import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuitse/features/canvas/domain/entities/tools/tool_settings.dart';

class OilPaintTool extends BaseFreehandTool {
  @override String get id => 'oil_paint';
  @override String get name => 'Oil Paint';
  @override String get description => 'Smooth buttery oil paint';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.color_lens;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final bristleCount = ((settings.custom['bristleCount'] as double?) ?? 4.0).round();
    final glossiness = (settings.custom['glossiness'] as double?) ?? 0.5;
    final c = settings.color;

    for (int b = 0; b < bristleCount; b++) {
      final offset = (b - bristleCount / 2.0) / bristleCount;
      final bPath = Path();
      bool started = false;
      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        final dx = i < points.length - 1 ? points[i + 1].y - p.y : 0.0;
        final dy = i < points.length - 1 ? -(points[i + 1].x - p.x) : 0.0;
        final len = math.sqrt(dx * dx + dy * dy);
        final nx = len > 0 ? dx / len : 0.0;
        final ny = len > 0 ? dy / len : 0.0;
        final bx = p.x + nx * offset * settings.size;
        final by = p.y + ny * offset * settings.size;
        if (!started) { bPath.moveTo(bx, by); started = true; }
        else { bPath.lineTo(bx, by); }
      }
      canvas.drawPath(bPath, Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = settings.size / bristleCount
        ..isAntiAlias = true
        ..blendMode = blendMode
        ..strokeCap = StrokeCap.round);
    }

    if (glossiness > 0.1 && points.length > 2) {
      final midIndex = points.length ~/ 2;
      final mp = points[midIndex];
      canvas.drawCircle(
        Offset(mp.x - settings.size * 0.3, mp.y - settings.size * 0.3),
        settings.size * 0.15 * glossiness,
        Paint()
          ..color = Color.fromARGB((glossiness * 120).round(), 255, 255, 255)
          ..blendMode = BlendMode.srcOver,
      );
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'bristleCount', label: 'Bristles', type: ToolSettingType.slider, defaultValue: 4.0, min: 2.0, max: 8.0),
    ToolSettingDefinition(key: 'glossiness', label: 'Glossiness', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 12.0, opacity: 1.0, custom: {'bristleCount': 4.0, 'glossiness': 0.5});
}
