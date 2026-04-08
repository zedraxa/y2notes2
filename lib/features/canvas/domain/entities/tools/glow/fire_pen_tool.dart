import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class FirePenTool extends BaseFreehandTool {
  @override String get id => 'fire_pen';
  @override String get name => 'Fire Pen';
  @override String get description => 'Fiery pen with heat gradient, embers, and smoke';
  @override ToolCategory get category => ToolCategory.glow;
  @override IconData get icon => Icons.local_fire_department;
  @override BlendMode get blendMode => BlendMode.screen;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final flameIntensity = (settings.custom['flameIntensity'] as double?) ?? 0.7;
    final embers = (settings.custom['embers'] as bool?) ?? true;
    final smokeTrail = (settings.custom['smokeTrail'] as double?) ?? 0.3;
    final rng = math.Random(points.first.timestamp);

    // Layer 1: Smoke trail
    if (smokeTrail > 0.1) {
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i];
        final smokeR = settings.size * (1.0 + rng.nextDouble() * 1.5) * smokeTrail;
        final ox = (rng.nextDouble() - 0.5) * settings.size * 0.5;
        canvas.drawCircle(Offset(p.x + ox, p.y - smokeR * 0.5), smokeR, Paint()..color = Colors.grey.withOpacity(0.05 * smokeTrail)..maskFilter = MaskFilter.blur(BlurStyle.normal, smokeR * 0.6));
      }
    }

    // Layer 2: Outer flame glow (red-orange)
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1]; final p2 = points[i];
      final t = i / points.length;
      final flameColor = Color.lerp(const Color(0xFFFF4500), const Color(0xFFFF8C00), t)!;
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), Paint()
        ..color = flameColor.withOpacity(settings.opacity * 0.15 * flameIntensity)
        ..strokeWidth = settings.size * 3.0 * flameIntensity..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, settings.size * 1.2 * flameIntensity)..blendMode = blendMode);
    }

    // Layer 3: Core flame (yellow-white gradient)
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1]; final p2 = points[i];
      final t = i / points.length;
      final coreColor = Color.lerp(const Color(0xFFFFFF00), Colors.white, t * 0.5)!;
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), Paint()
        ..color = coreColor.withOpacity(settings.opacity * 0.7 * flameIntensity)
        ..strokeWidth = settings.size * 0.7..strokeCap = StrokeCap.round..blendMode = blendMode);
    }

    // Layer 4: White-hot center
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1]; final p2 = points[i];
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), Paint()
        ..color = Colors.white.withOpacity(settings.opacity * 0.5 * flameIntensity)
        ..strokeWidth = settings.size * 0.2..strokeCap = StrokeCap.round..blendMode = blendMode);
    }

    // Layer 5: Flame tendrils
    for (int i = 0; i < points.length; i += 3) {
      final p = points[i];
      for (int t = 0; t < 2; t++) {
        final dir = -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi * 0.6;
        final len = settings.size * (0.5 + rng.nextDouble() * 1.5) * flameIntensity;
        canvas.drawLine(Offset(p.x, p.y), Offset(p.x + math.cos(dir) * len, p.y + math.sin(dir) * len), Paint()
          ..color = const Color(0xFFFF6600).withOpacity(0.15 * flameIntensity)..strokeWidth = 0.5 + rng.nextDouble() * 1.0..strokeCap = StrokeCap.round..blendMode = blendMode);
      }
    }

    // Layer 6: Ember particles
    if (embers) {
      for (int i = 0; i < points.length; i += 2) {
        final p = points[i];
        if (rng.nextDouble() < 0.4 * flameIntensity) {
          final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi;
          final dist = settings.size * (0.5 + rng.nextDouble() * 3.0);
          final eColor = Color.lerp(const Color(0xFFFF4500), const Color(0xFFFFFF00), rng.nextDouble())!;
          canvas.drawCircle(Offset(p.x + math.cos(angle) * dist, p.y + math.sin(angle) * dist), 0.5 + rng.nextDouble() * 1.2, Paint()..color = eColor.withOpacity(0.4 * flameIntensity)..blendMode = blendMode);
        }
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'flameIntensity', label: 'Flame Intensity', type: ToolSettingType.slider, defaultValue: 0.7, min: 0.1, max: 1.0),
    ToolSettingDefinition(key: 'smokeTrail', label: 'Smoke Trail', type: ToolSettingType.slider, defaultValue: 0.3, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'embers', label: 'Embers', type: ToolSettingType.toggle, defaultValue: true),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 4.0, opacity: 1.0, custom: {'flameIntensity': 0.7, 'smokeTrail': 0.3, 'embers': true});
}
