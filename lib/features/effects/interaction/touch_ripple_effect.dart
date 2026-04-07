import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effect.dart';

class _Ripple {
  _Ripple({
    required this.position,
    required this.color,
    required this.pressure,
  });

  final Offset position;
  final Color color;
  final double pressure;
  double age = 0.0;

  // 0.4 s (400 ms) duration
  static const double duration = 0.4;
  bool get isDead => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);
}

/// Touch Ripple Effect — expanding 3-ring ripple on every touch/stylus contact.
///
/// - Inner ring: fast, opaque  •  Middle ring: medium  •  Outer: slow, fading
/// - Color adapts to current tool color (subtly tinted)
/// - Intensity scales with stylus pressure (harder press = bigger ripple)
class TouchRippleEffect implements InteractionEffect {
  @override
  final String id = 'touch_ripple';

  @override
  final String name = 'Touch Ripple';

  @override
  final String description =
      'A subtle ripple radiates from where you touch the canvas.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_Ripple> _ripples = [];

  // ── Public trigger ──────────────────────────────────────────────────────────

  /// Trigger a ripple at [position].
  ///
  /// [color] is blended from the active tool colour. [pressure] (0–1) scales
  /// the maximum radius so a harder stylus press produces a larger ripple.
  void trigger(
    Offset position, {
    Color color = const Color(0xFF4A90D9),
    double pressure = 1.0,
  }) {
    if (!isEnabled) return;
    _ripples.add(_Ripple(position: position, color: color, pressure: pressure));
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    for (final r in _ripples) {
      r.age += dt;
    }
    _ripples.removeWhere((r) => r.isDead);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!isEnabled || _ripples.isEmpty) return;
    for (final r in _ripples) {
      _renderRipple(canvas, r);
    }
  }

  void _renderRipple(Canvas canvas, _Ripple r) {
    // ease-out cubic
    final prog = r.progress;
    final ease = 1.0 - math.pow(1.0 - prog, 3);

    // Harder stylus press → bigger ripple (0.7 – 1.0 base scale + pressure)
    final pressureScale = 0.7 + 0.3 * r.pressure.clamp(0.0, 1.0);
    const maxRadius = 60.0;

    // 3 rings: inner (fast/opaque), middle, outer (slow/fading)
    const rings = [
      (speedMult: 1.3, maxFactor: 0.50, opacity: 0.50),
      (speedMult: 1.0, maxFactor: 0.75, opacity: 0.35),
      (speedMult: 0.8, maxFactor: 1.00, opacity: 0.20),
    ];

    for (final ring in rings) {
      final ringEase = (ease * ring.speedMult).clamp(0.0, 1.0);
      final radius = maxRadius * ring.maxFactor * ringEase * pressureScale * intensity;
      final ringOpacity = (ring.opacity * (1.0 - prog) * intensity).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = r.color.withOpacity(ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(r.position, math.max(radius, 0.0), paint);
    }
  }

  @override
  void dispose() => _ripples.clear();
}
