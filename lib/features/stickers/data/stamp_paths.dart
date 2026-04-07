import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Provides programmatic [Path] definitions for stamp shapes.
/// All paths are defined in a [-50, 50] coordinate system (100x100 unit box).
class StampPaths {
  StampPaths._();

  static Path get(String id) {
    switch (id) {
      case 'star':
        return _star();
      case 'heart':
        return _heart();
      case 'circle':
        return _circle();
      case 'square':
        return _square();
      case 'triangle':
        return _triangle();
      case 'diamond':
        return _diamond();
      case 'cross':
        return _cross();
      case 'arrow_up':
        return _arrowUp();
      case 'arrow_down':
        return _arrowDown();
      case 'arrow_left':
        return _arrowLeft();
      case 'arrow_right':
        return _arrowRight();
      case 'leaf':
        return _leaf();
      case 'flower':
        return _flower();
      case 'sun':
        return _sun();
      case 'moon':
        return _moon();
      case 'cloud':
        return _cloud();
      case 'raindrop':
        return _raindrop();
      case 'snowflake':
        return _snowflake();
      case 'tree':
        return _tree();
      case 'mountain':
        return _mountain();
      case 'sparkle':
        return _sparkle();
      case 'ribbon':
        return _ribbon();
      case 'banner':
        return _banner();
      case 'frame':
        return _frame();
      case 'bracket':
        return _bracket();
      case 'divider':
        return _divider();
      case 'corner_ornament':
        return _cornerOrnament();
      case 'checkmark':
        return _checkmark();
      default:
        return _circle();
    }
  }

