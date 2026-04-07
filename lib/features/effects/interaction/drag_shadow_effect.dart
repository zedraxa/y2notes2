import 'package:flutter/material.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effect.dart';

class _DragState {
  _DragState({
    required this.elementId,
    required this.startPosition,
    required this.currentPosition,
    required this.bounds,
  });

  final String elementId;
  final Offset startPosition;
  Offset currentPosition;
  Rect bounds;
  final List<Offset> trail = []; // previous positions for trail effect
  double settleProgress = 0.0;
  bool settling = false;
  bool done = false;

  // Keep at most 4 trail samples
  static const int maxTrail = 4;
}

/// Drag Shadow Effect — elevated shadow, ghost & motion trail while dragging.
///
/// - Lifted shadow (larger, softer) simulates picking up the element
/// - 20%-opacity ghost copy at the starting position
/// - 3–4 semi-transparent trail copies at previous positions
/// - On drop: shadow settles back with a bounce (100 ms)
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
        // 100 ms settle animation
        drag.settleProgress = (drag.settleProgress + dt / 0.1).clamp(0.0, 1.0);
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

    if (drag.settling) {
      final shadowOpacity =
          ((1.0 - drag.settleProgress) * 0.3 * intensity).clamp(0.0, 1.0);
      _drawShadow(canvas, boundsAtCurrent, shadowOpacity);
      return;
    }

    // Ghost at original position (20% opacity)
    _drawGhostRect(canvas, drag.bounds, (0.10 * intensity).clamp(0.0, 1.0));

    // Motion trail
    for (int i = 0; i < drag.trail.length; i++) {
      final trailDelta = drag.trail[i] - drag.startPosition;
      final trailBounds = drag.bounds.shift(trailDelta);
      final trailOpacity =
          ((i + 1) / drag.trail.length * 0.12 * intensity).clamp(0.0, 1.0);
      _drawGhostRect(canvas, trailBounds, trailOpacity);
    }

    // Lifted shadow under current position
    _drawShadow(canvas, boundsAtCurrent, 0.3 * intensity);
  }

  void _drawGhostRect(Canvas canvas, Rect rect, double opacity) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
  }

  void _drawShadow(Canvas canvas, Rect bounds, double opacity) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(opacity.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawRect(bounds.inflate(8), shadowPaint);
  }

  @override
  void dispose() => _drags.clear();
}
