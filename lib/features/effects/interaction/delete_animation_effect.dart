import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/particle_system.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effect.dart';

/// How the element should visually disappear.
enum DeleteStyle {
  /// Break into angular polygon fragments.
  shatter,

  /// Fade out with a dissolve.
  dissolve,

  /// Shrink to centre with a particle cloud.
  poof,

  /// Slide off-screen in the swipe direction.
  swipe,
}

class _Fragment {
  _Fragment({
    required this.position,
    required this.velocity,
    required this.angularVelocity,
    required this.size,
    required this.color,
    required this.vertices,
  });

  Offset position;
  Offset velocity;
  double angularVelocity;
  double size;
  final Color color;
  double angle = 0.0;
  double age = 0.0;
  final List<Offset> vertices;
}

class _DeleteAnimation {
  _DeleteAnimation({
    required this.center,
    required this.style,
    required this.color,
    required this.fragments,
    this.swipeDirection = Offset.zero,
  });

  final Offset center;
  final DeleteStyle style;
  final Color color;
  final List<_Fragment> fragments;
  final Offset swipeDirection;
  double age = 0.0;

  static const double duration = 0.5;
  bool get isDead => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);
}

/// Delete Animation Effect — satisfying fragment / dissolve / poof animation.
///
/// - `shatter` — 8–16 angular polygon fragments scatter outward
/// - `dissolve` — uniform fade-out
/// - `poof`    — shrink to centre with particle cloud
/// - `swipe`   — slide off-screen in swipe direction
///
/// On undo the engine can re-trigger with inverted velocities (reassemble).
class DeleteAnimationEffect implements InteractionEffect {
  @override
  final String id = 'delete_animation';

  @override
  final String name = 'Delete Animation';

  @override
  final String description =
      'Deleted strokes and objects dissolve with a satisfying animation.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Inject the shared [ParticleSystem] for the burst at the deletion point.
  ParticleSystem? particleSystem;

  final List<_DeleteAnimation> _animations = [];
  final math.Random _rng = math.Random();

  // ── Public trigger ──────────────────────────────────────────────────────────

