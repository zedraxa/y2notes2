import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/features/effects/engine/easing_curves.dart';
import 'package:biscuits/features/effects/interaction/interaction_effect.dart';

class _PageTurnAnimation {
  _PageTurnAnimation({required this.direction, required this.pageSize});

  /// +1 = forward (next page), -1 = backward (previous page).
  final int direction;
  final Size pageSize;
  double age = 0.0;

  static const double duration = 0.45; // slightly longer for richer curl
  bool get isDone => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);
}

/// Page Turn Effect — realistic 3D page curl when switching notebook pages.
///
/// Enhanced multi-layer rendering:
/// - Bezier-curved fold line that arcs naturally across the page
/// - Gradient cylinder shadow along the curl for 3D depth
/// - Revealed "back side" of the page with paper-tone tinting
/// - Bright specular highlight on the fold edge
/// - Under-page shadow for elevation
/// - Spring-out easing for satisfying deceleration
/// - Duration: 450 ms
class PageTurnEffect implements InteractionEffect {
  @override
  final String id = 'page_turn';

  @override
  final String name = 'Page Turn';

  @override
  final String description =
      '3D page curl animation when switching notebook pages.';

  @override
  bool isEnabled = true;

  @override
  double intensity = 1.0;

  _PageTurnAnimation? _current;

  // ── Public trigger ──────────────────────────────────────────────────────────

  /// Start a page-turn animation.
  ///
  /// [direction] +1 = next page, -1 = previous page.
  void triggerPageTurn(int direction, Size pageSize) {
    if (!isEnabled) return;
    _current = _PageTurnAnimation(direction: direction, pageSize: pageSize);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    if (_current == null) return;
    _current!.age += dt;
    if (_current!.isDone) _current = null;
  }

  @override
  void render(Canvas canvas, Size size) {
    if (!isEnabled || _current == null) return;
    _renderPageCurl(canvas, size, _current!);
  }

  void _renderPageCurl(Canvas canvas, Size size, _PageTurnAnimation anim) {
    // Spring-out easing for natural deceleration with slight overshoot
    final eased = EasingCurves.springOut(anim.progress, damping: 10.0)
        .clamp(0.0, 1.0);
    final linearT = anim.progress;

    // Curl position: sweeps across the page width
    final curlX = anim.direction > 0
        ? size.width * (1.0 - eased)
        : size.width * eased;

    // Curl arc: the fold line bows outward at the middle of the page
    // creating a natural paper-curl arc (max deflection at vertical centre)
    final curlDepth = 30.0 * math.sin(linearT * math.pi) * intensity;

    // ── Layer 1 — Under-page shadow (soft wide shadow beneath the curl) ───
    final underShadowWidth = 60.0 * intensity;
    final underShadowLeft = anim.direction > 0
        ? curlX - underShadowWidth * 0.8
        : curlX - underShadowWidth * 0.2;
    if (underShadowWidth > 0) {
      final underRect = Rect.fromLTWH(
          underShadowLeft, 0, underShadowWidth, size.height);
      final underOpacity =
          (0.12 * math.sin(linearT * math.pi) * intensity).clamp(0.0, 1.0);
      final underPaint = Paint()
        ..shader = LinearGradient(
          begin: anim.direction > 0
              ? Alignment.centerRight
              : Alignment.centerLeft,
          end: anim.direction > 0
              ? Alignment.centerLeft
              : Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(underOpacity),
            Colors.black.withOpacity(underOpacity * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(underRect);
      canvas.drawRect(underRect, underPaint);
    }

    // ── Layer 2 — Darkened area (page that's been turned / revealed) ───────
    final backLeft = anim.direction > 0 ? 0.0 : curlX;
    final backWidth = anim.direction > 0 ? curlX : size.width - curlX;
    if (backWidth > 1) {
      final backRect = Rect.fromLTWH(backLeft, 0, backWidth, size.height);
      final backOpacity =
          (0.06 * (1.0 - linearT) * intensity).clamp(0.0, 1.0);
      final backPaint = Paint()
        ..color = Colors.black.withOpacity(backOpacity);
      canvas.drawRect(backRect, backPaint);
    }

    // ── Layer 3 — Paper back-side (narrow strip behind the curl) ──────────
    final backStripWidth = math.min(curlDepth * 2.5, 50.0 * intensity);
    if (backStripWidth > 1) {
      final stripLeft = anim.direction > 0
          ? curlX
          : curlX - backStripWidth;
      final stripRect =
          Rect.fromLTWH(stripLeft, 0, backStripWidth, size.height);
      // Warm paper tint for the "back" of the page
      final stripOpacity =
          (0.08 * math.sin(linearT * math.pi) * intensity).clamp(0.0, 1.0);
      final stripPaint = Paint()
        ..shader = LinearGradient(
          begin: anim.direction > 0
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: anim.direction > 0
              ? Alignment.centerRight
              : Alignment.centerLeft,
          colors: [
            const Color(0xFFF5ECD7).withOpacity(stripOpacity * 3),
            const Color(0xFFF5ECD7).withOpacity(stripOpacity),
          ],
        ).createShader(stripRect);
      canvas.drawRect(stripRect, stripPaint);
    }

    // ── Layer 4 — Cylinder shadow (tight gradient along the curl fold) ────
    final shadowWidth = 48.0 * intensity;
    final shadowLeft = anim.direction > 0
        ? curlX - shadowWidth * 0.6
        : curlX - shadowWidth * 0.4;
    final shadowRect = Rect.fromLTWH(shadowLeft, 0, shadowWidth, size.height);
    final shadowPeakOpacity =
        (0.25 * math.sin(linearT * math.pi) * intensity).clamp(0.0, 1.0);
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: anim.direction > 0
            ? Alignment.centerLeft
            : Alignment.centerRight,
        end: anim.direction > 0
            ? Alignment.centerRight
            : Alignment.centerLeft,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(shadowPeakOpacity * 0.3),
          Colors.black.withOpacity(shadowPeakOpacity),
          Colors.black.withOpacity(shadowPeakOpacity * 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(shadowRect);
    canvas.drawRect(shadowRect, shadowPaint);

    // ── Layer 5 — Bezier-curved fold line with specular highlight ──────────
    final foldPath = Path();
    const segments = 20;
    for (int i = 0; i <= segments; i++) {
      final yFraction = i / segments;
      final y = size.height * yFraction;
      // Quadratic bow: maximum deflection at vertical centre
      final bowFactor = 4.0 * yFraction * (1.0 - yFraction);
      final x = curlX + curlDepth * bowFactor * (anim.direction > 0 ? -1 : 1);
      if (i == 0) {
        foldPath.moveTo(x, y);
      } else {
        foldPath.lineTo(x, y);
      }
    }

    // Specular highlight: bright white line on the fold
    final specularOpacity =
        (0.45 * math.sin(linearT * math.pi) * intensity).clamp(0.0, 1.0);
    final specularPaint = Paint()
      ..color = Colors.white.withOpacity(specularOpacity)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(foldPath, specularPaint);

    // Secondary softer glow along the fold
    final glowOpacity = (specularOpacity * 0.3).clamp(0.0, 1.0);
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(glowOpacity)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(foldPath, glowPaint);
  }

  @override
  void dispose() => _current = null;
}
