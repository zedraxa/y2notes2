import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/entities/point_data.dart';
import '../domain/entities/shape_element.dart';
import '../domain/entities/shape_type.dart';

/// Result from the shape recognizer.
class ShapeRecognitionResult {
  const ShapeRecognitionResult({
    required this.type,
    required this.confidence,
    required this.bounds,
    required this.vertices,
  });

  final ShapeType type;

  /// Confidence score 0.0–1.0. Auto-conversion occurs when > 0.75.
  final double confidence;

  /// Axis-aligned bounding box.
  final Rect bounds;

  /// Pre-computed polygon vertices (for types that need them).
  final List<Offset> vertices;
}

/// Analyses a completed freehand stroke and attempts to recognise a geometric
/// shape using least-squares-inspired metric fitting.
class ShapeRecognizer {
  /// Confidence threshold above which auto-conversion should be offered.
  static const double autoConvertThreshold = 0.75;

  /// Attempt to recognise a shape in [points].
  ///
  /// Returns `null` if fewer than 3 points are available.
  static ShapeRecognitionResult? recognize(List<PointData> points) {
    if (points.length < 3) return null;

    final offsets = points.map((p) => Offset(p.x, p.y)).toList();
    final bounds = _computeBounds(offsets);

    if (bounds.width < 4 && bounds.height < 4) return null;

    final normalised = _normalise(offsets, bounds);
    final perimeter = _arcLength(offsets);
    final area = _shoelaceArea(offsets).abs();
    final closureRatio = _closureRatio(offsets, perimeter);
    final aspectRatio =
        bounds.height > 0 ? bounds.width / bounds.height : 1.0;
    final circularity =
        area > 0 ? (4 * math.pi * area) / (perimeter * perimeter) : 0.0;
    final cornerAngles = _extractCornerAngles(normalised);

    // ── Try each shape and take the best match ──────────────────────────────
    final candidates = <_Candidate>[];

    candidates.add(_scoreLine(offsets, bounds, closureRatio));
    candidates.add(_scoreCircle(circularity, closureRatio));
    candidates.add(_scoreEllipse(circularity, closureRatio, aspectRatio));
    candidates.add(_scoreRectangle(cornerAngles, closureRatio, aspectRatio));
    candidates.add(_scoreSquare(cornerAngles, closureRatio, aspectRatio));
    candidates.add(_scoreTriangle(cornerAngles, closureRatio));
    candidates.add(_scoreDiamond(cornerAngles, closureRatio, aspectRatio));
    candidates.add(_scoreStar(normalised, closureRatio));
    candidates.add(_scorePentagon(cornerAngles, closureRatio));
    candidates.add(_scoreHexagon(cornerAngles, closureRatio));
    candidates.add(_scoreArrow(offsets, bounds));

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first;

    if (best.score < 0.40) return null; // not confident enough to propose

    final shapeVertices = _buildVertices(best.type, bounds);

    return ShapeRecognitionResult(
      type: best.type,
      confidence: best.score.clamp(0.0, 1.0),
      bounds: bounds,
      vertices: shapeVertices,
    );
  }

  // ─── Scorers ──────────────────────────────────────────────────────────────

  static _Candidate _scoreCircle(double circularity, double closureRatio) {
    // A perfect circle: circularity ≈ 1.0, stroke closes on itself.
    final score = circularity * 0.7 + closureRatio * 0.3;
    return _Candidate(ShapeType.circle, score);
  }

  static _Candidate _scoreEllipse(
      double circularity, double closureRatio, double aspectRatio) {
    if (aspectRatio < 1.0) aspectRatio = 1.0 / aspectRatio;
    // Ellipse: circularity somewhat lower, aspect ratio ≠ 1.
    final ellipticness = (aspectRatio - 1.0).clamp(0.0, 3.0) / 3.0;
    final score = (circularity * 0.6 + closureRatio * 0.3) *
        (0.4 + ellipticness * 0.6);
    return _Candidate(ShapeType.ellipse, score);
  }

