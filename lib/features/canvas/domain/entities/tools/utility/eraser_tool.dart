import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class EraserTool implements DrawingTool {
  @override String get id => 'eraser';
  @override String get name => 'Eraser';
  @override String get description => 'Multi-mode eraser with pressure-sensitive softness';
  @override ToolCategory get category => ToolCategory.utility;
  @override IconData get icon => Icons.auto_fix_normal;
  @override BlendMode get blendMode => BlendMode.clear;
  @override bool get hasTexture => false;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final mode = (settings.custom['mode'] as String?) ?? 'stroke';
    final softness = (settings.custom['softness'] as double?) ?? 0.0;
    final pressureErase = (settings.custom['pressureErase'] as bool?) ?? true;

    if (mode == 'pixel') {
      if (softness > 0.3) {
        // Soft pixel eraser with feathered edge
        for (final p in points) {
          final radius = settings.size * (pressureErase ? p.pressure : 1.0);
          // Outer soft edge
          canvas.drawCircle(Offset(p.x, p.y), radius * (1.0 + softness * 0.3), Paint()
            ..color = Colors.white.withOpacity(0.4 * softness)..blendMode = BlendMode.dstOut
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * softness * 0.3));
          // Inner hard core
          canvas.drawCircle(Offset(p.x, p.y), radius * (1.0 - softness * 0.3), Paint()..blendMode = BlendMode.clear);
        }
      } else {
        // Hard pixel eraser
        for (final p in points) {
          final radius = settings.size * (pressureErase ? p.pressure : 1.0);
          canvas.drawCircle(Offset(p.x, p.y), radius, Paint()..blendMode = BlendMode.clear);
        }
      }
      // Connect segments for smooth erasure path
      if (points.length >= 2) {
        for (int i = 1; i < points.length; i++) {
          final prev = points[i - 1]; final p = points[i];
          final w = settings.size * 2.0 * (pressureErase ? p.pressure : 1.0);
          canvas.drawLine(Offset(prev.x, prev.y), Offset(p.x, p.y), Paint()..strokeWidth = w..strokeCap = StrokeCap.round..blendMode = BlendMode.clear);
        }
      }
    } else {
      // Stroke mode: visual indicator only (actual removal logic is in the BLoC)
      for (final p in points) {
        final radius = settings.size * (pressureErase ? p.pressure : 1.0);
        canvas.drawCircle(Offset(p.x, p.y), radius, Paint()..color = Colors.white..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(p.x, p.y), radius, Paint()..color = Colors.grey.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }
    }
  }

  @override
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings) {
    final mode = (settings.custom['mode'] as String?) ?? 'stroke';
    final pressureErase = (settings.custom['pressureErase'] as bool?) ?? true;
    final radius = settings.size * (pressureErase ? point.pressure.clamp(0.3, 1.0) : 1.0);
    canvas.drawCircle(Offset(point.x, point.y), radius, Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(point.x, point.y), radius, Paint()..color = Colors.grey..style = PaintingStyle.stroke..strokeWidth = 1.0);
    if (mode == 'stroke') {
      // Cross indicator for stroke mode
      final offset = radius * 0.5;
      final crossPaint = Paint()..color = Colors.red.withOpacity(0.5)..strokeWidth = 1.0..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(point.x - offset, point.y - offset), Offset(point.x + offset, point.y + offset), crossPaint);
      canvas.drawLine(Offset(point.x + offset, point.y - offset), Offset(point.x - offset, point.y + offset), crossPaint);
    }
  }

  @override
  Path buildStrokePath(List<PointData> points, ToolSettings settings) {
    final path = Path();
    for (final p in points) { path.addOval(Rect.fromCircle(center: Offset(p.x, p.y), radius: settings.size)); }
    return path;
  }

  @override double getWidth(PointData point, ToolSettings settings) => settings.size * 2.0;
  @override Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints) => Colors.white;
  @override double getOpacity(PointData point, ToolSettings settings) => 1.0;
  @override void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {}

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'mode', label: 'Mode', type: ToolSettingType.dropdown, defaultValue: 'stroke', options: ['stroke', 'pixel']),
    ToolSettingDefinition(key: 'softness', label: 'Softness', type: ToolSettingType.slider, defaultValue: 0.0, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'pressureErase', label: 'Pressure Sensitive', type: ToolSettingType.toggle, defaultValue: true),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 10.0, opacity: 1.0, custom: {'mode': 'stroke', 'softness': 0.0, 'pressureErase': true});
}
