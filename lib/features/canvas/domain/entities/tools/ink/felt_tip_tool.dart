import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class FeltTipTool extends BaseFreehandTool {
  @override String get id => 'felt_tip';
  @override String get name => 'Felt Tip';
  @override String get description => 'Bold felt tip marker with chisel mode';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.brush;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final chiselMode = (settings.custom['chiselMode'] as bool?) ?? false;
    final bleedAmount = (settings.custom['bleedAmount'] as double?) ?? 0.3;

    if (chiselMode && points.length >= 2) {
      _renderChiselStroke(canvas, points, settings);
    } else {
      final path = buildFreehandPath(points, settings, thinning: 0.1, smoothing: 0.4, streamline: 0.6);
      canvas.drawPath(path, Paint()
        ..color = settings.color..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);
    }

    // Ink bleed at slow-velocity points
    if (bleedAmount > 0.1) {
      final rng = math.Random(points.first.timestamp);
      for (final p in points) {
        if (p.velocity < 2.0 && rng.nextDouble() > 0.5) {
          final ox = (rng.nextDouble() - 0.5) * settings.size * 0.6;
          final oy = (rng.nextDouble() - 0.5) * settings.size * 0.6;
          canvas.drawCircle(
            Offset(p.x + ox, p.y + oy), settings.size * 0.15 * bleedAmount,
            Paint()..color = settings.color.withOpacity(0.1 * bleedAmount),
          );
        }
      }
    }
  }

  void _renderChiselStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    final paint = Paint()..color = settings.color..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode;
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1]; final p2 = points[i];
      final angle = math.atan2(p2.y - p1.y, p2.x - p1.x);
      final chiselFactor = math.cos(angle).abs();
      final width = settings.size * (0.3 + 0.7 * chiselFactor);
      final perp = Offset(-math.sin(angle), math.cos(angle));
      final halfW = width * 0.5;
      final path = Path()
        ..moveTo(p1.x + perp.dx * halfW, p1.y + perp.dy * halfW)
        ..lineTo(p2.x + perp.dx * halfW, p2.y + perp.dy * halfW)
        ..lineTo(p2.x - perp.dx * halfW, p2.y - perp.dy * halfW)
        ..lineTo(p1.x - perp.dx * halfW, p1.y - perp.dy * halfW)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints) {
    final saturation = (settings.custom['saturation'] as double?) ?? 1.2;
    final hsl = HSLColor.fromColor(settings.color);
    return hsl.withSaturation((hsl.saturation * saturation).clamp(0.0, 1.0)).toColor().withOpacity(settings.opacity);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'chiselMode', label: 'Chisel Mode', type: ToolSettingType.toggle, defaultValue: false),
    ToolSettingDefinition(key: 'bleedAmount', label: 'Ink Bleed', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'saturation', label: 'Saturation', type: ToolSettingType.slider, defaultValue: 1.2, min: 0.5, max: 2.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 5.0, opacity: 1.0, custom: {'chiselMode': false, 'bleedAmount': 0.3, 'saturation': 1.2});
}
