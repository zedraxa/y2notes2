import 'package:flutter/material.dart';
import 'package:biscuitse/core/engine/particle_system.dart';
import 'package:biscuitse/features/effects/interaction/interaction_effect.dart';

/// Pinch Zoom Effect — visual feedback during canvas pinch-zoom gestures.
///
/// - Subtle vignette darkening at edges during zoom
/// - Floating zoom-level indicator ("150%") that fades in/out
/// - Particle scatter at zoom centre on fast zoom-in
class PinchZoomEffect implements InteractionEffect {
  @override
  final String id = 'pinch_zoom';

  @override
  final String name = 'Pinch Zoom';

  @override
  final String description = 'Visual feedback during pinch-zoom gestures.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  /// Inject the shared [ParticleSystem] for the fast-zoom burst.
  ParticleSystem? particleSystem;

  double _currentScale = 1.0;
  double _previousScale = 1.0;
  Offset _zoomCenter = Offset.zero;
  bool _isZooming = false;
  double _indicatorAge = 0.0;
  double _indicatorOpacity = 0.0;
  double _vignetteOpacity = 0.0;
  bool _hasFiredFastZoomParticles = false;

  static const double _indicatorLingerDuration = 1.5;
  static const double _fastZoomDelta = 0.08;

  String _zoomLevelText = '100%';

  // ── Public triggers ─────────────────────────────────────────────────────────

  /// Call every time the InteractiveViewer scale changes.
  void onZoomChange(double scale, Offset center) {
    if (!isEnabled) return;
    final delta = scale - _previousScale;
    _currentScale = scale;
    _zoomCenter = center;
    _isZooming = true;
    _indicatorAge = 0.0;
    _vignetteOpacity =
        (delta.abs() * 10.0 * intensity).clamp(0.0, 0.3 * intensity);
    _zoomLevelText = '${(scale * 100).round()}%';

    // Fast zoom-in → particle scatter (fire once per zoom gesture)
    if (delta > _fastZoomDelta && !_hasFiredFastZoomParticles) {
      _hasFiredFastZoomParticles = true;
      particleSystem?.emitBurst(
        center,
        8,
        const ParticleConfig(
          baseColor: Color(0xFF4A90D9),
          minSize: 1.5,
          maxSize: 4.0,
          randomVelocitySpread: 60.0,
          shape: ParticleShape.sparkle,
        ),
      );
    }
    _previousScale = scale;
  }

  /// Call when the zoom gesture ends.
  void onZoomEnd() {
    _isZooming = false;
    _hasFiredFastZoomParticles = false;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    if (_isZooming) {
      _indicatorOpacity = (_indicatorOpacity + dt * 8.0).clamp(0.0, 1.0);
    } else {
      _indicatorAge += dt;
      _indicatorOpacity =
          (1.0 - (_indicatorAge / _indicatorLingerDuration)).clamp(0.0, 1.0);
      _vignetteOpacity = (_vignetteOpacity - dt * 2.0).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!isEnabled) return;
    if (_vignetteOpacity > 0.01) _renderVignette(canvas, size);
    if (_indicatorOpacity > 0.02) _renderZoomIndicator(canvas, size);
  }

  void _renderVignette(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          Colors.black
              .withOpacity((_vignetteOpacity * intensity).clamp(0.0, 1.0)),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _renderZoomIndicator(Canvas canvas, Size size) {
    final opacity = (_indicatorOpacity * intensity).clamp(0.0, 1.0);

    const pillWidth = 80.0;
    const pillHeight = 28.0;
    final center = Offset(size.width - 64.0, 44.0);
    final rect = Rect.fromCenter(
        center: center, width: pillWidth, height: pillHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14.0));

    // Pill background
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity((0.6 * opacity).clamp(0.0, 1.0));
    canvas.drawRRect(rrect, bgPaint);

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: _zoomLevelText,
        style: TextStyle(
          color: Colors.white.withOpacity(opacity),
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  void dispose() {}
}