  static _Candidate _scoreRectangle(List<double> corners, double closureRatio,
      double aspectRatio) {
    if (corners.length < 4) return _Candidate(ShapeType.rectangle, 0.0);
    final fourCorners = corners.take(4).toList()..sort();
    final meanAngle =
        fourCorners.fold(0.0, (s, a) => s + a) / fourCorners.length;
    final deviation = fourCorners
            .map((a) => (a - meanAngle).abs())
            .fold(0.0, (s, d) => s + d) /
        fourCorners.length;
    // Perfect rectangle: all corners near 90°, aspect ratio ≠ 1.
    final cornerScore = (1.0 - (meanAngle - 90.0).abs() / 90.0).clamp(0.0, 1.0);
    final deviationPenalty = (1.0 - deviation / 30.0).clamp(0.0, 1.0);
    final aspectPenalty = aspectRatio > 1.8 || aspectRatio < 0.55 ? 0.8 : 1.0;
    final score =
        cornerScore * deviationPenalty * aspectPenalty * 0.8 + closureRatio * 0.2;
    return _Candidate(ShapeType.rectangle, score);
  }

  static _Candidate _scoreSquare(List<double> corners, double closureRatio,
      double aspectRatio) {
    if (corners.length < 4) return _Candidate(ShapeType.square, 0.0);
    final rectCandidate = _scoreRectangle(corners, closureRatio, aspectRatio);
    // Extra reward when aspect ratio is near 1.
    final squareness = 1.0 - (aspectRatio - 1.0).abs().clamp(0.0, 1.0);
    return _Candidate(ShapeType.square, rectCandidate.score * squareness);
  }

  static _Candidate _scoreTriangle(
      List<double> corners, double closureRatio) {
    if (corners.length < 3) return _Candidate(ShapeType.triangle, 0.0);
    final threeCorners = corners.take(3).toList()..sort();
    final angleSum = threeCorners.fold(0.0, (s, a) => s + a);
    final sumScore = (1.0 - (angleSum - 180.0).abs() / 180.0).clamp(0.0, 1.0);
    final score = sumScore * 0.7 + closureRatio * 0.3;
    return _Candidate(ShapeType.triangle, score);
  }

  static _Candidate _scoreDiamond(List<double> corners, double closureRatio,
      double aspectRatio) {
    if (corners.length < 4) return _Candidate(ShapeType.diamond, 0.0);
    final rect = _scoreRectangle(corners, closureRatio, aspectRatio);
    // Diamond is rotated square; penalise non-square aspect ratios less.
    final squareness = 1.0 - (aspectRatio - 1.0).abs().clamp(0.0, 1.5) / 1.5;
    return _Candidate(ShapeType.diamond, rect.score * (0.5 + squareness * 0.5));
  }

  static _Candidate _scoreStar(
      List<Offset> normalised, double closureRatio) {
    // Count radial extrema (peaks and valleys in radius from centroid).
    final centroid = _centroid(normalised);
    final radii =
        normalised.map((p) => (p - centroid).distance).toList();
    int peaks = 0;
    for (int i = 1; i < radii.length - 1; i++) {
      if (radii[i] > radii[i - 1] && radii[i] > radii[i + 1]) peaks++;
    }
    // A 5-point star has ~10 extrema (5 peaks, 5 valleys).
    final peakScore = (1.0 - (peaks - 10).abs() / 10.0).clamp(0.0, 1.0);
    return _Candidate(
        ShapeType.star, peakScore * 0.6 + closureRatio * 0.4);
  }

  static _Candidate _scorePentagon(
      List<double> corners, double closureRatio) {
    if (corners.length < 5) return _Candidate(ShapeType.pentagon, 0.0);
    final fiveCorners = corners.take(5).toList()..sort();
    final expected = 108.0;
    final meanAngle =
        fiveCorners.fold(0.0, (s, a) => s + a) / fiveCorners.length;
    final score =
        (1.0 - (meanAngle - expected).abs() / 90.0).clamp(0.0, 1.0) * 0.7 +
            closureRatio * 0.3;
    return _Candidate(ShapeType.pentagon, score);
  }

