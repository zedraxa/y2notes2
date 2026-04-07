import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effect.dart';

class _DragState {
  _DragState({
    required this.elementId,
    required this.startPosition,
    required this.currentPosition,
    required this.bounds,
  }) : previousPosition = startPosition;

  final String elementId;
  final Offset startPosition;
  Offset currentPosition;
  Offset previousPosition;
  Rect bounds;
  final List<Offset> trail = []; // previous positions for trail effect
  double settleProgress = 0.0;
  bool settling = false;
  bool done = false;
  double speed = 0.0; // current drag speed in px/frame

  // Keep at most 4 trail samples
  static const int maxTrail = 4;
}

/// Drag Shadow Effect — elevated shadow, ghost & motion trail while dragging.
///
/// - Dynamic blur scaling based on drag speed
/// - Rounded-rect rendering for polished element shapes
/// - Parallax-offset trail layers with depth-based opacity
/// - Elastic overshoot-bounce settle animation (200 ms)
class DragShadowEffect implements InteractionEffect {
  @override
  final String id = 'drag_shadow';

  @override
  final String name = 'Drag Shadow';

  @override
  final String description =
      'Objects cast a realistic shadow while being dragged, giving a '
      'sense of elevation.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final Map<String, _DragState> _drags = {};

  // ── Public triggers ─────────────────────────────────────────────────────────

  /// Begin tracking a drag for [elementId].
  void startDrag(String elementId, Rect bounds, Offset startPosition) {
    if (!isEnabled) return;
    _drags[elementId] = _DragState(
      elementId: elementId,
      startPosition: startPosition,
      currentPosition: startPosition,
      bounds: bounds,
    );
  }

  /// Update the current drag [position] for [elementId].
  void updateDrag(String elementId, Offset position) {
    final drag = _drags[elementId];
    if (drag == null) return;
    drag.trail.add(drag.currentPosition);
    if (drag.trail.length > _DragState.maxTrail) drag.trail.removeAt(0);
    drag.speed = (position - drag.currentPosition).distance; // px per frame
    drag.previousPosition = drag.currentPosition;
    drag.currentPosition = position;
  }

  /// End the drag — plays settle-bounce animation.
  void endDrag(String elementId) {
    final drag = _drags[elementId];
    if (drag == null) return;
    drag.settling = true;
    drag.trail.clear();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    for (final drag in _drags.values) {
      if (drag.settling) {
        // 200 ms elastic settle animation
        drag.settleProgress = (drag.settleProgress + dt / 0.2).clamp(0.0, 1.0);
        if (drag.settleProgress >= 1.0) drag.done = true;
      }
    }
    _drags.removeWhere((_, d) => d.done);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!isEnabled || _drags.isEmpty) return;
    for (final drag in _drags.values) {
      _renderDrag(canvas, drag);
    }
  }

  void _renderDrag(Canvas canvas, _DragState drag) {
    final delta = drag.currentPosition - drag.startPosition;
    final boundsAtCurrent = drag.bounds.shift(delta);
    final cornerRadius = Radius.circular(6.0 * intensity);

    if (drag.settling) {
      // Elastic overshoot bounce: scale overshoots to 1.03x then settles to 1.0
      final t = drag.settleProgress;
      final elastic = 1.0 + 0.03 * math.sin(t * math.pi * 2) * (1.0 - t);
      final settleRect = _scaleRect(boundsAtCurrent, elastic);

      final shadowOpacity =
          ((1.0 - t) * 0.35 * intensity).clamp(0.0, 1.0);
      _drawRoundedShadow(canvas, settleRect, shadowOpacity, cornerRadius,
          blurSigma: 8.0 * (1.0 - t));
      return;
    }

    // Dynamic blur scales with drag speed
    final speedFactor = (drag.speed / 20.0).clamp(0.5, 2.5);

    // Ghost at original position — subtle rounded rect
    _drawGhostRoundedRect(
        canvas, drag.bounds, (0.10 * intensity).clamp(0.0, 1.0), cornerRadius);

    // Parallax motion trail — each layer offset slightly less than actual
    for (int i = 0; i < drag.trail.length; i++) {
      final trailDelta = drag.trail[i] - drag.startPosition;
      // Parallax: deeper layers lag behind more
      final parallaxFactor = 0.85 + (i / drag.trail.length) * 0.15;
      final parallaxDelta = trailDelta * parallaxFactor;
      final trailBounds = drag.bounds.shift(parallaxDelta);
      final depthOpacity =
          ((i + 1) / drag.trail.length * 0.14 * intensity).clamp(0.0, 1.0);
      _drawGhostRoundedRect(canvas, trailBounds, depthOpacity, cornerRadius);
    }

    // Lifted shadow under current position — blur scales with speed
    _drawRoundedShadow(canvas, boundsAtCurrent, 0.30 * intensity, cornerRadius,
        blurSigma: 10.0 * speedFactor);

    // Subtle elevation highlight on top edge
    final highlightRect = RRect.fromRectAndRadius(
      boundsAtCurrent.inflate(1),
      cornerRadius,
    );
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity((0.08 * intensity).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(highlightRect, highlightPaint);
  }

  void _drawGhostRoundedRect(
      Canvas canvas, Rect rect, double opacity, Radius radius) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
  }

  void _drawRoundedShadow(
      Canvas canvas, Rect bounds, double opacity, Radius radius,
      {double blurSigma = 12.0}) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(opacity.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.inflate(6), radius),
      shadowPaint,
    );
  }

  Rect _scaleRect(Rect rect, double scale) {
    final center = rect.center;
    final w = rect.width * scale;
    final h = rect.height * scale;
    return Rect.fromCenter(center: center, width: w, height: h);
  }

  @override
  void dispose() => _drags.clear();
}
