import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class NeonHighlighterTool extends BaseFreehandTool {
  @override String get id => 'neon_highlighter';
  @override String get name => 'Neon Highlighter';
  @override String get description => 'Electric neon highlighter with vibrant glow and saturation boost';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.highlight;
  @override BlendMode get blendMode => BlendMode.screen;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final saturation = (settings.custom['saturation'] as double?) ?? 1.5;
    final neonGlow = (settings.custom['neonGlow'] as double?) ?? 0.6;
    final electric = (settings.custom['electric'] as double?) ?? 0.3;

    // Boost saturation
    final hsl = HSLColor.fromColor(settings.color);
    final boostedColor = hsl.withSaturation((hsl.saturation * saturation).clamp(0.0, 1.0)).toColor();

    // Layer 1: Wide neon glow aura
    if (neonGlow > 0.1) {
      final auraPath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.8, streamline: 0.8, simulatePressure: false);
      final glowSize = settings.size * 2.0 * neonGlow;
      canvas.drawPath(auraPath, Paint()
        ..color = boostedColor.withOpacity(settings.opacity * 0.1 * neonGlow)
        ..style = PaintingStyle.stroke..strokeWidth = glowSize..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSize * 0.4)..blendMode = blendMode);
    }

    // Layer 2: Main body
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.6, streamline: 0.7, simulatePressure: false);
    canvas.drawPath(path, Paint()
      ..color = boostedColor.withOpacity(settings.opacity * 0.8)
      ..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 3: Inner bright core
    final corePath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.7);
    canvas.drawPath(corePath, Paint()
      ..color = Color.lerp(boostedColor, Colors.white, 0.3)!.withOpacity(settings.opacity * 0.3)
      ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.3..strokeCap = StrokeCap.round..blendMode = blendMode);

    // Layer 4: Electric sparkle
    if (electric > 0.1) {
      final rng = math.Random(points.first.timestamp);
      for (int i = 0; i < points.length; i += 3) {
        final p = points[i];
        if (rng.nextDouble() < electric * 0.5) {
          final ox = (rng.nextDouble() - 0.5) * settings.size;
          final oy = (rng.nextDouble() - 0.5) * settings.size;
          canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.5 + rng.nextDouble() * 1.0, Paint()..color = Colors.white.withOpacity(0.3 * electric)..blendMode = blendMode);
        }
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'saturation', label: 'Saturation', type: ToolSettingType.slider, defaultValue: 1.5, min: 0.5, max: 2.0),
    ToolSettingDefinition(key: 'neonGlow', label: 'Neon Glow', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'electric', label: 'Electric', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 18.0, opacity: 0.6, custom: {'saturation': 1.5, 'neonGlow': 0.6, 'electric': 0.3});
}
