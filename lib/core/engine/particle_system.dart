import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/core/constants/app_constants.dart';
import 'package:biscuits/core/utils/device_capability.dart';

/// Particle shape variants.
enum ParticleShape { circle, star, sparkle, square }

/// Configuration for a particle emission burst.
class ParticleConfig {
  const ParticleConfig({
    required this.baseColor,
    this.colorVariations,
    this.minSize = 2.0,
    this.maxSize = 6.0,
    this.minLifetime = 0.4,
    this.maxLifetime = 1.2,
    this.gravity = 0.0,
    this.drag = 0.95,
    this.initialVelocity = Offset.zero,
    this.randomVelocitySpread = 40.0,
    this.shape = ParticleShape.circle,
  });

  final Color baseColor;
  final List<Color>? colorVariations;
  final double minSize;
  final double maxSize;
  final double minLifetime;
  final double maxLifetime;

  /// Gravity acceleration (px/s²).
  final double gravity;

  /// Velocity damping per frame (0.0 – 1.0).
  final double drag;

  final Offset initialVelocity;
  final double randomVelocitySpread;
  final ParticleShape shape;
}

/// A single active particle.
class Particle {
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
    required this.shape,
  }) : age = 0.0,
       opacity = 1.0;

  Offset position;
  Offset velocity;
  Color color;
  double size;
  double opacity;
  double age;
  final double lifetime;
  final ParticleShape shape;

  bool get isDead => age >= lifetime;
  double get normalizedAge => (age / lifetime).clamp(0.0, 1.0);
}

/// Shared particle engine used by ALL writing/interaction effects.
class ParticleSystem {
  ParticleSystem({int? maxParticles})
      : maxParticles = maxParticles ?? _defaultMax();

  static int _defaultMax() {
    switch (DeviceCapability.detect()) {
      case DeviceTier.high:
        return AppConstants.maxParticlesHigh;
      case DeviceTier.medium:
        return AppConstants.maxParticlesMedium;
      case DeviceTier.low:
        return AppConstants.maxParticlesLow;
    }
  }

  final List<Particle> particles = [];
  final int maxParticles;
  final math.Random _random = math.Random();

  /// Emit a single particle at [position].
  void emit(Offset position, ParticleConfig config) {
    if (particles.length >= maxParticles) return;
    particles.add(_buildParticle(position, config));
  }

  /// Emit [count] particles in a burst at [position].
  void emitBurst(Offset position, int count, ParticleConfig config) {
    final available = maxParticles - particles.length;
    final actual = math.min(count, available);
    for (int i = 0; i < actual; i++) {
      particles.add(_buildParticle(position, config));
    }
  }

  Particle _buildParticle(Offset position, ParticleConfig config) {
    final spread = config.randomVelocitySpread;
    final vx = config.initialVelocity.dx +
        (_random.nextDouble() - 0.5) * 2 * spread;
    final vy = config.initialVelocity.dy +
        (_random.nextDouble() - 0.5) * 2 * spread;

    final colors = config.colorVariations;
    final color = (colors != null && colors.isNotEmpty)
        ? colors[_random.nextInt(colors.length)]
        : config.baseColor;

    final size = config.minSize +
        _random.nextDouble() * (config.maxSize - config.minSize);
    final lifetime = config.minLifetime +
        _random.nextDouble() * (config.maxLifetime - config.minLifetime);

    return Particle(
      position: position,
      velocity: Offset(vx, vy),
      color: color,
      size: size,
      lifetime: lifetime,
      shape: config.shape,
    );
  }

  /// Advance the simulation by [dt] seconds.
  void update(double dt) {
    for (final p in particles) {
      p.age += dt;
      // Apply gravity and drag
      final vx = p.velocity.dx * 0.97;
      final vy = (p.velocity.dy + 9.8 * 10 * dt) * 0.97;
      p.velocity = Offset(vx, vy);
      p.position = p.position + p.velocity * dt;
      // Fade out over lifetime
      p.opacity = (1.0 - p.normalizedAge).clamp(0.0, 1.0);
    }
    particles.removeWhere((p) => p.isDead);
  }

  /// Draw all active particles onto [canvas].
  void render(Canvas canvas) {
    for (final p in particles) {
      _renderParticle(canvas, p);
    }
  }

  void _renderParticle(Canvas canvas, Particle p) {
    final paint = Paint()
      ..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    switch (p.shape) {
      case ParticleShape.circle:
        canvas.drawCircle(p.position, p.size * 0.5, paint);
      case ParticleShape.square:
        canvas.drawRect(
          Rect.fromCenter(
            center: p.position,
            width: p.size,
            height: p.size,
          ),
          paint,
        );
      case ParticleShape.sparkle:
        _renderSparkle(canvas, p, paint);
      case ParticleShape.star:
        _renderStar(canvas, p, paint);
    }
  }

  void _renderSparkle(Canvas canvas, Particle p, Paint paint) {
    final path = Path();
    final s = p.size;
    // Four-point sparkle / cross
    path
      ..moveTo(p.position.dx, p.position.dy - s)
      ..lineTo(p.position.dx + s * 0.2, p.position.dy - s * 0.2)
      ..lineTo(p.position.dx + s, p.position.dy)
      ..lineTo(p.position.dx + s * 0.2, p.position.dy + s * 0.2)
      ..lineTo(p.position.dx, p.position.dy + s)
      ..lineTo(p.position.dx - s * 0.2, p.position.dy + s * 0.2)
      ..lineTo(p.position.dx - s, p.position.dy)
      ..lineTo(p.position.dx - s * 0.2, p.position.dy - s * 0.2)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _renderStar(Canvas canvas, Particle p, Paint paint) {
    const points = 5;
    final path = Path();
    final outer = p.size;
    final inner = p.size * 0.4;
    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? outer : inner;
      final angle = (math.pi * i / points) - math.pi / 2;
      final x = p.position.dx + r * math.cos(angle);
      final y = p.position.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Remove all particles.
  void clear() => particles.clear();

  /// Number of active particles.
  int get count => particles.length;
}
