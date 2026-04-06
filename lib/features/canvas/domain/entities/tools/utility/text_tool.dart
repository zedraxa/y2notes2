import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class TextTool implements DrawingTool {
  @override String get id => 'text';
  @override String get name => 'Text';
  @override String get description => 'Tap to place a text box';
  @override ToolCategory get category => ToolCategory.utility;
  @override IconData get icon => Icons.text_fields;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => false;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final fontSize = (settings.custom['fontSize'] as double?) ?? 16.0;
    final fontWeight = (settings.custom['fontWeight'] as String?) == 'Bold' ? FontWeight.bold : FontWeight.normal;
    final tp = TextPainter(
      text: TextSpan(
        text: 'T',
        style: TextStyle(color: settings.color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(points.first.x, points.first.y));
  }

  @override
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings) {
    canvas.drawRect(
      Rect.fromLTWH(point.x, point.y, 100, 24),
      Paint()
        ..color = const Color(0x332196F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  Path buildStrokePath(List<PointData> points, ToolSettings settings) => Path();

  @override
  double getWidth(PointData point, ToolSettings settings) => settings.size;

  @override
  Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints) => settings.color;

  @override
  double getOpacity(PointData point, ToolSettings settings) => settings.opacity;

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {}

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'fontSize', label: 'Font Size', type: ToolSettingType.slider, defaultValue: 16.0, min: 8.0, max: 72.0),
    ToolSettingDefinition(key: 'fontWeight', label: 'Font Weight', type: ToolSettingType.dropdown, defaultValue: 'Normal', options: ['Normal', 'Bold']),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 3.0, opacity: 1.0, custom: {'fontSize': 16.0, 'fontWeight': 'Normal'});
}
