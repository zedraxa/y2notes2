import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class SoftHighlighterTool extends BaseFreehandTool {
  @override String get id => 'soft_highlighter';
  @override String get name => 'Soft Highlighter';
  @override String get description => 'Feathered soft highlighter with gentle blended edges';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.highlight;
  @override BlendMode get blendMode => BlendMode.multiply;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final featherAmount = (settings.custom['featherAmount'] as double?) ?? 0.5;
    final warmth = (settings.custom['warmth'] as double?) ?? 0.3;

    // Layer 1: Outer feathered glow
    if (featherAmount > 0.1) {
      final featherPath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.8, streamline: 0.8, simulatePressure: false);
      final blur = settings.size * 0.5 * featherAmount;
      canvas.drawPath(featherPath, Paint()
        ..color = settings.color.withOpacity(settings.opacity * 0.15 * featherAmount)
        ..style = PaintingStyle.stroke..strokeWidth = settings.size * (1.0 + featherAmount * 0.5)..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)..blendMode = blendMode);
    }

    // Layer 2: Core highlight
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.7, streamline: 0.8, simulatePressure: false);
    canvas.drawPath(path, Paint()
      ..color = settings.color.withOpacity(settings.opacity * 0.7)
      ..style = PaintingStyle.fill..isAntiAlias = true
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * 0.1 * featherAmount)..blendMode = blendMode);

    // Layer 3: Warmth tint
    if (warmth > 0.1) {
      canvas.drawPath(path, Paint()
        ..color = Color.lerp(settings.color, const Color(0xFFFFE0B2), warmth)!.withOpacity(settings.opacity * 0.15 * warmth)
        ..style = PaintingStyle.fill..isAntiAlias = true..blendMode = blendMode);
    }

    // Layer 4: Subtle edge
    final edgePath = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.6);
    canvas.drawPath(edgePath, Paint()
      ..color = settings.color.withOpacity(settings.opacity * 0.08)
      ..style = PaintingStyle.stroke..strokeWidth = settings.size * 0.05..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'featherAmount', label: 'Feather Amount', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'warmth', label: 'Warmth', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 22.0, opacity: 0.3, custom: {'featherAmount': 0.5, 'warmth': 0.3});
}
