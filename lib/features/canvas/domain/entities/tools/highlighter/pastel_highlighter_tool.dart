import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class PastelHighlighterTool extends BaseFreehandTool {
  static const _palette = {
    'Baby Pink': Color(0xFFFFB3C1),
    'Mint': Color(0xFFB3F0DC),
    'Lavender': Color(0xFFD4B3FF),
    'Butter': Color(0xFFFFF3B3),
    'Peach': Color(0xFFFFCBA4),
  };

  @override String get id => 'pastel_highlighter';
  @override String get name => 'Pastel Hi';
  @override String get description => 'Muted pastel tone highlighter';
  @override ToolCategory get category => ToolCategory.highlighter;
  @override IconData get icon => Icons.color_lens_outlined;
  @override BlendMode get blendMode => BlendMode.multiply;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final paletteKey = (settings.custom['paletteIndex'] as String?) ?? 'Baby Pink';
    final c = _palette[paletteKey] ?? const Color(0xFFFFB3C1);
    final path = buildFreehandPath(points, settings, thinning: 0.0, smoothing: 0.4, simulatePressure: false);
    canvas.drawPath(path, Paint()
      ..color = Color.fromARGB(51, c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'paletteIndex', label: 'Palette', type: ToolSettingType.dropdown, defaultValue: 'Baby Pink', options: ['Baby Pink', 'Mint', 'Lavender', 'Butter', 'Peach']),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 20.0, opacity: 0.2, custom: {'paletteIndex': 'Baby Pink'});
}
