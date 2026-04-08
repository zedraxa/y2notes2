import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class LaserPenTool extends BaseFreehandTool {
  @override String get id => 'laser_pen';
  @override String get name => 'Laser Pen';
  @override String get description => 'Thin precise laser beam with afterburn and scatter';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.flash_on;
  @override BlendMode get blendMode => BlendMode.screen;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final beamWidth = (settings.custom['beamWidth'] as double?) ?? 0.5;
    final afterburn = (settings.custom['afterburn'] as double?) ?? 0.4;
    final scatter = (settings.custom['scatter'] as double?) ?? 0.2;

    // Layer 1: Wide diffuse glow
    if (points.length >= 2) {
      final glowPaint = Paint()
        ..color = settings.color.withOpacity(settings.opacity * 0.1)
        ..style = PaintingStyle.stroke..strokeWidth = settings.size * 4.0 * beamWidth..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * 2.0 * beamWidth)..blendMode = blendMode;
      final glowPath = Path()..moveTo(points[0].x, points[0].y);
      for (int i = 1; i < points.length; i++) { glowPath.lineTo(points[i].x, points[i].y); }
      canvas.drawPath(glowPath, glowPaint);
    }

    // Layer 2: Colored beam
    if (points.length >= 2) {
      final beamPaint = Paint()
        ..color = settings.color.withOpacity(settings.opacity * 0.8)
        ..style = PaintingStyle.stroke..strokeWidth = settings.size * beamWidth..strokeCap = StrokeCap.round..blendMode = blendMode;
      final beamPath = Path()..moveTo(points[0].x, points[0].y);
      for (int i = 1; i < points.length; i++) { beamPath.lineTo(points[i].x, points[i].y); }
      canvas.drawPath(beamPath, beamPaint);
    }

    // Layer 3: White core
    if (points.length >= 2) {
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(settings.opacity * 0.9)
        ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.3 * beamWidth..strokeCap = StrokeCap.round..blendMode = blendMode;
      final corePath = Path()..moveTo(points[0].x, points[0].y);
      for (int i = 1; i < points.length; i++) { corePath.lineTo(points[i].x, points[i].y); }
      canvas.drawPath(corePath, corePaint);
    }

    // Layer 4: Afterburn glow at impact point (end)
    if (afterburn > 0.1 && points.length > 1) {
      final end = points.last;
      canvas.drawCircle(Offset(end.x, end.y), settings.size * 2.0 * afterburn, Paint()..color = settings.color.withOpacity(0.15 * afterburn)..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * 1.5 * afterburn)..blendMode = blendMode);
      canvas.drawCircle(Offset(end.x, end.y), settings.size * 0.5 * afterburn, Paint()..color = Colors.white.withOpacity(0.5 * afterburn)..blendMode = blendMode);
    }

    // Layer 5: Photon scatter
    if (scatter > 0.05) {
      final rng = math.Random(points.first.timestamp);
      for (final p in points) {
        if (rng.nextDouble() < scatter * 0.5) {
          final angle = rng.nextDouble() * math.pi * 2;
          final dist = settings.size * (0.5 + rng.nextDouble() * 2.0) * scatter;
          canvas.drawCircle(Offset(p.x + math.cos(angle) * dist, p.y + math.sin(angle) * dist), 0.3 + rng.nextDouble() * 0.5, Paint()..color = settings.color.withOpacity(0.2 * scatter)..blendMode = blendMode);
        }
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'beamWidth', label: 'Beam Width', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'afterburn', label: 'Afterburn', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'scatter', label: 'Scatter', type: ToolSettingType.slider, defaultValue: 0.2, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 2.0, opacity: 1.0, custom: {'beamWidth': 0.5, 'afterburn': 0.4, 'scatter': 0.2});
}
