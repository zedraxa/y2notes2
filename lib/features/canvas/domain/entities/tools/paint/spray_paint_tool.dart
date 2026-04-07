import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';

class SprayPaintTool implements DrawingTool {
  @override String get id => 'spray_paint';
  @override String get name => 'Spray Paint';
  @override String get description => 'Aerosol spray paint';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.blur_on;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final density = ((settings.custom['density'] as double?) ?? 80.0).round();
    final coneAngle = ((settings.custom['coneAngle'] as double?) ?? 20.0) * math.pi / 180.0;
    final c = settings.color;
    final paint = Paint()
      ..color = Color.fromARGB(60, c.red, c.green, c.blue)
      ..style = PaintingStyle.fill
      ..blendMode = blendMode;

    for (final p in points) {
      final rng = math.Random((p.x * 1000 + p.y).toInt());
      for (int i = 0; i < density ~/ math.max(1, points.length); i++) {
        final angle = (rng.nextDouble() - 0.5) * coneAngle * 2;
        final dist = rng.nextDouble() * settings.size;
        canvas.drawCircle(
          Offset(p.x + math.cos(angle) * dist, p.y + math.sin(angle) * dist),
          rng.nextDouble() * 1.5 + 0.3,
          paint,
        );
      }
    }
  }

  @override
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings) {
    final c = settings.color;
    canvas.drawCircle(Offset(point.x, point.y), settings.size, Paint()
      ..color = Color.fromARGB(40, c.red, c.green, c.blue)
      ..style = PaintingStyle.fill);
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
    ToolSettingDefinition(key: 'density', label: 'Density', type: ToolSettingType.slider, defaultValue: 80.0, min: 10.0, max: 200.0),
    ToolSettingDefinition(key: 'coneAngle', label: 'Cone Angle', type: ToolSettingType.slider, defaultValue: 20.0, min: 5.0, max: 60.0),
    ToolSettingDefinition(key: 'dripEnabled', label: 'Drip', type: ToolSettingType.toggle, defaultValue: false),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 20.0, opacity: 1.0, custom: {'density': 80.0, 'coneAngle': 20.0, 'dripEnabled': false});
}
