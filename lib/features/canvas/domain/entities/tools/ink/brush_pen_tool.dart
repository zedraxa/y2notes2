import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class BrushPenTool extends BaseFreehandTool {
  // ── Springiness-to-streamline mapping ──────────────────────────────────
  static const double _baseStreamline = 0.7;
  static const double _springinessScale = 0.5;
  static const double _minStreamline = 0.1;
  static const double _maxStreamline = 0.9;

  @override String get id => 'brush_pen';
  @override String get name => 'Brush Pen';
  @override String get description => 'Pressure-sensitive brush pen';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.brush;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final springiness = (settings.custom['springiness'] as double?) ?? 0.3;
    // Springiness controls responsiveness: higher springiness → lower streamline
    // (the brush "springs" back to the pen position more quickly).
    final streamline = (_baseStreamline - springiness * _springinessScale)
        .clamp(_minStreamline, _maxStreamline);
    final path = buildFreehandPath(points, settings,
        thinning: 0.8, smoothing: 0.6, streamline: streamline);
    canvas.drawPath(path, Paint()
      ..color = settings.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode);
  }

  @override
  double getWidth(PointData point, ToolSettings settings) {
    final pressureRange = (settings.custom['pressureRange'] as double?) ?? 5.0;
    return settings.size * (0.5 + pressureRange * point.pressure * 0.1).clamp(0.5, 4.0);
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'springiness', label: 'Springiness', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'pressureRange', label: 'Pressure Range', type: ToolSettingType.slider, defaultValue: 5.0, min: 1.0, max: 10.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 6.0, opacity: 1.0, custom: {'springiness': 0.3, 'pressureRange': 5.0});
}
