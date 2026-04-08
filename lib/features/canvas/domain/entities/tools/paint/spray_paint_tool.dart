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
  @override String get description => 'Aerosol spray with particle cone and drip effects';
  @override ToolCategory get category => ToolCategory.paint;
  @override IconData get icon => Icons.blur_on;
  @override BlendMode get blendMode => BlendMode.srcOver;
  @override bool get hasTexture => true;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final density = (settings.custom['density'] as double?) ?? 0.6;
    final coneAngle = (settings.custom['coneAngle'] as double?) ?? 30.0;
    final dripEnabled = (settings.custom['dripEnabled'] as bool?) ?? true;
    final spatter = (settings.custom['spatter'] as double?) ?? 0.3;
    final coneRad = coneAngle * math.pi / 180.0;
    final rng = math.Random(points.first.timestamp);
    final particlesPerPoint = (density * 25).round().clamp(5, 50);

    for (final p in points) {
      for (int j = 0; j < particlesPerPoint; j++) {
        final angle = rng.nextDouble() * coneRad * 2 - coneRad;
        final dist = rng.nextDouble() * settings.size;
        final gaussianDist = dist * dist / (settings.size * settings.size);
        final px = p.x + math.cos(angle) * dist;
        final py = p.y + math.sin(angle) * dist;
        final particleOpacity = settings.opacity * (0.6 - gaussianDist * 0.4) * density;
        canvas.drawCircle(Offset(px, py), 0.4 + rng.nextDouble() * 1.2, Paint()..color = settings.color.withOpacity(particleOpacity.clamp(0.01, 0.8)));
      }
      // Pressure affects cone spread
      if (p.pressure < 0.4) {
        for (int j = 0; j < 5; j++) {
          final angle = rng.nextDouble() * math.pi * 2;
          final dist = settings.size * (0.8 + rng.nextDouble() * 0.5);
          canvas.drawCircle(Offset(p.x + math.cos(angle) * dist, p.y + math.sin(angle) * dist), 0.3 + rng.nextDouble() * 0.5, Paint()..color = settings.color.withOpacity(settings.opacity * 0.1));
        }
      }
    }

    // Spatter
    if (spatter > 0.1) {
      final spatterCount = (points.length * spatter * 0.8).round();
      for (int i = 0; i < spatterCount; i++) {
        final idx = rng.nextInt(points.length);
        final p = points[idx];
        final angle = rng.nextDouble() * math.pi * 2;
        final dist = settings.size * (1.0 + rng.nextDouble() * 1.5);
        canvas.drawCircle(Offset(p.x + math.cos(angle) * dist, p.y + math.sin(angle) * dist), 1.0 + rng.nextDouble() * 2.5 * spatter, Paint()..color = settings.color.withOpacity(settings.opacity * 0.3 * spatter));
      }
    }

    // Drip effect
    if (dripEnabled) {
      for (final p in points) {
        if (p.velocity < 1.0 && rng.nextDouble() > 0.85) {
          final dripLength = settings.size * (0.5 + rng.nextDouble() * 2.0);
          canvas.drawLine(
            Offset(p.x + (rng.nextDouble() - 0.5) * settings.size * 0.3, p.y),
            Offset(p.x + (rng.nextDouble() - 0.5) * 2, p.y + dripLength),
            Paint()..color = settings.color.withOpacity(settings.opacity * 0.4)..strokeWidth = 0.8 + rng.nextDouble() * 0.8..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  @override
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings) {
    canvas.drawCircle(Offset(point.x, point.y), settings.size, Paint()..color = settings.color.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    canvas.drawCircle(Offset(point.x, point.y), settings.size * 0.3, Paint()..color = settings.color.withOpacity(0.3)..style = PaintingStyle.fill);
  }

  @override
  Path buildStrokePath(List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return Path();
    final path = Path();
    for (final p in points) { path.addOval(Rect.fromCircle(center: Offset(p.x, p.y), radius: settings.size)); }
    return path;
  }

  @override double getWidth(PointData point, ToolSettings settings) => settings.size;
  @override Color getColor(PointData point, ToolSettings settings, int pointIndex, int totalPoints) => settings.color;
  @override double getOpacity(PointData point, ToolSettings settings) => settings.opacity;

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final rng = math.Random(points.first.timestamp + 55);
    final mistCount = (points.length * 0.3).round();
    for (int i = 0; i < mistCount; i++) {
      final idx = rng.nextInt(points.length);
      final p = points[idx];
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = settings.size * (1.5 + rng.nextDouble() * 2.0);
      canvas.drawCircle(Offset(p.x + math.cos(angle) * dist, p.y + math.sin(angle) * dist), 0.2 + rng.nextDouble() * 0.5, Paint()..color = settings.color.withOpacity(0.02));
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'density', label: 'Density', type: ToolSettingType.slider, defaultValue: 0.6, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'coneAngle', label: 'Cone Angle', type: ToolSettingType.slider, defaultValue: 30.0, min: 5.0, max: 90.0),
    ToolSettingDefinition(key: 'spatter', label: 'Spatter', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'dripEnabled', label: 'Drip', type: ToolSettingType.toggle, defaultValue: true),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 20.0, opacity: 0.8, custom: {'density': 0.6, 'coneAngle': 30.0, 'spatter': 0.3, 'dripEnabled': true});
}
