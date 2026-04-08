import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class TextTool implements DrawingTool {
  @override String get id => 'text';
  @override String get name => 'Text';
  @override String get description => 'Rich text placement with typography controls';
  @override ToolCategory get category => ToolCategory.utility;
  @override IconData get icon => Icons.text_fields;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => false;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final fontSize = (settings.custom['fontSize'] as double?) ?? 16.0;
    final fontWeight = (settings.custom['fontWeight'] as String?) ?? 'Normal';
    final letterSpacing = (settings.custom['letterSpacing'] as double?) ?? 0.0;
    final shadowEnabled = (settings.custom['shadow'] as bool?) ?? false;

    final p = points.first;

    // Layer 1: Text area indicator box
    final boxWidth = fontSize * 12; final boxHeight = fontSize * 2.5;
    final boxRect = Rect.fromLTWH(p.x, p.y, boxWidth, boxHeight);

    // Box background
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(4.0)), Paint()..color = Colors.white.withOpacity(0.9)..style = PaintingStyle.fill);
    // Box border
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(4.0)), Paint()..color = settings.color.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Corner resize handles
    for (final corner in [boxRect.topLeft, boxRect.topRight, boxRect.bottomLeft, boxRect.bottomRight]) {
      canvas.drawCircle(corner, 3.0, Paint()..color = settings.color.withOpacity(0.5)..style = PaintingStyle.fill);
      canvas.drawCircle(corner, 3.0, Paint()..color = settings.color..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }

    // Layer 2: Text cursor
    final cursorX = p.x + 8.0; final cursorY = p.y + fontSize * 0.3;
    canvas.drawLine(Offset(cursorX, cursorY), Offset(cursorX, cursorY + fontSize * 1.2), Paint()..color = settings.color..strokeWidth = 1.5);

    // Layer 3: Baseline guide
    canvas.drawLine(Offset(p.x + 4, cursorY + fontSize), Offset(p.x + boxWidth - 4, cursorY + fontSize), Paint()..color = settings.color.withOpacity(0.1)..strokeWidth = 0.5);

    // Layer 4: Shadow preview
    if (shadowEnabled) {
      canvas.drawRRect(RRect.fromRectAndRadius(boxRect.shift(const Offset(1.5, 1.5)), const Radius.circular(4.0)), Paint()..color = Colors.black.withOpacity(0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0));
    }

    // Layer 5: Drag indicator
    if (points.length >= 2) {
      final last = points.last;
      final dragBox = Rect.fromPoints(Offset(p.x, p.y), Offset(last.x, last.y));
      canvas.drawRect(dragBox, Paint()..color = settings.color.withOpacity(0.05)..style = PaintingStyle.fill);
      canvas.drawRect(dragBox, Paint()..color = settings.color.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }
  }

  @override
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings) {
    final fontSize = (settings.custom['fontSize'] as double?) ?? 16.0;
    // Text cursor indicator
    canvas.drawLine(Offset(point.x, point.y), Offset(point.x, point.y + fontSize * 1.2), Paint()..color = settings.color..strokeWidth = 1.5);
    // Cross-hair
    canvas.drawLine(Offset(point.x - 6, point.y), Offset(point.x + 6, point.y), Paint()..color = settings.color.withOpacity(0.4)..strokeWidth = 0.5);
    canvas.drawLine(Offset(point.x, point.y - 6), Offset(point.x, point.y + 6), Paint()..color = settings.color.withOpacity(0.4)..strokeWidth = 0.5);
  }

  @override
  Path buildStrokePath(List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return Path();
    final fontSize = (settings.custom['fontSize'] as double?) ?? 16.0;
    final p = points.first;
    return Path()..addRect(Rect.fromLTWH(p.x, p.y, fontSize * 12, fontSize * 2.5));
  }

  @override double getWidth(PointData point, ToolSettings settings) => 1.0;
  @override Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints) => settings.color;
  @override double getOpacity(PointData point, ToolSettings settings) => settings.opacity;
  @override void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {}

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'fontSize', label: 'Font Size', type: ToolSettingType.slider, defaultValue: 16.0, min: 8.0, max: 72.0),
    ToolSettingDefinition(key: 'fontWeight', label: 'Font Weight', type: ToolSettingType.dropdown, defaultValue: 'Normal', options: ['Light', 'Normal', 'Bold', 'Heavy']),
    ToolSettingDefinition(key: 'letterSpacing', label: 'Letter Spacing', type: ToolSettingType.slider, defaultValue: 0.0, min: -2.0, max: 10.0),
    ToolSettingDefinition(key: 'shadow', label: 'Text Shadow', type: ToolSettingType.toggle, defaultValue: false),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 1.0, opacity: 1.0, custom: {'fontSize': 16.0, 'fontWeight': 'Normal', 'letterSpacing': 0.0, 'shadow': false});
}
