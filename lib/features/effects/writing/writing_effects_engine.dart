import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/particle_system.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_budget.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';
import 'package:y2notes2/features/effects/engine/effect_registry.dart';
import 'package:y2notes2/features/effects/writing/chalk_effect.dart';
import 'package:y2notes2/features/effects/writing/fountain_pen_effect.dart';
import 'package:y2notes2/features/effects/writing/ink_dry_effect.dart';
import 'package:y2notes2/features/effects/writing/ink_flow_effect.dart';
import 'package:y2notes2/features/effects/writing/ink_shimmer_effect.dart';
import 'package:y2notes2/features/effects/writing/neon_glow_effect.dart';
import 'package:y2notes2/features/effects/writing/pressure_bloom_effect.dart';
import 'package:y2notes2/features/effects/writing/rainbow_ink_effect.dart';
import 'package:y2notes2/features/effects/writing/trail_particles_effect.dart';
import 'package:y2notes2/features/effects/writing/watercolor_bleed_effect.dart';

/// Orchestrates all writing effects and the shared particle system.
///
/// Call [onStrokeStart], [onStrokePoint], [onStrokeEnd], [update], and
/// [render] from the canvas engine at the appropriate moments.
class WritingEffectsEngine {
  WritingEffectsEngine({EffectBudget? budget})
      : budget = budget ?? EffectBudget.detect() {
    _init();
  }

  final EffectBudget budget;
  late final ParticleSystem particleSystem;
  late final EffectRegistry _registry;

  /// Whether the engine is globally enabled.
  bool enabled = true;

  void _init() {
    particleSystem = ParticleSystem(maxParticles: budget.writingMaxParticles);
    _registry = EffectRegistry.instance;

    // Register all 10 effects
    _registry
      ..register(InkFlowEffect())
      ..register(PressureBloomEffect())
      ..register(InkShimmerEffect(particleSystem))
      ..register(NeonGlowEffect())
      ..register(WatercolorBleedEffect())
      ..register(FountainPenEffect())
      ..register(InkDryEffect())
      ..register(TrailParticlesEffect(particleSystem))
      ..register(RainbowInkEffect())
      ..register(ChalkEffect());
  }

  List<WritingEffect> get _active =>
      enabled ? _registry.enabled : [];

  /// Propagate stroke-start to all enabled effects.
  void onStrokeStart(PointData point) {
    for (final e in _active) {
      e.onStrokeStart(point);
    }
  }

  /// Propagate new stroke point to all enabled effects.
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) {
    for (final e in _active) {
      e.onStrokePoint(point, previous, activeStroke);
    }
  }

  /// Propagate stroke completion to all enabled effects.
  void onStrokeEnd(Stroke completedStroke) {
    for (final e in _active) {
      e.onStrokeEnd(completedStroke);
    }
  }

  /// Advance all effect animations and the particle system.
  void update(double dt) {
    if (!enabled) return;
    particleSystem.update(dt);
    for (final e in _registry.all) {
      if (e.isEnabled) e.update(dt);
    }
  }

  /// Render all enabled effect layers.
  void render(Canvas canvas, Size size) {
    if (!enabled) return;
    for (final e in _active) {
      e.render(canvas, size);
    }
    particleSystem.render(canvas);
  }

  /// Toggle a specific effect by [id].
  void setEffectEnabled(String id, bool value) {
    _registry.get(id)?.isEnabled = value;
  }

  /// Set intensity for a specific effect by [id].
  void setEffectIntensity(String id, double value) {
    _registry.get(id)?.intensity = value;
  }

  /// All registered effects (for settings UI enumeration).
  List<WritingEffect> get allEffects => _registry.all;

  /// Dispose all effects and clear the particle system.
  void dispose() {
    for (final e in _registry.all) {
      e.dispose();
    }
    particleSystem.clear();
    _registry.clear();
  }
}
