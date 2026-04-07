import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effect.dart';

/// Which canvas edge was hit.
enum EdgeDirection { top, bottom, left, right }

class _EdgeGlow {
  _EdgeGlow({required this.direction});

  final EdgeDirection direction;
  double age = 0.0;

  // 0.35 s (350 ms) duration
  static const double duration = 0.35;
  bool get isDead => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);

  /// Shake offset for 2 px canvas shake effect.
  double shakeOffset(double intensity) {
    if (progress > 0.5) return 0.0;
    final t = progress / 0.5;
    return math.sin(t * math.pi * 4) * 2.0 * intensity * (1.0 - t);
  }
}

/// Canvas Edge Bounce Effect.
///
/// When panning hits the canvas boundary:
/// - Gradient edge glow flash along the hit edge
/// - 150 ms subtle canvas shake (2 px amplitude)
class EdgeBounceEffect implements InteractionEffect {
  @override
  final String id = 'edge_bounce';

  @override
  final String name = 'Canvas Edge Bounce';

  @override
  final String description =
      'Elastic bounce and glow when panning hits the canvas boundary.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_EdgeGlow> _glows = [];

  // ── Public trigger ──────────────────────────────────────────────────────────

  /// Trigger a bounce at [direction].
  void triggerEdgeBounce(EdgeDirection direction) {
    if (!isEnabled) return;
    _glows.add(_EdgeGlow(direction: direction));
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
      _renderEdgeGlow(canvas, size, g);
    }
  }

  void _renderEdgeGlow(Canvas canvas, Size size, _EdgeGlow glow) {
    final opacity = (1.0 - glow.progress) * intensity;
    const accentColor = Color(0xFF4A90D9);
    const glowWidth = 32.0;

    Rect rect;
    Alignment begin;
    Alignment end;

    switch (glow.direction) {
      case EdgeDirection.left:
        rect = Rect.fromLTWH(0, 0, glowWidth, size.height);
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
      case EdgeDirection.right:
        rect =
            Rect.fromLTWH(size.width - glowWidth, 0, glowWidth, size.height);
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
      case EdgeDirection.top:
        rect = Rect.fromLTWH(0, 0, size.width, glowWidth);
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
      case EdgeDirection.bottom:
        rect = Rect.fromLTWH(
            0, size.height - glowWidth, size.width, glowWidth);
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
    }

    final paint = Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [
          accentColor.withOpacity((opacity * 0.5).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  void dispose() => _glows.clear();
}
