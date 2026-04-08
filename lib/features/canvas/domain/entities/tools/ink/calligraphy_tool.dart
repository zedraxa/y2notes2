import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/base_freehand_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class CalligraphyTool extends BaseFreehandTool {
  // ── Flexibility tuning ─────────────────────────────────────────────────
  /// Pressure value treated as neutral (no boost/reduction).
  static const double _pressureNeutralPoint = 0.5;

  /// How strongly flexibility maps pressure to width variation.
  static const double _flexibilityScale = 0.8;

  @override String get id => 'calligraphy';
  @override String get name => 'Calligraphy';
  @override String get description => 'Angle-sensitive calligraphy nib with ink pooling';
  @override ToolCategory get category => ToolCategory.ink;
  @override IconData get icon => Icons.create;
  @override BlendMode get blendMode => BlendMode.srcOver;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 2) return;
    final nibAngle = ((settings.custom['nibAngle'] as double?) ?? 45.0) * math.pi / 180.0;
    final flexibility = ((settings.custom['flexibility'] as double?) ?? 0.5).clamp(0.0, 1.0);
    final hairlineEntry = (settings.custom['hairlineEntry'] as bool?) ?? true;
    final paint = Paint()
      ..color = settings.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = blendMode;

    // Hairline entry stroke
    if (hairlineEntry && points.length > 3) {
      final entryPaint = Paint()..color = settings.color..style = PaintingStyle.stroke..strokeWidth = 0.5..isAntiAlias = true;
      final entryPath = Path()..moveTo(points[0].x, points[0].y);
      for (int i = 1; i <= math.min(3, points.length - 1); i++) {
        entryPath.lineTo(points[i].x, points[i].y);
      }
      canvas.drawPath(entryPath, entryPaint);
    }

    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;
      final angle = math.atan2(dy, dx);
      final tiltOffset = (p2.tilt - math.pi / 4) * 0.3 * flexibility;
      final effectiveNibAngle = nibAngle + tiltOffset;
      final angleDiff = (angle - effectiveNibAngle).abs();
      // Base width from nib angle
      final angleWidth = 0.15 + 0.85 * math.sin(angleDiff).abs().clamp(0.0, 1.0);
      // Flexibility adds pressure-based width variation: pressing harder
      // opens the nib wider, like a flexible broad-edge pen.
      final pressureBoost =
          1.0 + flexibility * (p2.pressure - _pressureNeutralPoint) * _flexibilityScale;
      final width = settings.size * angleWidth * pressureBoost.clamp(0.5, 1.8);
      final perp = Offset(-math.sin(angle) * width * 0.5, math.cos(angle) * width * 0.5);
      final path = Path()
        ..moveTo(p1.x + perp.dx, p1.y + perp.dy)
        ..lineTo(p2.x + perp.dx, p2.y + perp.dy)
        ..lineTo(p2.x - perp.dx, p2.y - perp.dy)
        ..lineTo(p1.x - perp.dx, p1.y - perp.dy)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Hairline exit
    if (hairlineEntry && points.length > 3) {
      final exitPaint = Paint()..color = settings.color..style = PaintingStyle.stroke..strokeWidth = 0.5..isAntiAlias = true;
      final exitStart = math.max(0, points.length - 4);
      final exitPath = Path()..moveTo(points[exitStart].x, points[exitStart].y);
      for (int i = exitStart + 1; i < points.length; i++) {
        exitPath.lineTo(points[i].x, points[i].y);
      }
      canvas.drawPath(exitPath, exitPaint);
    }
  }

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.length < 3) return;
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1]; final curr = points[i]; final next = points[i + 1];
      final a1 = math.atan2(curr.y - prev.y, curr.x - prev.x);
      final a2 = math.atan2(next.y - curr.y, next.x - curr.x);
      var diff = (a2 - a1).abs();
      if (diff > math.pi) diff = 2 * math.pi - diff;
      if (diff > math.pi * 0.35) {
        canvas.drawCircle(Offset(curr.x, curr.y), settings.size * 0.25, Paint()..color = settings.color.withOpacity(0.2));
      }
    }
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(key: 'nibAngle', label: 'Nib Angle', type: ToolSettingType.slider, defaultValue: 45.0, min: 0.0, max: 180.0),
    ToolSettingDefinition(key: 'flexibility', label: 'Flexibility', type: ToolSettingType.slider, defaultValue: 0.5, min: 0.0, max: 1.0),
    ToolSettingDefinition(key: 'hairlineEntry', label: 'Hairline Entry/Exit', type: ToolSettingType.toggle, defaultValue: true),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(size: 4.0, opacity: 1.0, custom: {'nibAngle': 45.0, 'flexibility': 0.5, 'hairlineEntry': true});
}