  static Path _star() {
    final path = Path();
    const outerR = 48.0;
    const innerR = 20.0;
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  static Path _heart() {
    final path = Path();
    path.moveTo(0, 40);
    path.cubicTo(-50, 10, -50, -30, -20, -35);
    path.cubicTo(-10, -38, 0, -28, 0, -20);
    path.cubicTo(0, -28, 10, -38, 20, -35);
    path.cubicTo(50, -30, 50, 10, 0, 40);
    path.close();
    return path;
  }

  static Path _circle() =>
      Path()..addOval(const Rect.fromCircle(center: Offset.zero, radius: 48));

  static Path _square() =>
      Path()..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTRB(-44, -44, 44, 44), const Radius.circular(6)));

  static Path _triangle() {
    return Path()
      ..moveTo(0, -48)
      ..lineTo(44, 44)
      ..lineTo(-44, 44)
      ..close();
  }

  static Path _diamond() {
    return Path()
      ..moveTo(0, -48)
      ..lineTo(34, 0)
      ..lineTo(0, 48)
      ..lineTo(-34, 0)
      ..close();
  }

  static Path _cross() {
    const w = 16.0;
    const e = 44.0;
    return Path()
      ..moveTo(-w, -e)
      ..lineTo(w, -e)
      ..lineTo(w, -w)
      ..lineTo(e, -w)
      ..lineTo(e, w)
      ..lineTo(w, w)
      ..lineTo(w, e)
      ..lineTo(-w, e)
      ..lineTo(-w, w)
      ..lineTo(-e, w)
      ..lineTo(-e, -w)
      ..lineTo(-w, -w)
      ..close();
  }

  static Path _arrowUp() {
    return Path()
      ..moveTo(0, -48)
      ..lineTo(36, -4)
      ..lineTo(16, -4)
      ..lineTo(16, 48)
      ..lineTo(-16, 48)
      ..lineTo(-16, -4)
      ..lineTo(-36, -4)
      ..close();
  }

  static Path _arrowDown() {
    return Path()
      ..moveTo(0, 48)
      ..lineTo(36, 4)
      ..lineTo(16, 4)
      ..lineTo(16, -48)
      ..lineTo(-16, -48)
      ..lineTo(-16, 4)
      ..lineTo(-36, 4)
      ..close();
  }

  static Path _arrowLeft() {
    return Path()
      ..moveTo(-48, 0)
      ..lineTo(-4, -36)
      ..lineTo(-4, -16)
      ..lineTo(48, -16)
      ..lineTo(48, 16)
      ..lineTo(-4, 16)
      ..lineTo(-4, 36)
      ..close();
  }

  static Path _arrowRight() {
    return Path()
      ..moveTo(48, 0)
      ..lineTo(4, -36)
      ..lineTo(4, -16)
      ..lineTo(-48, -16)
      ..lineTo(-48, 16)
      ..lineTo(4, 16)
      ..lineTo(4, 36)
      ..close();
  }

  static Path _leaf() {
    final path = Path();
    path.moveTo(0, -48);
    path.cubicTo(30, -20, 44, 10, 20, 40);
    path.cubicTo(10, 50, -10, 50, -20, 40);
    path.cubicTo(-44, 10, -30, -20, 0, -48);
    path.close();
    // Midrib line
    path.moveTo(0, -48);
    path.lineTo(0, 48);
    return path;
  }

  static Path _flower() {
    final path = Path();
    const petalR = 28.0;
    const centerR = 16.0;
    const petals = 6;
    for (var i = 0; i < petals; i++) {
      final angle = i * (2 * math.pi / petals);
      final cx = petalR * math.cos(angle);
      final cy = petalR * math.sin(angle);
      path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: 18));
    }
    path.addOval(Rect.fromCircle(center: Offset.zero, radius: centerR));
    return path;
  }

  static Path _sun() {
    final path = Path();
    path.addOval(const Rect.fromCircle(center: Offset.zero, radius: 24));
    const rays = 8;
    for (var i = 0; i < rays; i++) {
      final angle = i * (2 * math.pi / rays);
      final x1 = 28 * math.cos(angle);
      final y1 = 28 * math.sin(angle);
      final x2 = 48 * math.cos(angle);
      final y2 = 48 * math.sin(angle);
      path.moveTo(x1, y1);
      path.lineTo(x2, y2);
    }
    return path;
  }

  static Path _moon() {
    final path = Path();
    path.addArc(const Rect.fromLTRB(-40, -48, 40, 48), -math.pi / 2, math.pi * 1.2);
    path.close();
    // Inner circle to create crescent
    path.addOval(const Rect.fromCircle(center: Offset(10, 0), radius: 36));
    return path;
  }

  static Path _cloud() {
    final path = Path();
    path.addOval(const Rect.fromCircle(center: Offset(-20, 10), radius: 22));
    path.addOval(const Rect.fromCircle(center: Offset(10, -5), radius: 28));
    path.addOval(const Rect.fromCircle(center: Offset(30, 10), radius: 20));
    path.addRect(const Rect.fromLTRB(-42, 10, 50, 38));
    return path;
  }

  static Path _raindrop() {
    final path = Path();
    path.moveTo(0, -48);
    path.cubicTo(30, -10, 36, 20, 20, 34);
    path.arcToPoint(const Offset(-20, 34),
        radius: const Radius.circular(20), clockwise: false);
    path.cubicTo(-36, 20, -30, -10, 0, -48);
    path.close();
    return path;
  }

  static Path _snowflake() {
    final path = Path();
    const arms = 6;
    for (var i = 0; i < arms; i++) {
      final angle = i * (math.pi / 3);
      path.moveTo(0, 0);
      path.lineTo(48 * math.cos(angle), 48 * math.sin(angle));
      // Small branches
      const bLen = 16.0;
      const bAngle = math.pi / 4;
      for (final sign in [-1.0, 1.0]) {
        final bx = 24 * math.cos(angle);
        final by = 24 * math.sin(angle);
        path.moveTo(bx, by);
        path.lineTo(bx + bLen * math.cos(angle + sign * bAngle),
            by + bLen * math.sin(angle + sign * bAngle));
      }
    }
    return path;
  }

  static Path _tree() {
    final path = Path();
    // Trunk
    path.addRect(const Rect.fromLTRB(-8, 20, 8, 48));
    // Three tiers of triangles
    path
      ..moveTo(0, -48)
      ..lineTo(28, -10)
      ..lineTo(-28, -10)
      ..close();
    path
      ..moveTo(0, -30)
      ..lineTo(36, 10)
      ..lineTo(-36, 10)
      ..close();
    path
      ..moveTo(0, -12)
      ..lineTo(44, 24)
      ..lineTo(-44, 24)
      ..close();
    return path;
  }

  static Path _mountain() {
    final path = Path();
    path
      ..moveTo(-48, 48)
      ..lineTo(0, -48)
      ..lineTo(48, 48)
      ..close();
    // Second peak (behind)
    path
      ..moveTo(-10, 48)
      ..lineTo(30, -20)
      ..lineTo(70, 48);
    return path;
  }

  static Path _sparkle() {
    final path = Path();
    const points = 4;
    const outerR = 48.0;
    const innerR = 10.0;
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  static Path _ribbon() {
    final path = Path();
    // Bow left loop
    path.moveTo(0, 0);
    path.cubicTo(-16, -16, -44, -20, -40, 0);
    path.cubicTo(-44, 20, -16, 16, 0, 0);
    // Bow right loop
    path.moveTo(0, 0);
    path.cubicTo(16, -16, 44, -20, 40, 0);
    path.cubicTo(44, 20, 16, 16, 0, 0);
    // Ribbon tails
    path.moveTo(-4, 4);
    path.lineTo(-28, 44);
    path.moveTo(4, 4);
    path.lineTo(28, 44);
    return path;
  }

  static Path _banner() {
    final path = Path();
    path.moveTo(-48, -24);
    path.lineTo(48, -24);
    path.lineTo(48, 16);
    path.lineTo(0, 36);
    path.lineTo(-48, 16);
    path.close();
    return path;
  }

  static Path _frame() {
    final path = Path();
    // Outer rect
    path.addRect(const Rect.fromLTRB(-48, -48, 48, 48));
    // Inner rect (hole)
    path.addRect(const Rect.fromLTRB(-36, -36, 36, 36));
    return path;
  }

  static Path _bracket() {
    final path = Path();
    // Left bracket
    path
      ..moveTo(-40, -48)
      ..lineTo(-24, -48)
      ..lineTo(-24, -40)
      ..lineTo(-32, -40)
      ..lineTo(-32, 40)
      ..lineTo(-24, 40)
      ..lineTo(-24, 48)
      ..lineTo(-40, 48)
      ..close();
    // Right bracket
    path
      ..moveTo(40, -48)
      ..lineTo(24, -48)
      ..lineTo(24, -40)
      ..lineTo(32, -40)
      ..lineTo(32, 40)
      ..lineTo(24, 40)
      ..lineTo(24, 48)
      ..lineTo(40, 48)
      ..close();
    return path;
  }

  static Path _divider() {
    final path = Path();
    // Horizontal line
    path.moveTo(-48, 0);
    path.lineTo(48, 0);
    // Diamond ornament at center
    path
      ..moveTo(0, -8)
      ..lineTo(8, 0)
      ..lineTo(0, 8)
      ..lineTo(-8, 0)
      ..close();
    // Small circles at ends
    path.addOval(const Rect.fromCircle(center: Offset(-44, 0), radius: 4));
    path.addOval(const Rect.fromCircle(center: Offset(44, 0), radius: 4));
    return path;
  }

  static Path _cornerOrnament() {
    final path = Path();
    // Corner lines
    path.moveTo(-48, -48);
    path.lineTo(0, -48);
    path.moveTo(-48, -48);
    path.lineTo(-48, 0);
    // Decorative flourish
    path.moveTo(-48, -48);
    path.cubicTo(-20, -48, -48, -20, -32, -32);
    path.addOval(const Rect.fromCircle(center: Offset(-32, -32), radius: 8));
    return path;
  }

  static Path _checkmark() {
    final path = Path();
    path.moveTo(-44, 0);
    path.lineTo(-16, 36);
    path.lineTo(44, -36);
    path.lineTo(36, -44);
    path.lineTo(-16, 22);
    path.lineTo(-36, -8);
    path.close();
    return path;
  }
}
