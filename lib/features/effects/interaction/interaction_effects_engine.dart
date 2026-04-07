import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/particle_system.dart';
import 'package:y2notes2/features/effects/engine/effect_budget.dart';
import 'package:y2notes2/features/effects/interaction/delete_animation_effect.dart';
import 'package:y2notes2/features/effects/interaction/drag_shadow_effect.dart';
import 'package:y2notes2/features/effects/interaction/edge_bounce_effect.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effect.dart';
import 'package:y2notes2/features/effects/interaction/page_turn_effect.dart';
import 'package:y2notes2/features/effects/interaction/pinch_zoom_effect.dart';
import 'package:y2notes2/features/effects/interaction/selection_pulse_effect.dart';
import 'package:y2notes2/features/effects/interaction/snap_glow_effect.dart';
import 'package:y2notes2/features/effects/interaction/tool_switch_effect.dart';
import 'package:y2notes2/features/effects/interaction/touch_ripple_effect.dart';
import 'package:y2notes2/features/effects/interaction/undo_redo_effect.dart';

export 'package:y2notes2/features/effects/interaction/delete_animation_effect.dart'
    show DeleteStyle;
export 'package:y2notes2/features/effects/interaction/edge_bounce_effect.dart'
    show EdgeDirection;
export 'package:y2notes2/features/effects/interaction/interaction_effect.dart'
    show InteractionEffect;

/// Orchestrates all 10 interaction effects.
///
/// Parallel to [WritingEffectsEngine] but handles gesture/interaction feedback
/// rather than stroke-drawing effects.
///
/// Usage:
/// ```dart
/// engine.onTouchDown(position, toolColor: state.activeColor);
/// engine.update(dt);
/// engine.render(canvas, size);
/// ```
class InteractionEffectsEngine {
  InteractionEffectsEngine({
    EffectBudget? budget,
    /// Pass the [WritingEffectsEngine]'s particle system to share the budget.
    ParticleSystem? sharedParticles,
  }) : budget = budget ?? EffectBudget.detect() {
    _init(sharedParticles);
  }

  final EffectBudget budget;

  // ── The 10 interaction effects ─────────────────────────────────────────────

  late final TouchRippleEffect touchRipple;
  late final SnapGlowEffect snapGlow;
  late final SelectionPulseEffect selectionPulse;
  late final DeleteAnimationEffect deleteAnimation;
  late final DragShadowEffect dragShadow;
  late final PinchZoomEffect pinchZoom;
  late final PageTurnEffect pageTurn;
  late final UndoRedoEffect undoRedo;
  late final ToolSwitchEffect toolSwitch;
  late final EdgeBounceEffect edgeBounce;

  late final List<InteractionEffect> _all;
  late final ParticleSystem _particleSystem;

  /// Master on/off switch for all interaction effects.
  bool enabled = true;

  void _init(ParticleSystem? sharedParticles) {
    // Use the interaction share of the particle budget
    _particleSystem = sharedParticles ??
        ParticleSystem(maxParticles: budget.interactionMaxParticles);

    touchRipple = TouchRippleEffect();
    snapGlow = SnapGlowEffect();
    selectionPulse = SelectionPulseEffect();
    deleteAnimation = DeleteAnimationEffect()
      ..particleSystem = _particleSystem;
    dragShadow = DragShadowEffect();
    pinchZoom = PinchZoomEffect()..particleSystem = _particleSystem;
    pageTurn = PageTurnEffect();
    undoRedo = UndoRedoEffect();
    toolSwitch = ToolSwitchEffect()..particleSystem = _particleSystem;
    edgeBounce = EdgeBounceEffect();

    _all = [
      touchRipple,
      snapGlow,
      selectionPulse,
      deleteAnimation,
      dragShadow,
      pinchZoom,
      pageTurn,
      undoRedo,
      toolSwitch,
      edgeBounce,
    ];
  }

  // ── Effect enumeration (for settings UI) ──────────────────────────────────

  List<InteractionEffect> get allEffects => List.unmodifiable(_all);
  List<InteractionEffect> get enabledEffects =>
      _all.where((e) => e.isEnabled).toList();

  // ── Animation loop ─────────────────────────────────────────────────────────

  void update(double dt) {
    if (!enabled) return;
    _particleSystem.update(dt);
    for (final e in _all) {
      if (e.isEnabled) e.update(dt);
    }
  }

