import 'package:flutter/material.dart';
import 'package:biscuitse/features/effects/interaction/interaction_effect.dart';

enum _FlashType { undo, redo }

class _FlashOverlay {
  _FlashOverlay({required this.type, required this.area});

  final _FlashType type;
  final Rect? area;
  double age = 0.0;

  // 0.2 s (200 ms) for undo / redo flash
  static const double duration = 0.2;
  bool get isDead => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);
}

/// Undo/Redo Flash Effect.
///
/// - Undo: brief blue flash over the changed area (100 ms peak)
/// - Redo: brief orange flash
/// - Pulsing border highlight around the changed area
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
    final opacity = (1.0 - flash.progress) * 0.25 * intensity;

    final color = flash.type == _FlashType.undo
        ? const Color(0xFF4A90D9) // blue for undo
        : const Color(0xFFFF9500); // orange for redo

    final renderRect =
        flash.area ?? Rect.fromLTWH(0, 0, size.width, size.height);

    // Fill flash
    final fillPaint = Paint()
      ..color = color.withOpacity(opacity.clamp(0.0, 1.0));
    canvas.drawRect(renderRect, fillPaint);

    // Border highlight (only when a specific area is known)
    if (flash.area != null) {
      final borderOpacity =
          ((1.0 - flash.progress) * 0.6 * intensity).clamp(0.0, 1.0);
      final borderPaint = Paint()
        ..color = color.withOpacity(borderOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(flash.area!, borderPaint);
    }
  }

  @override
  void dispose() => _flashes.clear();
}
