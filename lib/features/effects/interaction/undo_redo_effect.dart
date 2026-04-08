import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/features/effects/interaction/interaction_effect.dart';

enum _FlashType { undo, redo }

class _FlashOverlay {
  _FlashOverlay({required this.type, required this.area});

  final _FlashType type;
  final Rect? area;
  double age = 0.0;

  // 0.35 s (350 ms) for richer undo / redo flash
  static const double duration = 0.35;
  bool get isDead => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);
}

/// Undo/Redo Flash Effect.
///
/// - Undo: radial gradient blue flash with expanding ring wave
/// - Redo: radial gradient orange flash with expanding ring wave
/// - Pulsing rounded-corner border highlight around the changed area
class UndoRedoEffect implements InteractionEffect {
  @override
  final String id = 'undo_redo';

  @override
  final String name = 'Undo/Redo Flash';

  @override
  final String description =
      'Brief colour flash when undoing or redoing actions.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  final List<_FlashOverlay> _flashes = [];

  // ── Public triggers ─────────────────────────────────────────────────────────

  /// Trigger a blue flash for an undo action.
  ///
  /// [changedArea] bounds the region that was affected (null = full canvas).
  void triggerUndo({Rect? changedArea}) {
    if (!isEnabled) return;
    _flashes.add(_FlashOverlay(type: _FlashType.undo, area: changedArea));
  }

  /// Trigger an orange flash for a redo action.
  void triggerRedo({Rect? changedArea}) {
    if (!isEnabled) return;
    _flashes.add(_FlashOverlay(type: _FlashType.redo, area: changedArea));
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    for (final f in _flashes) {
      f.age += dt;
    }
    _flashes.removeWhere((f) => f.isDead);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!isEnabled || _flashes.isEmpty) return;
    for (final f in _flashes) {
      _renderFlash(canvas, size, f);
    }
  }

  void _renderFlash(Canvas canvas, Size size, _FlashOverlay flash) {
    final t = flash.progress;
    // ease-out: fast start, slow end
    final ease = 1.0 - math.pow(1.0 - t, 3);
    final fade = 1.0 - t;

    final color = flash.type == _FlashType.undo
        ? const Color(0xFF4A90D9) // blue for undo
        : const Color(0xFFFF9500); // orange for redo

    final renderRect =
        flash.area ?? Rect.fromLTWH(0, 0, size.width, size.height);
    final center = renderRect.center;

    // Layer 1 — radial gradient flash (bright center fading to edges)
    final maxRadius =
        math.sqrt(renderRect.width * renderRect.width +
            renderRect.height * renderRect.height) *
        0.5;
    final gradientOpacity = (0.20 * intensity * fade).clamp(0.0, 1.0);
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          color.withOpacity(gradientOpacity),
          color.withOpacity(gradientOpacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(renderRect);
    canvas.drawRect(renderRect, gradientPaint);

    // Layer 2 — expanding ring wave from center
    final ringRadius = maxRadius * ease * 0.7;
    final ringOpacity = (0.30 * intensity * fade).clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..color = color.withOpacity(ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (1.0 - t * 0.5);
    canvas.drawCircle(center, ringRadius, ringPaint);

    // Layer 3 — secondary softer ring (slightly delayed)
    final ring2Progress = (t * 1.3 - 0.15).clamp(0.0, 1.0);
    if (ring2Progress > 0) {
      final ring2Radius = maxRadius * ring2Progress * 0.5;
      final ring2Opacity =
          (0.15 * intensity * (1.0 - ring2Progress)).clamp(0.0, 1.0);
      final ring2Paint = Paint()
        ..color = color.withOpacity(ring2Opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, ring2Radius, ring2Paint);
    }

    // Layer 4 — pulsing rounded-corner border highlight
    if (flash.area != null) {
      final pulsePhase = math.sin(t * math.pi * 2) * 0.5 + 0.5;
      final borderOpacity =
          (fade * 0.5 * intensity * (0.5 + pulsePhase * 0.5)).clamp(0.0, 1.0);
      final borderPaint = Paint()
        ..color = color.withOpacity(borderOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(flash.area!, const Radius.circular(4.0)),
        borderPaint,
      );

      // Outer glow border
      final glowOpacity = (fade * 0.2 * intensity).clamp(0.0, 1.0);
      final glowPaint = Paint()
        ..color = color.withOpacity(glowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            flash.area!.inflate(2), const Radius.circular(6.0)),
        glowPaint,
      );
    }
  }

  @override
  void dispose() => _flashes.clear();
}
