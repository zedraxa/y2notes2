import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class ClassicHighlighterTool extends BaseFreehandTool {
  @override String get id => 'classic_highlighter';
  @override String get name => 'Classic Highlighter';
  @override String get description => 'Standard flat highlighter with chisel edge and overlap darkening';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.highlight;
  @override BlendMode get blendMode => BlendMode.multiply;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final chiselAngle = (settings.custom['chiselAngle'] as double?) ?? 15.0;
    final overlapDarkening = (settings.custom['overlapDarkening'] as double?) ?? 0.3;

    // Layer 1: Main flat marker stroke
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.6, streamline: 0.8, simulatePressure: false);
    canvas.drawPath(path, Paint()
      ..color = settings.color.withOpacity(settings.opacity)
      ..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 2: Chisel edge (angled edge darkening)
    if (chiselAngle > 0 && points.length >= 2) {
      final angleRad = chiselAngle * math.pi / 180.0;
      for (int i = 1; i < points.length; i++) {
        final p = points[i]; final prev = points[i - 1];
        final angle = math.atan2(p.y - prev.y, p.x - prev.x);
        final perp = Offset(-math.sin(angle + angleRad), math.cos(angle + angleRad));
        final offset = settings.size * 0.4;
        canvas.drawLine(Offset(prev.x + perp.dx * offset, prev.y + perp.dy * offset), Offset(p.x + perp.dx * offset, p.y + perp.dy * offset), Paint()
          ..color = settings.color.withOpacity(settings.opacity * 0.15)..strokeWidth = settings.size * 0.1..strokeCap = StrokeCap.round..blendMode = blendMode);
      }
    }

    // Layer 3: Overlap buildup at slow points
    if (overlapDarkening > 0.1) {
      for (final p in points) {
        if (p.velocity < 2.0) {
          canvas.drawCircle(Offset(p.x, p.y), settings.size * 0.4, Paint()..color = settings.color.withOpacity(settings.opacity * 0.05 * overlapDarkening)..blendMode = blendMode);
        }
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'chiselAngle', label: 'Chisel Angle', type: ToolSettingType.slider, defaultValue: 15.0, min: 0.0, max: 45.0),
    ToolSettingDefinition(key: 'overlapDarkening', label: 'Overlap Darkening', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 20.0, opacity: 0.35, custom: {'chiselAngle': 15.0, 'overlapDarkening': 0.3});
}
