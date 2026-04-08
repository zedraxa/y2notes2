import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class PastelHighlighterTool extends BaseFreehandTool {
  @override String get id => 'pastel_highlighter';
  @override String get name => 'Pastel Highlighter';
  @override String get description => 'Soft muted pastel palette with chalky texture';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.highlight;
  @override BlendMode get blendMode => BlendMode.multiply;

  static const _paletteColors = {
    'Baby Pink': Color(0xFFFFB6C1),
    'Mint': Color(0xFF98FB98),
    'Lavender': Color(0xFFE6E6FA),
    'Butter': Color(0xFFFFFDD0),
    'Peach': Color(0xFFFFDAB9),
    'Sky Blue': Color(0xFF87CEEB),
  };

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final paletteName = (settings.custom['palette'] as String?) ?? 'Lavender';
    final chalkTexture = (settings.custom['chalkTexture'] as double?) ?? 0.4;
    final paletteColor = _paletteColors[paletteName] ?? const Color(0xFFE6E6FA);
    final effectiveColor = Color.lerp(settings.color, paletteColor, 0.7)!;

    // Layer 1: Soft chalky base
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.6, streamline: 0.7, simulatePressure: false);
    final blur = settings.size * 0.06 * chalkTexture;
    canvas.drawPath(path, Paint()
      ..color = effectiveColor.withOpacity(settings.opacity * 0.75)
      ..style = PaintingStyle.fill..isAntiAlias = true
      ..maskFilter = blur > 0.3 ? MaskFilter.blur(BlurStyle.normal, blur) : null
      ..blendMode = blendMode);

    // Layer 2: Muted overlay
    canvas.drawPath(path, Paint()
      ..color = effectiveColor.withOpacity(settings.opacity * 0.15)
      ..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 3: Chalk grain texture
    if (chalkTexture > 0.2) {
      final rng = math.Random(points.first.timestamp);
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i];
        for (int g = 0; g < (chalkTexture * 5).round(); g++) {
          final ox = (rng.nextDouble() - 0.5) * settings.size * 0.8;
          final oy = (rng.nextDouble() - 0.5) * settings.size * 0.8;
          canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.2 + rng.nextDouble() * 0.5, Paint()..color = Colors.white.withOpacity(0.06 * chalkTexture));
        }
      }
    }

    // Layer 4: Subtle pastel edge
    final edgePath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.6);
    canvas.drawPath(edgePath, Paint()
      ..color = effectiveColor.withOpacity(settings.opacity * 0.1)
      ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.04..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'palette', label: 'Palette', type: ToolSettingType.dropdown, defaultValue: 'Lavender', options: ['Baby Pink', 'Mint', 'Lavender', 'Butter', 'Peach', 'Sky Blue']),
    ToolSettingDefinition(key: 'chalkTexture', label: 'Chalk Texture', type: ToolSettingType.slider, defaultValue: 0.4, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 18.0, opacity: 0.4, custom: {'palette': 'Lavender', 'chalkTexture': 0.4});
}
