import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:y2notes2/core/constants/app_constants.dart';
import 'package:y2notes2/core/engine/particle_system.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Ink Shimmer Effect — sparkle particles along a completed stroke.
///
/// After a stroke completes, emits sparkle particles with a delayed cascade
/// along the path. Each sparkle pulses in size using a sine wave and renders
/// a secondary glow halo beneath the particle for added shimmer.
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

  // Pending cascade emissions
  final List<_CascadeEmission> _pendingEmissions = [];

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

    // Build cascade emissions with staggered delays along the stroke
    final step = (points.length / count).ceil();
    for (int i = 0; i < points.length; i += step) {
      final p = points[i];
      final delay = (i / points.length) * 0.3; // up to 300ms cascade
      _pendingEmissions.add(_CascadeEmission(
        position: Offset(p.x, p.y),
        colorIndex: i % _shimmerColors.length,
        delay: delay,
        age: 0.0,
      ));
    }
  }

  @override
  void update(double dt) {
    // Process cascade emissions
    for (final emission in _pendingEmissions) {
      emission.age += dt;
      if (emission.age >= emission.delay && !emission.emitted) {
        emission.emitted = true;
        // Primary sparkle particle
        _particleSystem.emit(
          emission.position,
          ParticleConfig(
            baseColor: _shimmerColors[emission.colorIndex],
            colorVariations: _shimmerColors,
            minSize: 1.5,
            maxSize: 4.5,
            minLifetime: AppConstants.shimmerParticleLifetime * 0.7,
            maxLifetime: AppConstants.shimmerParticleLifetime * 1.5,
            gravity: -20.0,
            drag: 0.92,
            initialVelocity: Offset.zero,
            randomVelocitySpread: 15.0,
            shape: ParticleShape.sparkle,
          ),
        );
        // Secondary glow halo particle — larger, softer, shorter-lived
        _particleSystem.emit(
          emission.position,
          ParticleConfig(
            baseColor: _shimmerColors[emission.colorIndex].withOpacity(0.3),
            minSize: 4.0,
            maxSize: 8.0,
            minLifetime: AppConstants.shimmerParticleLifetime * 0.4,
            maxLifetime: AppConstants.shimmerParticleLifetime * 0.7,
            gravity: -5.0,
            drag: 0.96,
            initialVelocity: Offset.zero,
            randomVelocitySpread: 6.0,
            shape: ParticleShape.circle,
          ),
        );
      }
    }
    _pendingEmissions.removeWhere((e) => e.emitted);
  }

  @override
  void render(Canvas canvas, Size size) {
    // Particles are rendered by the particle system centrally.
    // Render additional twinkle halos on top of the particle system output
    for (final p in _particleSystem.particles) {
      if (p.shape == ParticleShape.sparkle && !p.isDead) {
        // Sine-wave twinkle: modulates opacity for a pulsing glint
        final twinkle = (math.sin(p.age * math.pi * 6) * 0.5 + 0.5);
        final haloOpacity = (p.opacity * 0.2 * twinkle * intensity).clamp(0.0, 1.0);
        if (haloOpacity > 0.01) {
          final haloPaint = Paint()
            ..color = p.color.withOpacity(haloOpacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
          canvas.drawCircle(p.position, p.size * 1.5, haloPaint);
        }
      }
    }
  }

  @override
  void dispose() => _pendingEmissions.clear();
}

class _CascadeEmission {
  _CascadeEmission({
    required this.position,
    required this.colorIndex,
    required this.delay,
    required this.age,
  });

  final Offset position;
  final int colorIndex;
  final double delay;
  double age;
  bool emitted = false;
}
