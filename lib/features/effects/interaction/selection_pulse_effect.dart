import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effect.dart';

class _PulsingSelection {
  _PulsingSelection({
    required this.id,
    required this.bounds,
    required this.color,
  });

  final String id;
  Rect bounds;
  final Color color;
  double age = 0.0;
  bool active = true;
  double dismissAge = 0.0;

  static const double dismissDuration = 0.2;
}

/// Selection Pulse Effect — animated highlight border on selected elements.
///
/// - Sin-wave opacity (0.3 → 0.8 → 0.3) with a 1.2 s period
/// - Dashed "marching ants" border rotating around the selection
/// - Corner handle glow
/// - Soft drop shadow beneath the selected element
/// - Multi-select: each item pulses in sync
class SelectionPulseEffect implements InteractionEffect {
  @override
  final String id = 'selection_pulse';

  @override
  final String name = 'Selection Pulse';

  @override
  final String description =
      'Selected objects gently pulse to indicate their active state.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final Map<String, _PulsingSelection> _selections = {};
  double _dashOffset = 0.0;

  // ── Public triggers ─────────────────────────────────────────────────────────

  /// Start a pulsing highlight around [bounds] for element [elementId].
  void startPulse(String elementId, Rect bounds, {Color? color}) {
    if (!isEnabled) return;
    _selections[elementId] = _PulsingSelection(
      id: elementId,
      bounds: bounds,
      color: color ?? const Color(0xFF4A90D9),
    );
  }

  /// Update selection bounds without restarting the animation.
  void updateBounds(String elementId, Rect bounds) {
    _selections[elementId]?.bounds = bounds;
  }

  /// Stop pulsing for [elementId].
  void stopPulse(String elementId) {
    _selections[elementId]?.active = false;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    // Advance dash animation (px/s)
    _dashOffset += dt * 30.0;

    for (final sel in _selections.values) {
      sel.age += dt;
      if (!sel.active) sel.dismissAge += dt;
    }
    _selections.removeWhere(
      (_, s) => !s.active && s.dismissAge >= _PulsingSelection.dismissDuration,
    );
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!isEnabled || _selections.isEmpty) return;
    for (final sel in _selections.values) {
      _renderSelection(canvas, sel);
    }
  }

  void _renderSelection(Canvas canvas, _PulsingSelection sel) {
    // Sin-wave opacity: 0.3 → 0.8 → 0.3, period 1.2 s
    final sinVal = math.sin(sel.age * 2 * math.pi / 1.2);
    final opacity = (0.55 + sinVal * 0.25).clamp(0.3, 0.8) * intensity;

    double alphaMult = 1.0;
    if (!sel.active) {
      alphaMult = 1.0 -
          (sel.dismissAge / _PulsingSelection.dismissDuration).clamp(0.0, 1.0);
    }

    final rect = sel.bounds.inflate(4.0);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4.0));

    // Drop shadow
    final shadowPaint = Paint()
      ..color = sel.color.withOpacity((0.15 * alphaMult * intensity).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRRect(rrect.inflate(4), shadowPaint);

    // Marching-ants dashed border
    _drawDashedBorder(canvas, rect, sel.color, (opacity * alphaMult).clamp(0.0, 1.0));

    // Corner handle glow
    _drawCornerHandles(canvas, rect, sel.color, (opacity * alphaMult).clamp(0.0, 1.0));
  }

  void _drawCornerHandles(Canvas canvas, Rect rect, Color color, double opacity) {
    const handleSize = 8.0;
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];

    final paint = Paint()
      ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
      ..style = PaintingStyle.fill;

    for (final corner in corners) {
      canvas.drawRect(
        Rect.fromCenter(center: corner, width: handleSize, height: handleSize),
        paint,
      );
    }
  }

  void _drawDashedBorder(Canvas canvas, Rect rect, Color color, double opacity) {
    final paint = Paint()
      ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final sourcePath = Path()..addRect(rect);
    final dashedPath = _createDashedPath(
      sourcePath,
      dashLength: 8.0,
      gapLength: 4.0,
      offset: _dashOffset,
    );
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(
    Path source, {
    required double dashLength,
    required double gapLength,
    required double offset,
  }) {
    final dashedPath = Path();
    final metrics = source.computeMetrics();

    for (final metric in metrics) {
      final total = metric.length;
      final stride = dashLength + gapLength;
      // Start at a negative offset so the animation wraps smoothly
      double distance = -(offset % stride);

      while (distance < total) {
        final start = distance.clamp(0.0, total);
        final end = (distance + dashLength).clamp(0.0, total);
        if (start < end) {
          dashedPath.addPath(metric.extractPath(start, end), Offset.zero);
        }
        distance += stride;
      }
    }
    return dashedPath;
  }

  @override
  void dispose() => _selections.clear();
}
