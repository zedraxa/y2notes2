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

  // 0.2 s (200 ms) total
  static const double duration = 0.2;
  bool get isDead => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);
}

/// Tool Switch Animation Effect.
///
/// - Morphing colour halo at the cursor position
/// - Particle sparkle burst at cursor
/// - 200 ms duration
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

    // Particle sparkle
    particleSystem?.emitBurst(
      cursorPosition,
      6,
      ParticleConfig(
        baseColor: toColor,
        colorVariations: [fromColor, toColor, Colors.white],
        minSize: 1.5,
        maxSize: 4.0,
        randomVelocitySpread: 40.0,
        shape: ParticleShape.sparkle,
        drag: 0.90,
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
    final progress = anim.progress;
    final color =
        Color.lerp(anim.fromColor, anim.toColor, progress) ?? anim.toColor;
    final opacity =
        (math.sin(progress * math.pi) * 0.4 * intensity).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(anim.cursor, 12.0 * intensity, paint);
  }

  @override
  void dispose() => _animations.clear();
}
