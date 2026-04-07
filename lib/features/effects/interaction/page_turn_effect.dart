import 'package:flutter/material.dart';
import 'package:biscuitse/features/effects/interaction/interaction_effect.dart';

class _PageTurnAnimation {
  _PageTurnAnimation({required this.direction, required this.pageSize});

  /// +1 = forward (next page), -1 = backward (previous page).
  final int direction;
  final Size pageSize;
  double age = 0.0;

  static const double duration = 0.3;
  bool get isDone => age >= duration;
  double get progress => (age / duration).clamp(0.0, 1.0);
}

/// Page Turn Effect — 3D page curl when switching notebook pages.
///
/// - Curved page-curl sweep from one edge to the other
/// - Page shadow follows the curl
/// - Bright edge highlight on the fold
/// - Duration: 300 ms
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
    final eased = _easeInOut(anim.progress);

    // Curl position: starts at the originating edge, sweeps across
    final curlX = anim.direction > 0
        ? size.width * (1.0 - eased) // right → left for next page
        : size.width * eased; // left → right for prev page

    // ── Shadow gradient following the curl ─────────────────────────────────
    const shadowWidth = 40.0;
    final shadowLeft = anim.direction > 0 ? curlX - shadowWidth : curlX;
    final shadowRect =
        Rect.fromLTWH(shadowLeft, 0, shadowWidth, size.height);

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
          Colors.black
              .withOpacity((0.20 * intensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(shadowRect);
    canvas.drawRect(shadowRect, shadowPaint);

    // ── Bright edge highlight on the fold ──────────────────────────────────
    final edgeOpacity =
        ((1.0 - anim.progress) * 0.35 * intensity).clamp(0.0, 1.0);
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(edgeOpacity)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(curlX, 0),
      Offset(curlX, size.height),
      edgePaint,
    );

    // ── Darkened "back side" of the page behind the curl ──────────────────
    final backLeft = anim.direction > 0 ? 0.0 : curlX;
    final backWidth =
        anim.direction > 0 ? curlX : size.width - curlX;
    if (backWidth > 0) {
      final backRect = Rect.fromLTWH(backLeft, 0, backWidth, size.height);
      final backPaint = Paint()
        ..color = Colors.black.withOpacity(
            (0.08 * (1.0 - anim.progress) * intensity).clamp(0.0, 1.0));
      canvas.drawRect(backRect, backPaint);
    }
  }

  double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

  @override
  void dispose() => _current = null;
}
