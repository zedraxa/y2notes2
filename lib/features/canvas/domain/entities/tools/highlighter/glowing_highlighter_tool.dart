import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class GlowingHighlighterTool extends BaseFreehandTool {
  @override String get id => 'glowing_highlighter';
  @override String get name => 'Glowing Highlighter';
  @override String get description => 'Pulsating glow highlighter with dynamic wave effect';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.light;
  @override BlendMode get blendMode => BlendMode.screen;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final pulseSpeed = (settings.custom['pulseSpeed'] as double?) ?? 3.0;
    final glowRadius = (settings.custom['glowRadius'] as double?) ?? 0.6;
    final breathe = (settings.custom['breathe'] as bool?) ?? true;

    // Layer 1: Dynamic pulsating outer glow
    double dist = 0.0;
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (i > 0) {
        final dx = points[i].x - points[i - 1].x;
        final dy = points[i].y - points[i - 1].y;
        dist += math.sqrt(dx * dx + dy * dy);
      }
      final pulse = breathe ? (0.7 + 0.3 * math.sin(dist * pulseSpeed * 0.05)) : 1.0;
      final glowR = settings.size * (1.5 + glowRadius) * pulse;
      canvas.drawCircle(Offset(p.x, p.y), glowR, Paint()
        ..color = settings.color.withOpacity(settings.opacity * 0.06 * pulse * glowRadius)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowR * 0.5)..blendMode = blendMode);
    }

    // Layer 2: Main highlighted stroke
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.7, streamline: 0.8, simulatePressure: false);
    canvas.drawPath(path, Paint()
      ..color = settings.color.withOpacity(settings.opacity * 0.6)
      ..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);

    // Layer 3: Inner bright core
    final corePath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.7);
    canvas.drawPath(corePath, Paint()
      ..color = Color.lerp(settings.color, Colors.white, 0.4)!.withOpacity(settings.opacity * 0.3)
      ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.3..strokeCap = StrokeCap.round..blendMode = blendMode);

    // Layer 4: Wave sparkles
    if (breathe) {
      final rng = math.Random(points.first.timestamp);
      dist = 0.0;
      for (int i = 1; i < points.length; i += 4) {
        final dx = points[i].x - points[i - 1].x;
        final dy = points[i].y - points[i - 1].y;
        dist += math.sqrt(dx * dx + dy * dy);
        final pulse = math.sin(dist * pulseSpeed * 0.05);
        if (pulse > 0.5 && rng.nextDouble() > 0.5) {
          final p = points[i];
          canvas.drawCircle(Offset(p.x, p.y), 0.8 + rng.nextDouble() * 1.0, Paint()..color = Colors.white.withOpacity(0.2 * pulse)..blendMode = blendMode);
        }
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'pulseSpeed', label: 'Pulse Speed', type: ToolSettingType.slider, defaultValue: 3.0, min: 0.5, max: 8.0),
    ToolSettingDefinition(key: 'glowRadius', label: 'Glow Radius', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'breathe', label: 'Breathe Effect', type: ToolSettingType.toggle, defaultValue: true),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 18.0, opacity: 0.5, custom: {'pulseSpeed': 3.0, 'glowRadius': 0.6, 'breathe': true});
}