  void render(Canvas canvas, Size size) {
    if (!enabled) return;
    for (final e in enabledEffects) {
      e.render(canvas, size);
    }
    _particleSystem.render(canvas);
  }

  // ── Per-effect control ─────────────────────────────────────────────────────

  void setEffectEnabled(String id, bool value) {
    for (final e in _all) {
      if (e.id == id) {
        e.isEnabled = value;
        return;
      }
    }
  }

  void setEffectIntensity(String id, double value) {
    for (final e in _all) {
      if (e.id == id) {
        e.intensity = value;
        return;
      }
    }
  }

  // ── Typed trigger methods ──────────────────────────────────────────────────

  /// Touch/stylus contact at [position].
  ///
  /// [toolColor] is the current drawing tool colour.
  /// [pressure] (0.0–1.0) scales the ripple size.
  void onTouchDown(
    Offset position, {
    Color? toolColor,
    double pressure = 1.0,
  }) =>
      touchRipple.trigger(
        position,
        color: toolColor ?? const Color(0xFF4A90D9),
        pressure: pressure,
      );

  /// Shape/sticker snapped to an alignment guide from [lineStart] to [lineEnd].
  void onSnap(Offset lineStart, Offset lineEnd, {Color? color}) =>
      snapGlow.trigger(lineStart, lineEnd, color: color ?? const Color(0xFF4A90D9));

  /// Element with [elementId] was selected, occupying [bounds].
  void onElementSelected(String elementId, Rect bounds, {Color? color}) =>
      selectionPulse.startPulse(elementId, bounds, color: color);

  /// Element with [elementId] was deselected.
  void onElementDeselected(String elementId) =>
      selectionPulse.stopPulse(elementId);

  /// Update the selection [bounds] after an element moves/resizes.
  void onSelectionBoundsChanged(String elementId, Rect bounds) =>
      selectionPulse.updateBounds(elementId, bounds);

  /// An element occupying [bounds] was deleted.
  void onDelete(
    Rect bounds, {
    Color? color,
    DeleteStyle style = DeleteStyle.shatter,
    Offset swipeDirection = Offset.zero,
  }) =>
      deleteAnimation.triggerDelete(
        bounds,
        color: color ?? const Color(0xFF888888),
        style: style,
        swipeDirection: swipeDirection,
      );

  /// A drag began for [elementId] at [startPosition] with element [bounds].
  void onDragStart(String elementId, Rect bounds, Offset startPosition) =>
      dragShadow.startDrag(elementId, bounds, startPosition);

  /// The drag for [elementId] moved to [position].
  void onDragUpdate(String elementId, Offset position) =>
      dragShadow.updateDrag(elementId, position);

  /// The drag for [elementId] ended.
  void onDragEnd(String elementId) => dragShadow.endDrag(elementId);

  /// Canvas zoom changed to [scale] around [center].
  void onZoomChange(double scale, Offset center) =>
      pinchZoom.onZoomChange(scale, center);

  /// Zoom gesture ended.
  void onZoomEnd() => pinchZoom.onZoomEnd();

  /// Page navigation: [direction] +1 = next, -1 = prev.
  void onPageTurn(int direction, Size pageSize) =>
      pageTurn.triggerPageTurn(direction, pageSize);

  /// User triggered undo. [changedArea] is the bounds of affected content.
  void onUndo({Rect? changedArea}) =>
      undoRedo.triggerUndo(changedArea: changedArea);

  /// User triggered redo. [changedArea] is the bounds of affected content.
  void onRedo({Rect? changedArea}) =>
      undoRedo.triggerRedo(changedArea: changedArea);

  /// Active tool switched at [cursor] position.
  void onToolSwitch(
    Offset cursor, {
    Color? fromColor,
    Color? toColor,
  }) =>
      toolSwitch.triggerToolSwitch(
        cursor,
        fromColor: fromColor ?? const Color(0xFF4A90D9),
        toColor: toColor ?? const Color(0xFF4A90D9),
      );

  /// Canvas panning hit [direction] boundary.
  void onEdgeBounce(EdgeDirection direction) =>
      edgeBounce.triggerEdgeBounce(direction);

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  void dispose() {
    for (final e in _all) {
      e.dispose();
    }
    _particleSystem.clear();
  }
}
