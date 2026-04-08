import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/features/effects/interaction/interaction_effect.dart';

/// Which canvas edge was hit.
enum EdgeDirection { top, bottom, left, right }

class _EdgeGlow {
  _EdgeGlow({required this.direction});

  final EdgeDirection direction;
  double age = 0.0;

  // 0.45 s (450 ms) duration — slightly longer for richer glow
  static const double duration = 0.45;
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
/// - 2-layer gradient glow (wide soft + narrow bright highlight streak)
/// - Fade-in/out easing curve for smooth entrance and exit
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
    // Fade-in/out easing: quick rise, smooth fall
    final t = glow.progress;
    final fadeIn = (t * 5.0).clamp(0.0, 1.0); // ramps to 1 in first 20%
    final fadeOut = 1.0 - math.pow(t, 2); // quadratic decay
    final envelope = fadeIn * fadeOut * intensity;

    const accentColor = Color(0xFF4A90D9);
    const glowWidthWide = 48.0;
    const glowWidthNarrow = 16.0;

    Rect wideRect;
    Rect narrowRect;
    Alignment begin;
    Alignment end;

    switch (glow.direction) {
      case EdgeDirection.left:
        wideRect = Rect.fromLTWH(0, 0, glowWidthWide, size.height);
        narrowRect = Rect.fromLTWH(0, 0, glowWidthNarrow, size.height);
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
      case EdgeDirection.right:
        wideRect = Rect.fromLTWH(
            size.width - glowWidthWide, 0, glowWidthWide, size.height);
        narrowRect = Rect.fromLTWH(
            size.width - glowWidthNarrow, 0, glowWidthNarrow, size.height);
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
      case EdgeDirection.top:
        wideRect = Rect.fromLTWH(0, 0, size.width, glowWidthWide);
        narrowRect = Rect.fromLTWH(0, 0, size.width, glowWidthNarrow);
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
      case EdgeDirection.bottom:
        wideRect = Rect.fromLTWH(
            0, size.height - glowWidthWide, size.width, glowWidthWide);
        narrowRect = Rect.fromLTWH(
            0, size.height - glowWidthNarrow, size.width, glowWidthNarrow);
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
    }

    // Layer 1 — wide soft outer glow
    final wideOpacity = (envelope * 0.35).clamp(0.0, 1.0);
    final widePaint = Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [
          accentColor.withOpacity(wideOpacity),
          accentColor.withOpacity(wideOpacity * 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(wideRect);
    canvas.drawRect(wideRect, widePaint);

    // Layer 2 — narrow bright inner highlight streak
    final narrowOpacity = (envelope * 0.6).clamp(0.0, 1.0);
    final narrowPaint = Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [
          Colors.white.withOpacity(narrowOpacity * 0.7),
          accentColor.withOpacity(narrowOpacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(narrowRect);
    canvas.drawRect(narrowRect, narrowPaint);

    // Layer 3 — edge line accent
    final lineOpacity = (envelope * 0.5).clamp(0.0, 1.0);
    final linePaint = Paint()
      ..color = accentColor.withOpacity(lineOpacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    switch (glow.direction) {
      case EdgeDirection.left:
        canvas.drawLine(Offset.zero, Offset(0, size.height), linePaint);
      case EdgeDirection.right:
        canvas.drawLine(
            Offset(size.width, 0), Offset(size.width, size.height), linePaint);
      case EdgeDirection.top:
        canvas.drawLine(Offset.zero, Offset(size.width, 0), linePaint);
      case EdgeDirection.bottom:
        canvas.drawLine(
            Offset(0, size.height), Offset(size.width, size.height), linePaint);
    }
  }

  @override
  void dispose() => _glows.clear();
}
