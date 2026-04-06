import 'package:flutter/material.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/core/engine/particle_system.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Trail Particles Effect — particles stream from the pen tip while drawing.
///
/// Emits 10–30 particles per second that drift and fade over 0.8 s.
class TrailParticlesEffect implements WritingEffect {
  TrailParticlesEffect(this._particleSystem);

  final ParticleSystem _particleSystem;

  @override
  final String id = 'trail_particles';

  @override
  final String name = 'Trail Particles';

  @override
  final String description =
      'Tiny particles stream from the pen tip as you draw, like magic dust.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Seconds since last emission.
  double _timeSinceEmit = 0.0;
  Color _currentColor = const Color(0xFF4A90D9);
  Offset? _currentPosition;

  @override
  void onStrokeStart(PointData point) {
    _currentColor = const Color(0xFF4A90D9);
    _currentPosition = Offset(point.x, point.y);
    _timeSinceEmit = 0.0;
  }

  @override
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) {
    _currentColor = activeStroke.color;
    _currentPosition = Offset(point.x, point.y);
  }

  @override
  void onStrokeEnd(Stroke completedStroke) {
    _currentPosition = null;
    _timeSinceEmit = 0.0;
  }

  @override
  void update(double dt) {
    _timeSinceEmit += dt;
    final emitInterval =
        1.0 / (AppConstants.trailParticleRate * intensity);

    if (_currentPosition != null && _timeSinceEmit >= emitInterval) {
      _timeSinceEmit = 0.0;
      _particleSystem.emit(
        _currentPosition!,
        ParticleConfig(
          baseColor: _currentColor,
          colorVariations: [
            _currentColor,
            _currentColor.withOpacity(0.7),
            Colors.white.withOpacity(0.6),
          ],
          minSize: 1.0,
          maxSize: 3.5,
          minLifetime: AppConstants.trailParticleLifetime * 0.6,
          maxLifetime: AppConstants.trailParticleLifetime * 1.2,
          gravity: -15.0,
          drag: 0.90,
          initialVelocity: Offset.zero,
          randomVelocitySpread: 25.0 * intensity,
          shape: ParticleShape.circle,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas, Size size) {
    // Particle system renders centrally.
  }

  @override
  void dispose() {
    _currentPosition = null;
  }
}
