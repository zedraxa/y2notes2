import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class OilPaintTool extends BaseFreehandTool {
  @override String get id => 'oil_paint';
  @override String get name => 'Oil Paint';
  @override String get description => 'Rich oil paint with bristle marks and gloss';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.brush;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final bristleCount = ((settings.custom['bristleCount'] as double?) ?? 5.0).round().clamp(2, 10);
    final glossiness = (settings.custom['glossiness'] as double?) ?? 0.3;
    final thickness = (settings.custom['thickness'] as double?) ?? 0.6;
    final colorMixing = (settings.custom['colorMixing'] as double?) ?? 0.2;

    // Layer 1: Base opaque stroke
    final basePath = buildFreehandPath(points, settings, thinning: 0.05 * (1.0 - thickness), smoothing: 0.3, streamline: 0.4);
    canvas.drawPath(basePath, Paint()..color = settings.color..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 2: Bristle marks
    final rng = math.Random(points.first.timestamp);
    for (int b = 0; b < bristleCount; b++) {
      final offset = (b - bristleCount / 2) * (settings.size / bristleCount) * 0.7;
      final bristlePaint = Paint()
        ..color = settings.color.withOpacity(0.2 + rng.nextDouble() * 0.15)
        ..style = PaintingStyle.stroke..strokeWidth = (settings.size / bristleCount) * 0.5..strokeCap = StrokeCap.round..isAntiAlias = true;
      if (points.length >= 2) {
        final bristlePath = Path();
        final wobble = 0.3 + rng.nextDouble() * 0.4;
        bristlePath.moveTo(points[0].x + offset * 0.8, points[0].y);
        for (int i = 1; i < points.length; i++) {
          final p = points[i]; final prevP = points[i - 1];
          final angle = math.atan2(p.y - prevP.y, p.x - prevP.x);
          final perp = Offset(-math.sin(angle), math.cos(angle));
          final jitter = math.sin(i * wobble) * settings.size * 0.05;
          bristlePath.lineTo(p.x + perp.dx * (offset + jitter), p.y + perp.dy * (offset + jitter));
        }
        canvas.drawPath(bristlePath, bristlePaint);
      }
    }

    // Layer 3: Thickness shadow
    if (thickness > 0.3) {
      final shadowPath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.3);
      canvas.drawPath(shadowPath, Paint()
        ..color = Colors.black.withOpacity(0.04 * thickness)
        ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.1..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0));
    }

    // Layer 4: Glossy highlights
    if (glossiness > 0.1) {
      for (int i = 0; i < points.length; i += 4) {
        final p = points[i];
        final hs = settings.size * 0.15 * glossiness * p.pressure;
        canvas.drawCircle(Offset(p.x, p.y - hs * 0.3), hs, Paint()..color = Colors.white.withOpacity(0.15 * glossiness));
      }
    }

    // Layer 5: Color mixing
    if (colorMixing > 0.1 && points.length > 5) {
      final hsl = HSLColor.fromColor(settings.color);
      for (int i = 0; i < points.length; i += 6) {
        final p = points[i];
        final hueShift = (rng.nextDouble() - 0.5) * 20.0 * colorMixing;
        final mixed = hsl.withHue((hsl.hue + hueShift) % 360.0);
        final ox = (rng.nextDouble() - 0.5) * settings.size * 0.6;
        final oy = (rng.nextDouble() - 0.5) * settings.size * 0.6;
        canvas.drawCircle(Offset(p.x + ox, p.y + oy), settings.size * 0.15, Paint()..color = mixed.toColor().withOpacity(0.1 * colorMixing));
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'bristleCount', label: 'Bristle Count', type: ToolSettingType.slider, defaultValue: 5.0, min: 2.0, max: 10.0),
    ToolSettingDefinition(key: 'glossiness', label: 'Glossiness', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'thickness', label: 'Thickness', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'colorMixing', label: 'Color Mixing', type: ToolSettingType.slider, defaultValue: 0.2, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 12.0, opacity: 1.0, custom: {'bristleCount': 5.0, 'glossiness': 0.3, 'thickness': 0.6, 'colorMixing': 0.2});
}
