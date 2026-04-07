import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class HolographicPenTool extends BaseFreehandTool {
  @override String get id => 'holographic_pen';
  @override String get name => 'Holographic Pen';
  @override String get description => 'Rainbow-shifting holographic ink with prismatic shimmer';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.lens_blur;
  @override BlendMode get blendMode => BlendMode.screen;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final hueSpeed = (settings.custom['hueSpeed'] as double?) ?? 2.0;
    final shimmer = (settings.custom['shimmer'] as double?) ?? 0.5;
    final prismSplit = (settings.custom['prismSplit'] as double?) ?? 0.3;

    double cumulativeDistance = 0.0;

    // Layer 1: Prismatic RGB split
    if (prismSplit > 0.1) {
      for (int i = 1; i < points.length; i++) {
        final p1 = points[i - 1]; final p2 = points[i];
        final angle = math.atan2(p2.y - p1.y, p2.x - p1.x);
        final perp = Offset(-math.sin(angle), math.cos(angle));
        final offset = settings.size * 0.3 * prismSplit;
        for (final (color, mul) in [(Colors.red, -1.0), (Colors.green, 0.0), (Colors.blue, 1.0)]) {
          canvas.drawLine(Offset(p1.x + perp.dx * offset * mul, p1.y + perp.dy * offset * mul), Offset(p2.x + perp.dx * offset * mul, p2.y + perp.dy * offset * mul), Paint()..color = color.withOpacity(settings.opacity * 0.15 * prismSplit)..strokeWidth = settings.size * 0.3..strokeCap = StrokeCap.round..blendMode = blendMode);
        }
      }
    }

    // Layer 2: Rainbow hue-shifting segments
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1]; final p2 = points[i];
      final dx = p2.x - p1.x; final dy = p2.y - p1.y;
      cumulativeDistance += math.sqrt(dx * dx + dy * dy);
      final hue = (cumulativeDistance * hueSpeed) % 360.0;
      final segColor = HSVColor.fromAHSV(1.0, hue, 0.8, 1.0).toColor();
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), Paint()
        ..color = segColor.withOpacity(settings.opacity * 0.8)
        ..strokeWidth = settings.size * p2.pressure..strokeCap = StrokeCap.round..blendMode = blendMode);
    }

    // Layer 3: Holographic glow
    cumulativeDistance = 0.0;
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1]; final p2 = points[i];
      final dx = p2.x - p1.x; final dy = p2.y - p1.y;
      cumulativeDistance += math.sqrt(dx * dx + dy * dy);
      final hue = (cumulativeDistance * hueSpeed) % 360.0;
      final glowColor = HSVColor.fromAHSV(1.0, hue, 0.6, 1.0).toColor();
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), Paint()
        ..color = glowColor.withOpacity(settings.opacity * 0.1)
        ..strokeWidth = settings.size * 2.5..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * 0.8)..blendMode = blendMode);
    }

    // Layer 4: Shimmer sparkle
    if (shimmer > 0.1) {
      final rng = math.Random(points.first.timestamp);
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i];
        if (rng.nextDouble() < shimmer * 0.6) {
          final ox = (rng.nextDouble() - 0.5) * settings.size;
          final oy = (rng.nextDouble() - 0.5) * settings.size;
          canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.5 + rng.nextDouble() * 1.0, Paint()..color = Colors.white.withOpacity(0.35 * shimmer)..blendMode = blendMode);
        }
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'hueSpeed', label: 'Hue Speed', type: ToolSettingType.slider, defaultValue: 2.0, min: 0.5, max: 8.0),
    ToolSettingDefinition(key: 'shimmer', label: 'Shimmer', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'prismSplit', label: 'Prism Split', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 4.0, opacity: 1.0, custom: {'hueSpeed': 2.0, 'shimmer': 0.5, 'prismSplit': 0.3});
}
