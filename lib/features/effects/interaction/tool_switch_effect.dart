import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/particle_system.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effect.dart';

class _ToolSwitchAnimation {
  _ToolSwitchAnimation({
    required this.cursor,
    required this.fromColor,
    required this.toColor,
  });

  final Offset cursor;
  final Color fromColor;
  final Color toColor;
  double age = 0.0;

  // 0.3 s (300 ms) total — slightly longer for richer animation
  static const double duration = 0.3;
  bool get isDead => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);
}

/// Tool Switch Animation Effect.
///
/// - Expanding outer ring that fades outward
/// - Shrinking inner halo that collapses inward
/// - 2-layer blur glow with colour morphing
/// - Colour afterimage trail (3 ghost circles)
/// - Particle sparkle burst at cursor
class ToolSwitchEffect implements InteractionEffect {
  @override
  final String id = 'tool_switch';

  @override
  final String name = 'Tool Switch Animation';

  @override
  final String description =
      'Particle sparkle and colour transition when switching tools.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Inject the shared [ParticleSystem].
  ParticleSystem? particleSystem;

  final List<_ToolSwitchAnimation> _animations = [];

  // ── Public trigger ──────────────────────────────────────────────────────────

  /// Trigger a tool-switch animation at [cursorPosition].
  void triggerToolSwitch(
    Offset cursorPosition, {
    Color fromColor = const Color(0xFF4A90D9),
    Color toColor = const Color(0xFF4A90D9),
  }) {
    if (!isEnabled) return;
    _animations.add(_ToolSwitchAnimation(
      cursor: cursorPosition,
      fromColor: fromColor,
      toColor: toColor,
    ));

    // Particle sparkle burst — more particles for richer effect
    particleSystem?.emitBurst(
      cursorPosition,
      10,
      ParticleConfig(
        baseColor: toColor,
        colorVariations: [fromColor, toColor, Colors.white],
        minSize: 1.5,
        maxSize: 4.5,
        randomVelocitySpread: 50.0,
        shape: ParticleShape.sparkle,
        drag: 0.88,
      ),
    );
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    for (final a in _animations) {
      a.age += dt;
    }
    _animations.removeWhere((a) => a.isDead);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!isEnabled || _animations.isEmpty) return;
    for (final a in _animations) {
      _renderTransition(canvas, a);
    }
  }

  void _renderTransition(Canvas canvas, _ToolSwitchAnimation anim) {
    final t = anim.progress;
    // ease-out cubic for smooth deceleration
    final ease = 1.0 - math.pow(1.0 - t, 3);
    final fade = 1.0 - t;
    final color =
        Color.lerp(anim.fromColor, anim.toColor, t) ?? anim.toColor;

    // Layer 1 — wide soft outer glow
    final outerOpacity =
        (math.sin(t * math.pi) * 0.25 * intensity).clamp(0.0, 1.0);
    final outerPaint = Paint()
      ..color = color.withOpacity(outerOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(anim.cursor, 20.0 * ease * intensity, outerPaint);

    // Layer 2 — bright inner glow that shrinks inward
    final innerRadius = 14.0 * (1.0 - ease * 0.6) * intensity;
    final innerOpacity =
        (math.sin(t * math.pi) * 0.45 * intensity).clamp(0.0, 1.0);
    final innerPaint = Paint()
      ..color = color.withOpacity(innerOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(anim.cursor, innerRadius, innerPaint);

    // Layer 3 — expanding ring
    final ringRadius = 24.0 * ease * intensity;
    final ringOpacity = (fade * 0.35 * intensity).clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..color = anim.toColor.withOpacity(ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * (1.0 - t * 0.5);
    canvas.drawCircle(anim.cursor, ringRadius, ringPaint);

    // Layer 4 — colour afterimage trail (3 ghost circles at staggered delays)
    for (int i = 0; i < 3; i++) {
      final ghostT = (t - i * 0.08).clamp(0.0, 1.0);
      if (ghostT <= 0) continue;
      final ghostColor = i == 0
          ? anim.fromColor
          : Color.lerp(anim.fromColor, anim.toColor, ghostT);
      final ghostOpacity =
          (0.15 * (1.0 - ghostT) * intensity).clamp(0.0, 1.0);
      final ghostRadius = 10.0 * (1.0 - ghostT * 0.4) * intensity;
      final ghostPaint = Paint()
        ..color = (ghostColor ?? anim.fromColor).withOpacity(ghostOpacity);
      canvas.drawCircle(anim.cursor, ghostRadius, ghostPaint);
    }
  }

  @override
  void dispose() => _animations.clear();
}
