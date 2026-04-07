import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effect.dart';

class _SnapGlow {
  _SnapGlow({
    required this.start,
    required this.end,
    required this.color,
  });

  final Offset start;
  final Offset end;
  final Color color;
  double age = 0.0;

  // 0.6 s (600 ms) duration
  static const double duration = 0.6;
  bool get isDead => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);
}

/// Snap Glow Effect — neon line glow when shapes snap to alignment guides.
///
/// - Pulsing glow (2 cycles) along the snap guide line
/// - Semi-transparent accent colour with 3-layer MaskFilter blur
/// - Fades out over 600 ms
/// - Triggers on shape snap and grid-line proximity
class SnapGlowEffect implements InteractionEffect {
  @override
  final String id = 'snap_glow';

  @override
  final String name = 'Snap Glow';

  @override
  final String description =
      'A brief glow appears when a sticker or shape snaps to alignment.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_SnapGlow> _glows = [];

  // ── Public trigger ──────────────────────────────────────────────────────────

  /// Trigger a snap glow from [start] to [end].
  void trigger(
    Offset start,
    Offset end, {
    Color color = const Color(0xFF4A90D9),
  }) {
    if (!isEnabled) return;
    _glows.add(_SnapGlow(start: start, end: end, color: color));
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    for (final g in _glows) {
      g.age += dt;
    }
    _glows.removeWhere((g) => g.isDead);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!isEnabled || _glows.isEmpty) return;
    for (final g in _glows) {
      _renderGlow(canvas, g);
    }
  }

  void _renderGlow(Canvas canvas, _SnapGlow g) {
    // 2 pulse cycles across the full duration → angular frequency = 2 * 2π / duration
    final cycleAngle = g.age * (2 * math.pi * 2) / _SnapGlow.duration;
    final pulseOpacity = (math.sin(cycleAngle) * 0.5 + 0.5).clamp(0.0, 1.0);
    final fadeOut = 1.0 - g.progress;
    final baseOpacity = pulseOpacity * fadeOut * intensity;

    // 3-layer neon glow (wide blur → narrow blur → crisp core)
    const layers = [
      (width: 8.0, opacityMult: 0.15),
      (width: 4.0, opacityMult: 0.30),
      (width: 2.0, opacityMult: 0.60),
    ];

    for (final layer in layers) {
      final paint = Paint()
        ..color = g.color.withOpacity((baseOpacity * layer.opacityMult).clamp(0.0, 1.0))
        ..strokeWidth = layer.width
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawLine(g.start, g.end, paint);
    }

    // Crisp bright core
    final corePaint = Paint()
      ..color = g.color.withOpacity((baseOpacity * 0.8).clamp(0.0, 1.0))
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(g.start, g.end, corePaint);
  }

  @override
  void dispose() => _glows.clear();
}
