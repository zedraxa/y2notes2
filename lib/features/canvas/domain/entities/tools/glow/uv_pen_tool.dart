import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class UvPenTool extends BaseFreehandTool {
  @override String get id => 'uv_pen';
  @override String get name => 'UV Pen';
  @override String get description => 'UV-reactive ink with fluorescent glow under blacklight';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.visibility;
  @override BlendMode get blendMode => BlendMode.screen;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final uvMode = (settings.custom['uvMode'] as bool?) ?? true;
    final fluorescence = (settings.custom['fluorescence'] as double?) ?? 0.7;
    final reactivity = (settings.custom['reactivity'] as double?) ?? 0.5;

    if (!uvMode) {
      // Invisible mode: very faint
      final path = buildFreehandPath(points, settings, thinning: 0.2, smoothing: 0.5, streamline: 0.6);
      canvas.drawPath(path, Paint()..color = settings.color.withOpacity(0.04)..style = PaintingStyle.fill..isAntiAlias = true);
      return;
    }

    // UV mode: fluorescent rendering
    // Layer 1: Wide fluorescent aura
    final auraPath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.7, streamline: 0.7, simulatePressure: false);
    final auraSize = settings.size * 3.0 * fluorescence;
    canvas.drawPath(auraPath, Paint()
      ..color = settings.color.withOpacity(settings.opacity * 0.08 * fluorescence)
      ..style = PaintingStyle.stroke..strokeWidth = auraSize..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, auraSize * 0.4)..blendMode = blendMode);

    // Layer 2: Bright core
    final corePath = buildFreehandPath(points, settings, thinning: 0.15, smoothing: 0.5, streamline: 0.6);
    canvas.drawPath(corePath, Paint()
      ..color = settings.color.withOpacity(settings.opacity * 0.9 * fluorescence)
      ..style = PaintingStyle.fill..blendMode = blendMode);

    // Layer 3: White-hot center
    final centerPath = buildFreehandPath(points, settings, thinning: 0.2, smoothing: 0.6, streamline: 0.7);
    canvas.drawPath(centerPath, Paint()
      ..color = Colors.white.withOpacity(settings.opacity * 0.4 * fluorescence)
      ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.2..strokeCap = StrokeCap.round..blendMode = blendMode);

    // Layer 4: Reactive sparkle
    if (reactivity > 0.2) {
      final rng = math.Random(points.first.timestamp);
      for (int i = 0; i < points.length; i += 3) {
        final p = points[i];
        if (rng.nextDouble() < reactivity * 0.5) {
          final ox = (rng.nextDouble() - 0.5) * settings.size;
          final oy = (rng.nextDouble() - 0.5) * settings.size;
          canvas.drawCircle(Offset(p.x + ox, p.y + oy), 0.5 + rng.nextDouble() * 1.0, Paint()..color = Colors.white.withOpacity(0.3 * reactivity)..blendMode = blendMode);
        }
      }
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final uvMode = (settings.custom['uvMode'] as bool?) ?? true;
    if (!uvMode) return;
    final fluorescence = (settings.custom['fluorescence'] as double?) ?? 0.7;
    final rng = math.Random(points.first.timestamp + 33);
    for (int i = 0; i < points.length; i += 6) {
      final p = points[i]; final dir = rng.nextDouble() * math.pi * 2;
      final dist = settings.size * 2.0 * fluorescence;
      canvas.drawCircle(Offset(p.x + math.cos(dir) * dist, p.y + math.sin(dir) * dist), settings.size * 0.3, Paint()..color = settings.color.withOpacity(0.01 * fluorescence)..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * 0.5)..blendMode = blendMode);
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'uvMode', label: 'UV Mode', type: ToolSettingType.toggle, defaultValue: true),
    ToolSettingDefinition(key: 'fluorescence', label: 'Fluorescence', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'reactivity', label: 'Reactivity', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 1.0, custom: {'uvMode': true, 'fluorescence': 0.7, 'reactivity': 0.5});
}