  /// Trigger a deletion animation for an element that occupied [bounds].
  void triggerDelete(
    Rect bounds, {
    DeleteStyle style = DeleteStyle.shatter,
    Color color = const Color(0xFF888888),
    Offset swipeDirection = Offset.zero,
  }) {
    if (!isEnabled) return;

    final center = bounds.center;
    final fragments = _buildFragments(bounds, style, color);

    _animations.add(_DeleteAnimation(
      center: center,
      style: style,
      color: color,
      fragments: fragments,
      swipeDirection: swipeDirection,
    ));

    // Particle burst at deletion centre
    particleSystem?.emitBurst(
      center,
      12,
      ParticleConfig(
        baseColor: color,
        colorVariations: [color, Colors.white, color.withOpacity(0.5)],
        minSize: 2.0,
        maxSize: 6.0,
        randomVelocitySpread: 80.0,
        drag: 0.93,
        shape: ParticleShape.sparkle,
      ),
    );
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    for (final anim in _animations) {
      anim.age += dt;
      for (final frag in anim.fragments) {
        frag.age += dt;
        frag.position += frag.velocity * dt;
        frag.angle += frag.angularVelocity * dt;
        // Gravity + drag
        frag.velocity = Offset(
          frag.velocity.dx * 0.95,
          frag.velocity.dy * 0.95 + 9.8 * 50.0 * dt,
        );
        // Shrink fragments
        frag.size = (frag.size - dt * 20.0).clamp(0.0, double.infinity);
      }
    }
    _animations.removeWhere((a) => a.isDead);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!isEnabled || _animations.isEmpty) return;
    for (final anim in _animations) {
      _renderAnimation(canvas, anim);
    }
  }

  void _renderAnimation(Canvas canvas, _DeleteAnimation anim) {
    final opacity =
        ((1.0 - anim.progress) * intensity).clamp(0.0, 1.0);

    switch (anim.style) {
      case DeleteStyle.shatter:
        _renderShatter(canvas, anim, opacity);
      case DeleteStyle.dissolve:
        _renderDissolve(canvas, anim, opacity);
      case DeleteStyle.poof:
        _renderPoof(canvas, anim, opacity);
      case DeleteStyle.swipe:
        _renderSwipe(canvas, anim, opacity);
    }
  }

  void _renderShatter(Canvas canvas, _DeleteAnimation anim, double opacity) {
    for (final frag in anim.fragments) {
      if (frag.size < 0.5) continue;
      final fragOpacity =
          (opacity * (1.0 - frag.age / _DeleteAnimation.duration))
              .clamp(0.0, 1.0);
      final paint = Paint()
        ..color = frag.color.withOpacity(fragOpacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(frag.position.dx, frag.position.dy);
      canvas.rotate(frag.angle);

      if (frag.vertices.length >= 3) {
        final path = Path()
          ..moveTo(frag.vertices[0].dx, frag.vertices[0].dy);
        for (int i = 1; i < frag.vertices.length; i++) {
          path.lineTo(frag.vertices[i].dx, frag.vertices[i].dy);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  void _renderDissolve(Canvas canvas, _DeleteAnimation anim, double opacity) {
    // Dissolve: just use a circular fade-out around the centre
    final paint = Paint()
      ..color = anim.color.withOpacity(opacity * 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 + anim.progress * 12);
    canvas.drawCircle(anim.center, 20.0 + anim.progress * 30.0, paint);
  }

  void _renderPoof(Canvas canvas, _DeleteAnimation anim, double opacity) {
    // Poof: ring expanding from centre, shrinking colour blob
    final ringRadius = anim.progress * 40.0 * intensity;
    final ringPaint = Paint()
      ..color = anim.color.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(anim.center, ringRadius, ringPaint);

    final corePaint = Paint()
      ..color = anim.color.withOpacity(opacity * 0.7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 * anim.progress);
    final coreRadius = (1.0 - anim.progress) * 16.0 * intensity;
    canvas.drawCircle(anim.center, math.max(coreRadius, 0.0), corePaint);
  }

  void _renderSwipe(Canvas canvas, _DeleteAnimation anim, double opacity) {
    // Slide off in swipe direction
    for (final frag in anim.fragments) {
      if (frag.size < 0.5) continue;
      canvas.save();
      canvas.translate(frag.position.dx, frag.position.dy);
      final paint = Paint()
        ..color = frag.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: frag.size, height: frag.size),
        paint,
      );
      canvas.restore();
    }
  }

  // ── Fragment generation ───────────────────────────────────────────────────

  List<_Fragment> _buildFragments(Rect bounds, DeleteStyle style, Color color) {
    if (style == DeleteStyle.shatter) return _buildShatterFragments(bounds, color);
    if (style == DeleteStyle.swipe) return _buildSwipeFragments(bounds, color);
    // For dissolve/poof we still create a few fragments for the particle cloud
    return _buildShatterFragments(bounds, color, count: 8);
  }

  List<_Fragment> _buildShatterFragments(
    Rect bounds,
    Color color, {
    int? count,
  }) {
    final n = count ?? (8 + _rng.nextInt(9)); // 8–16
    return List.generate(n, (i) {
      final angle = (i / n) * 2 * math.pi + _rng.nextDouble() * 0.5;
      final speed = 80.0 + _rng.nextDouble() * 120.0;
      final startX = bounds.left + _rng.nextDouble() * bounds.width;
      final startY = bounds.top + _rng.nextDouble() * bounds.height;
      final vertices = _randomPolygon(_rng, 8.0 + _rng.nextDouble() * 12.0);

      return _Fragment(
        position: Offset(startX, startY),
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        angularVelocity: (_rng.nextDouble() - 0.5) * 8.0,
        size: 8.0 + _rng.nextDouble() * 12.0,
        color: color,
        vertices: vertices,
      );
    });
  }

  List<_Fragment> _buildSwipeFragments(Rect bounds, Color color) {
    const n = 6;
    return List.generate(n, (i) {
      final startX = bounds.left + (i / n) * bounds.width;
      final startY = bounds.center.dy;
      return _Fragment(
        position: Offset(startX, startY),
        velocity: Offset(200.0 + _rng.nextDouble() * 100.0, (_rng.nextDouble() - 0.5) * 40.0),
        angularVelocity: (_rng.nextDouble() - 0.5) * 3.0,
        size: 10.0 + _rng.nextDouble() * 10.0,
        color: color,
        vertices: _randomPolygon(_rng, 10.0),
      );
    });
  }

  List<Offset> _randomPolygon(math.Random rng, double size) {
    final sides = 3 + rng.nextInt(3); // 3–5 sided
    return List.generate(sides, (i) {
      final a = (i / sides) * 2 * math.pi + rng.nextDouble() * 0.4;
      final r = size * (0.6 + rng.nextDouble() * 0.4);
      return Offset(math.cos(a) * r, math.sin(a) * r);
    });
  }

  @override
  void dispose() => _animations.clear();
}
