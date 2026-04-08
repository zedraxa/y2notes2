import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/point_data.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';

class EraserTool implements DrawingTool {
  // ── Tilt thresholds (matching BaseFreehandTool) ────────────────────────
  static const double _flatAngleRad = 0.5236; // 30°
  static const double _normalAngleRad = 1.0472; // 60°

  // ── Velocity tuning ────────────────────────────────────────────────────
  static const double _maxVelocityForSpread = 15.0;
  static const double _velocitySpreadScale = 0.6;

  @override String get id => 'eraser';
  @override String get name => 'Eraser';
  @override String get description =>
      'Multi-mode eraser with pressure, tilt, and velocity dynamics';
  @override ToolCategory get category => ToolCategory.utility;
  @override IconData get icon => Icons.auto_fix_normal;
  @override BlendMode get blendMode => BlendMode.clear;
  @override bool get hasTexture => false;

  @override
  void renderStroke(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final mode = (settings.custom['mode'] as String?) ?? 'stroke';
    final softness = (settings.custom['softness'] as double?) ?? 0.0;
    final pressureErase = (settings.custom['pressureErase'] as bool?) ?? true;
    final shape = (settings.custom['shape'] as String?) ?? 'round';
    final tiltMod = (settings.custom['tiltModulation'] as double?) ?? 0.5;
    final velocitySpread = (settings.custom['velocitySpread'] as double?) ?? 0.3;

    if (mode == 'pixel') {
      _renderPixelMode(canvas, points, settings, softness, pressureErase,
          shape, tiltMod, velocitySpread);
    } else {
      // Stroke mode: visual indicator only (actual removal logic is in the BLoC)
      _renderStrokeMode(canvas, points, settings, pressureErase, shape,
          tiltMod, velocitySpread);
    }
  }

  // ── Pixel mode: destructive erasure ────────────────────────────────────

  void _renderPixelMode(
    Canvas canvas,
    List<PointData> points,
    ToolSettings settings,
    double softness,
    bool pressureErase,
    String shape,
    double tiltMod,
    double velocitySpread,
  ) {
    final isSquare = shape == 'square';

    // Layer 1: Soft edge halo (feathered periphery for soft mode)
    if (softness > 0.2) {
      for (final p in points) {
        final r = _effectiveRadius(p, settings.size, pressureErase, tiltMod,
            velocitySpread);
        final haloRadius = r * (1.0 + softness * 0.5);
        final haloOpacity = (0.25 * softness).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(p.x, p.y),
          haloRadius,
          Paint()
            ..color = Colors.white.withOpacity(haloOpacity)
            ..blendMode = BlendMode.dstOut
            ..maskFilter = MaskFilter.blur(
                BlurStyle.normal, haloRadius * softness * 0.4),
        );
      }
    }

    // Layer 2: Mid-feather ring (graduated partial removal)
    if (softness > 0.4) {
      for (final p in points) {
        final r = _effectiveRadius(p, settings.size, pressureErase, tiltMod,
            velocitySpread);
        final midRadius = r * (1.0 + softness * 0.15);
        canvas.drawCircle(
          Offset(p.x, p.y),
          midRadius,
          Paint()
            ..color = Colors.white.withOpacity(0.35 * softness)
            ..blendMode = BlendMode.dstOut
            ..maskFilter = MaskFilter.blur(
                BlurStyle.normal, midRadius * softness * 0.2),
        );
      }
    }