  static _Candidate _scoreHexagon(
      List<double> corners, double closureRatio) {
    if (corners.length < 6) return _Candidate(ShapeType.hexagon, 0.0);
    final sixCorners = corners.take(6).toList()..sort();
    final expected = 120.0;
    final meanAngle =
        sixCorners.fold(0.0, (s, a) => s + a) / sixCorners.length;
    final score =
        (1.0 - (meanAngle - expected).abs() / 90.0).clamp(0.0, 1.0) * 0.7 +
            closureRatio * 0.3;
    return _Candidate(ShapeType.hexagon, score);
  }

  static _Candidate _scoreArrow(List<Offset> offsets, Rect bounds) {
    // An arrow is roughly a line that ends in a wider V shape.
    if (offsets.length < 6) return _Candidate(ShapeType.arrow, 0.0);
    final half = offsets.length ~/ 2;
    final firstHalf = offsets.sublist(0, half);
    final secondHalf = offsets.sublist(half);
    final firstSpread = _spread(firstHalf);
    final secondSpread = _spread(secondHalf);
    // Arrowhead is wider spread at the end.
    final arrowScore = firstSpread > 0
        ? (secondSpread / firstSpread).clamp(0.0, 3.0) / 3.0
        : 0.0;
    return _Candidate(ShapeType.arrow, arrowScore * 0.7);
  }

  static _Candidate _scoreLine(
      List<Offset> offsets, Rect bounds, double closureRatio) {
    // A line: very low closure, small cross-axis spread.
    final diag = math.sqrt(
        bounds.width * bounds.width + bounds.height * bounds.height);
    if (diag == 0) return _Candidate(ShapeType.line, 0.0);
    final linearityScore =
        (1.0 - closureRatio) * (1.0 - _lateralSpread(offsets) / diag);
    return _Candidate(
        ShapeType.line, linearityScore.clamp(0.0, 1.0));
  }

  // ─── Geometry helpers ─────────────────────────────────────────────────────

