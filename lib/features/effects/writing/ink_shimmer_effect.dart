import 'package:flutter/material.dart';
import 'package:biscuitse/core/constants/app_constants.dart';
import 'package:biscuitse/core/engine/particle_system.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import 'package:biscuitse/features/canvas/domain/entities/stroke.dart';
import 'package:biscuitse/features/effects/engine/effect_config.dart';

/// Ink Shimmer Effect — sparkle particles along a completed stroke.
///
/// After a stroke completes, emits small sparkle particles along the path
/// that twinkle and fade using the shared [ParticleSystem].
class InkShimmerEffect implements WritingEffect {
  InkShimmerEffect(this._particleSystem);

  final ParticleSystem _particleSystem;

  @override
  final String id = 'ink_shimmer';

  @override
  final String name = 'Ink Shimmer';

  @override
  final String description =
      'Small sparkle particles appear along each stroke and fade gracefully.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  static const _shimmerColors = [
    Color(0xFFFFD700),
    Color(0xFFFFF8DC),
    Color(0xFFE8F4FD),
    Color(0xFFB0E0E6),
    Color(0xFFDDA0DD),
  ];

  @override
  void onStrokeStart(PointData point) {}

  @override
  void onStrokePoint(
    PointData point,
    PointData? previous,
    Stroke activeStroke,
  ) {}

  @override
  void onStrokeEnd(Stroke completedStroke) {
    final points = completedStroke.points;
    if (points.isEmpty) return;

    final count = (AppConstants.shimmerParticleCount * intensity).round();

    // Distribute particles evenly along the stroke
    final step = (points.length / count).ceil();
    for (int i = 0; i < points.length; i += step) {
      final p = points[i];
      _particleSystem.emit(
        Offset(p.x, p.y),
        ParticleConfig(
          baseColor: _shimmerColors[i % _shimmerColors.length],
          colorVariations: _shimmerColors,
          minSize: 1.5,
          maxSize: 4.0,
          minLifetime: AppConstants.shimmerParticleLifetime * 0.7,
          maxLifetime: AppConstants.shimmerParticleLifetime * 1.3,
          gravity: -20.0,
          drag: 0.92,
          initialVelocity: Offset.zero,
          randomVelocitySpread: 15.0,
          shape: ParticleShape.sparkle,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    // Particle system is updated by the engine centrally.
  }

  @override
  void render(Canvas canvas, Size size) {
    // Particles are rendered by the particle system centrally.
  }

  @override
  void dispose() {}
}