    // Layer 3: Hard core (full removal)
    for (final p in points) {
      final r = _effectiveRadius(p, settings.size, pressureErase, tiltMod,
          velocitySpread);
      final coreRadius = softness > 0.2 ? r * (1.0 - softness * 0.25) : r;
      final clearPaint = Paint()..blendMode = BlendMode.clear;
      if (isSquare) {
        final azAngle = p.azimuth;
        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(azAngle);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: coreRadius * 2.0,
              height: coreRadius * 2.0),
          clearPaint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(p.x, p.y), coreRadius, clearPaint);
      }
    }

    // Connect segments for smooth erasure path
    if (points.length >= 2) {
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final p = points[i];
        final w = _effectiveRadius(p, settings.size, pressureErase, tiltMod,
                velocitySpread) *
            2.0;
        canvas.drawLine(
          Offset(prev.x, prev.y),
          Offset(p.x, p.y),
          Paint()
            ..strokeWidth = w
            ..strokeCap = isSquare ? StrokeCap.butt : StrokeCap.round
            ..blendMode = BlendMode.clear,
        );
      }
    }

    // Layer 4: Velocity streaks — fast strokes leave elongated clear marks
    if (velocitySpread > 0.1 && points.length >= 3) {
      for (int i = 1; i < points.length - 1; i++) {
        final p = points[i];
        if (p.velocity > 3.0) {
          final streakLength = settings.size *
              0.6 *
              (p.velocity / _maxVelocityForSpread).clamp(0.0, 1.0) *
              velocitySpread;
          final prev = points[i - 1];
          final dir = math.atan2(p.y - prev.y, p.x - prev.x);
          final dx = math.cos(dir) * streakLength;
          final dy = math.sin(dir) * streakLength;
          canvas.drawLine(
            Offset(p.x - dx, p.y - dy),
            Offset(p.x + dx, p.y + dy),
            Paint()
              ..strokeWidth = settings.size * 0.3 * p.pressure
              ..strokeCap = StrokeCap.round
              ..blendMode = BlendMode.clear,
          );
        }
      }
    }
  }

  // ── Stroke mode: visual preview ────────────────────────────────────────

  void _renderStrokeMode(
    Canvas canvas,
    List<PointData> points,
    ToolSettings settings,
    bool pressureErase,
    String shape,
    double tiltMod,
    double velocitySpread,
  ) {
    final isSquare = shape == 'square';

    // Sweep highlight — translucent fill showing erasure area
    for (final p in points) {
      final r = _effectiveRadius(p, settings.size, pressureErase, tiltMod,
          velocitySpread);
      final fillPaint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.grey.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      if (isSquare) {
        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(p.azimuth);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: r * 2, height: r * 2),
          fillPaint,
        );
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: r * 2, height: r * 2),
          borderPaint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(p.x, p.y), r, fillPaint);
        canvas.drawCircle(Offset(p.x, p.y), r, borderPaint);
      }
    }

    // Hatched overlay — diagonal lines inside the preview to distinguish
    // from pixel mode
    if (points.isNotEmpty) {
      final last = points.last;
      final r = _effectiveRadius(last, settings.size, pressureErase, tiltMod,
          velocitySpread);
      final hatchPaint = Paint()
        ..color = Colors.red.withOpacity(0.18)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;
      final spacing = r * 0.45;
      final steps = spacing > 0 ? ((2 * r) / spacing).ceil() : 0;
      for (int n = 0; n <= steps; n++) {
        final d = -r + n * spacing;
        final x1 = last.x + d;
        final y1 = last.y - r;
        final x2 = last.x + d + r;
        final y2 = last.y;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), hatchPaint);
      }
    }
  }

  @override
  void renderActivePoint(Canvas canvas, PointData point, ToolSettings settings) {
    final mode = (settings.custom['mode'] as String?) ?? 'stroke';
    final pressureErase = (settings.custom['pressureErase'] as bool?) ?? true;
    final shape = (settings.custom['shape'] as String?) ?? 'round';
    final tiltMod = (settings.custom['tiltModulation'] as double?) ?? 0.5;
    final velocitySpread = (settings.custom['velocitySpread'] as double?) ?? 0.3;
    final isSquare = shape == 'square';
    final radius = _effectiveRadius(
        point, settings.size, pressureErase, tiltMod, velocitySpread)
        .clamp(settings.size * 0.3, settings.size * 3.0);

    // Fill
    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    // Border
    final borderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (isSquare) {
      canvas.save();
      canvas.translate(point.x, point.y);
      canvas.rotate(point.azimuth);
      final rect = Rect.fromCenter(
          center: Offset.zero, width: radius * 2, height: radius * 2);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
      canvas.restore();
    } else {
      canvas.drawCircle(Offset(point.x, point.y), radius, fillPaint);
      canvas.drawCircle(Offset(point.x, point.y), radius, borderPaint);
    }

    // Mode indicator overlays
    if (mode == 'stroke') {
      // Cross indicator for stroke mode
      final offset = radius * 0.5;
      final crossPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(point.x - offset, point.y - offset),
        Offset(point.x + offset, point.y + offset),
        crossPaint,
      );
      canvas.drawLine(
        Offset(point.x + offset, point.y - offset),
        Offset(point.x - offset, point.y + offset),
        crossPaint,
      );
    } else {
      // Pixel mode: subtle clear icon (dot at centre)
      canvas.drawCircle(
        Offset(point.x, point.y),
        radius * 0.08,
        Paint()..color = Colors.grey.withOpacity(0.4),
      );
    }
  }

  @override
  Path buildStrokePath(List<PointData> points, ToolSettings settings) {
    final shape = (settings.custom['shape'] as String?) ?? 'round';
    final pressureErase = (settings.custom['pressureErase'] as bool?) ?? true;
    final tiltMod = (settings.custom['tiltModulation'] as double?) ?? 0.5;
    final velocitySpread = (settings.custom['velocitySpread'] as double?) ?? 0.3;
    final path = Path();
    for (final p in points) {
      final r = _effectiveRadius(p, settings.size, pressureErase, tiltMod,
          velocitySpread);
      if (shape == 'square') {
        // Build a rotated square path respecting azimuth
        final cos = math.cos(p.azimuth);
        final sin = math.sin(p.azimuth);
        final corners = [
          Offset(-r, -r), Offset(r, -r),
          Offset(r, r), Offset(-r, r),
        ];
        final rotated = corners.map((c) => Offset(
          p.x + c.dx * cos - c.dy * sin,
          p.y + c.dx * sin + c.dy * cos,
        )).toList();
        path.moveTo(rotated[0].dx, rotated[0].dy);
        for (int j = 1; j < rotated.length; j++) {
          path.lineTo(rotated[j].dx, rotated[j].dy);
        }
        path.close();
      } else {
        path.addOval(
            Rect.fromCircle(center: Offset(p.x, p.y), radius: r));
      }
    }
    return path;
  }

  @override
  double getWidth(PointData point, ToolSettings settings) {
    final tiltMod = (settings.custom['tiltModulation'] as double?) ?? 0.5;
    final velocitySpread = (settings.custom['velocitySpread'] as double?) ?? 0.3;
    return _effectiveRadius(point, settings.size, true, tiltMod,
            velocitySpread) *
        2.0;
  }

  @override
  Color getColor(PointData point, ToolSettings settings, int pointIndex,
          int totalPoints) =>
      Colors.white;

  @override
  double getOpacity(PointData point, ToolSettings settings) => 1.0;

  @override
  void postProcess(Canvas canvas, List<PointData> points, ToolSettings settings) {
    if (points.isEmpty) return;
    final debris = (settings.custom['debris'] as double?) ?? 0.0;
    if (debris < 0.05) return;

    // Eraser debris particles — small semi-transparent crumbs scattered
    // near the erasure path, like rubber shavings from a real eraser.
    final rng = math.Random(points.first.timestamp + points.length);
    final particleCount = (points.length * debris * 3.0).round();
    for (int i = 0; i < particleCount && i < points.length * 4; i++) {
      final idx = rng.nextInt(points.length);
      final p = points[idx];
      final ox = (rng.nextDouble() - 0.5) * settings.size * 1.8;
      final oy = (rng.nextDouble() - 0.5) * settings.size * 1.8;
      final crumbSize = 0.3 + rng.nextDouble() * 1.2 * debris;
      canvas.drawCircle(
        Offset(p.x + ox, p.y + oy),
        crumbSize,
        Paint()
          ..color = const Color(0xFFE8E0D8).withOpacity(
              (0.15 * debris * rng.nextDouble()).clamp(0.0, 0.3)),
      );
    }

    // Larger clumped debris near direction changes
    if (debris > 0.3 && points.length >= 3) {
      for (int i = 1; i < points.length - 1; i += 3) {
        final prev = points[i - 1];
        final curr = points[i];
        final next = points[i + 1];
        final a1 = math.atan2(curr.y - prev.y, curr.x - prev.x);
        final a2 = math.atan2(next.y - curr.y, next.x - curr.x);
        var diff = (a2 - a1).abs();
        if (diff > math.pi) diff = 2 * math.pi - diff;
        if (diff > math.pi * 0.3) {
          final clumpDir = rng.nextDouble() * math.pi * 2;
          final clumpDist = settings.size * (0.4 + rng.nextDouble() * 0.6);
          canvas.drawCircle(
            Offset(curr.x + math.cos(clumpDir) * clumpDist,
                curr.y + math.sin(clumpDir) * clumpDist),
            1.0 + rng.nextDouble() * 1.5 * debris,
            Paint()
              ..color = const Color(0xFFD8D0C8)
                  .withOpacity(0.12 * debris),
          );
        }
      }
    }
  }

  // ── Effective radius computation ───────────────────────────────────────

  /// Computes the eraser radius for a single point, modulated by pressure,
  /// tilt (altitude), and velocity — matching the depth of other tools.
  double _effectiveRadius(
    PointData point,
    double baseSize,
    bool pressureErase,
    double tiltMod,
    double velocitySpread,
  ) {
    double r = baseSize;

    // Pressure
    if (pressureErase) {
      r *= point.pressure.clamp(0.15, 1.0);
    }

    // Tilt modulation: flat pen → wider eraser (like using side of eraser)
    if (tiltMod > 0.0) {
      final tiltMultiplier = _tiltMultiplier(point.altitude);
      r *= 1.0 + (tiltMultiplier - 1.0) * tiltMod;
    }

    // Velocity spread: faster strokes widen the eraser slightly
    if (velocitySpread > 0.0) {
      final velocityFactor = (point.velocity / _maxVelocityForSpread)
          .clamp(0.0, 1.0);
      r *= 1.0 + velocityFactor * velocitySpread * _velocitySpreadScale;
    }

    return r;
  }

  /// Returns a width multiplier based on the pen altitude angle [radians].
  /// Flat (< 30°) → 2.0, Normal (30°–60°) → interpolated, Upright (> 60°) → 0.5.
  static double _tiltMultiplier(double radians) {
    if (radians < _flatAngleRad) return 2.0;
    if (radians > _normalAngleRad) return 0.5;
    final t = (radians - _flatAngleRad) / (_normalAngleRad - _flatAngleRad);
    return 2.0 - 1.5 * t;
  }

  @override
  List<ToolSettingDefinition> get settingsSchema => const [
    ToolSettingDefinition(
        key: 'mode',
        label: 'Mode',
        type: ToolSettingType.dropdown,
        defaultValue: 'stroke',
        options: ['stroke', 'pixel']),
    ToolSettingDefinition(
        key: 'shape',
        label: 'Shape',
        type: ToolSettingType.dropdown,
        defaultValue: 'round',
        options: ['round', 'square']),
    ToolSettingDefinition(
        key: 'softness',
        label: 'Softness',
        type: ToolSettingType.slider,
        defaultValue: 0.0,
        min: 0.0,
        max: 1.0),
    ToolSettingDefinition(
        key: 'pressureErase',
        label: 'Pressure Sensitive',
        type: ToolSettingType.toggle,
        defaultValue: true),
    ToolSettingDefinition(
        key: 'tiltModulation',
        label: 'Tilt Modulation',
        type: ToolSettingType.slider,
        defaultValue: 0.5,
        min: 0.0,
        max: 1.0),
    ToolSettingDefinition(
        key: 'velocitySpread',
        label: 'Velocity Spread',
        type: ToolSettingType.slider,
        defaultValue: 0.3,
        min: 0.0,
        max: 1.0),
    ToolSettingDefinition(
        key: 'debris',
        label: 'Debris',
        type: ToolSettingType.slider,
        defaultValue: 0.0,
        min: 0.0,
        max: 1.0),
  ];

  @override
  ToolSettings get defaultSettings => const ToolSettings(
    size: 10.0,
    opacity: 1.0,
    custom: {
      'mode': 'stroke',
      'shape': 'round',
      'softness': 0.0,
      'pressureErase': true,
      'tiltModulation': 0.5,
      'velocitySpread': 0.3,
      'debris': 0.0,
    },
  );
}