  static Rect _computeBounds(List<Offset> pts) {
    double minX = pts[0].dx,
        maxX = pts[0].dx,
        minY = pts[0].dy,
        maxY = pts[0].dy;
    for (final p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static List<Offset> _normalise(List<Offset> pts, Rect bounds) {
    final w = bounds.width == 0 ? 1.0 : bounds.width;
    final h = bounds.height == 0 ? 1.0 : bounds.height;
    return pts
        .map((p) => Offset(
              (p.dx - bounds.left) / w,
              (p.dy - bounds.top) / h,
            ))
        .toList();
  }

  static double _arcLength(List<Offset> pts) {
    double len = 0.0;
    for (int i = 1; i < pts.length; i++) {
      len += (pts[i] - pts[i - 1]).distance;
    }
    return len;
  }

  static double _shoelaceArea(List<Offset> pts) {
    double area = 0.0;
    final n = pts.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += pts[i].dx * pts[j].dy;
      area -= pts[j].dx * pts[i].dy;
    }
    return area / 2.0;
  }

  static double _closureRatio(List<Offset> pts, double perimeter) {
    if (perimeter == 0) return 0.0;
    final gap = (pts.first - pts.last).distance;
    return (1.0 - gap / perimeter).clamp(0.0, 1.0);
  }

  /// Extract interior angles at significant corners (direction changes > 20°).
  static List<double> _extractCornerAngles(List<Offset> pts) {
    if (pts.length < 3) return [];
    final angles = <double>[];
    const step = 3;
    for (int i = step; i < pts.length - step; i++) {
      final v1 = pts[i] - pts[i - step];
      final v2 = pts[i + step] - pts[i];
      if (v1.distance < 1e-6 || v2.distance < 1e-6) continue;
      final dot = v1.dx * v2.dx + v1.dy * v2.dy;
      final cross = v1.dx * v2.dy - v1.dy * v2.dx;
      final angle = math.atan2(cross.abs(), dot) * 180 / math.pi;
      if (angle > 20) angles.add(angle);
    }
    return angles;
  }

  static Offset _centroid(List<Offset> pts) {
    var cx = 0.0, cy = 0.0;
    for (final p in pts) {
      cx += p.dx;
      cy += p.dy;
    }
    return Offset(cx / pts.length, cy / pts.length);
  }

  static double _spread(List<Offset> pts) {
    if (pts.isEmpty) return 0.0;
    final c = _centroid(pts);
    return pts.map((p) => (p - c).distance).fold(0.0, math.max);
  }

  static double _lateralSpread(List<Offset> pts) {
    if (pts.length < 2) return 0.0;
    final axis = pts.last - pts.first;
    if (axis.distance < 1e-6) return 0.0;
    final axisNorm = axis / axis.distance;
    final perp = Offset(-axisNorm.dy, axisNorm.dx);
    double maxDist = 0.0;
    for (final p in pts) {
      final v = p - pts.first;
      final d = (v.dx * perp.dx + v.dy * perp.dy).abs();
      if (d > maxDist) maxDist = d;
    }
    return maxDist;
  }

  // ─── Build canonical vertices ─────────────────────────────────────────────

  /// Build canonical polygon vertices in canvas coordinates for [type].
  static List<Offset> _buildVertices(ShapeType type, Rect bounds) {
    final cx = bounds.center.dx;
    final cy = bounds.center.dy;
    final rx = bounds.width / 2;
    final ry = bounds.height / 2;

    switch (type) {
      case ShapeType.triangle:
        return [
          Offset(cx, bounds.top),
          Offset(bounds.right, bounds.bottom),
          Offset(bounds.left, bounds.bottom),
        ];
      case ShapeType.diamond:
        return [
          Offset(cx, bounds.top),
          Offset(bounds.right, cy),
          Offset(cx, bounds.bottom),
          Offset(bounds.left, cy),
        ];
      case ShapeType.star:
        return _starVertices(cx, cy, rx, ry, 5);
      case ShapeType.pentagon:
        return _regularPolygonVertices(cx, cy, rx, ry, 5, -math.pi / 2);
      case ShapeType.hexagon:
        return _regularPolygonVertices(cx, cy, rx, ry, 6, 0);
      default:
        return [];
    }
  }

  static List<Offset> _regularPolygonVertices(
      double cx, double cy, double rx, double ry, int n, double startAngle) {
    return List.generate(n, (i) {
      final angle = startAngle + 2 * math.pi * i / n;
      return Offset(cx + rx * math.cos(angle), cy + ry * math.sin(angle));
    });
  }

  static List<Offset> _starVertices(
      double cx, double cy, double rx, double ry, int points) {
    final innerRx = rx * 0.4;
    final innerRy = ry * 0.4;
    final verts = <Offset>[];
    for (int i = 0; i < points * 2; i++) {
      final angle = -math.pi / 2 + math.pi * i / points;
      if (i.isEven) {
        verts.add(Offset(cx + rx * math.cos(angle), cy + ry * math.sin(angle)));
      } else {
        verts.add(
            Offset(cx + innerRx * math.cos(angle), cy + innerRy * math.sin(angle)));
      }
    }
    return verts;
  }

  /// Convenience: build a [ShapeElement] from a recognised result.
  static ShapeElement toShapeElement(
    ShapeRecognitionResult result, {
    Color strokeColor = const Color(0xFF2D2D2D),
    Color fillColor = Colors.transparent,
    double strokeWidth = 2.0,
  }) {
    return ShapeElement.create(
      type: result.type,
      bounds: result.bounds,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      vertices: result.vertices,
    );
  }
}

class _Candidate {
  const _Candidate(this.type, this.score);
  final ShapeType type;
  final double score;
}
