import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/handwriting/domain/entities/recognition_result.dart';

/// Feature vector for one character (8 direction bins + structural features).
class CharacterFeatures {
  const CharacterFeatures({
    required this.directionHistogram,
    required this.aspectRatio,
    required this.strokeCount,
    required this.loopCount,
    required this.startEndDist,
    required this.lengthRatio,
    required this.curvatureVariance,
    required this.startQuadrant,
    required this.endQuadrant,
  });

  /// 8-direction histogram (N, NE, E, SE, S, SW, W, NW), normalized.
  final List<double> directionHistogram;
  final double aspectRatio; // width / height
  final int strokeCount;
  final int loopCount;
  final double startEndDist; // normalized by diagonal
  final double lengthRatio; // total_length / diagonal
  final double curvatureVariance;
  final int startQuadrant; // 0–3 (top-left, top-right, bottom-right, bottom-left)
  final int endQuadrant;

  /// Flatten to a list of doubles for distance computation.
  List<double> toVector() => [
        ...directionHistogram,
        aspectRatio,
        strokeCount.toDouble() / 5.0,
        loopCount.toDouble() / 3.0,
        startEndDist,
        lengthRatio,
        curvatureVariance,
        startQuadrant.toDouble() / 3.0,
        endQuadrant.toDouble() / 3.0,
      ];

  static const int vectorLength = 8 + 7; // 15 features
}

/// Extracts [CharacterFeatures] from a group of strokes (one character).
class FeatureExtractor {
  const FeatureExtractor();

  CharacterFeatures extract(List<RecognitionStroke> strokes) {
    if (strokes.isEmpty) {
      return const CharacterFeatures(
        directionHistogram: [0, 0, 0, 0, 0, 0, 0, 0],
        aspectRatio: 1.0,
        strokeCount: 0,
        loopCount: 0,
        startEndDist: 0.0,
        lengthRatio: 0.0,
        curvatureVariance: 0.0,
        startQuadrant: 0,
        endQuadrant: 0,
      );
    }

    final allPoints = strokes.expand((s) => s.points).toList();
    final bounds = _computeBounds(allPoints);
    final diagonal = math.sqrt(
      bounds.width * bounds.width + bounds.height * bounds.height,
    );

    final histogram = _directionHistogram(allPoints);
    final totalLength = _totalLength(allPoints);
    final loops = _estimateLoops(strokes);
    final curvVar = _curvatureVariance(allPoints);

    final firstPt = strokes.first.points.isNotEmpty
        ? strokes.first.points.first
        : const RecognitionPoint(x: 0, y: 0);
    final lastPt = strokes.last.points.isNotEmpty
        ? strokes.last.points.last
        : const RecognitionPoint(x: 0, y: 0);

    final startEndDist = diagonal > 0
        ? math.sqrt(
            math.pow(lastPt.x - firstPt.x, 2) +
                math.pow(lastPt.y - firstPt.y, 2),
          ) /
            diagonal
        : 0.0;

    return CharacterFeatures(
      directionHistogram: histogram,
      aspectRatio: bounds.height > 0 ? bounds.width / bounds.height : 1.0,
      strokeCount: strokes.length,
      loopCount: loops,
      startEndDist: startEndDist.clamp(0.0, 1.0),
      lengthRatio: diagonal > 0 ? (totalLength / diagonal).clamp(0.0, 5.0) / 5.0 : 0.0,
      curvatureVariance: curvVar.clamp(0.0, 1.0),
      startQuadrant: _quadrant(firstPt, bounds),
      endQuadrant: _quadrant(lastPt, bounds),
    );
  }

  List<double> _directionHistogram(List<RecognitionPoint> points) {
    final bins = List<double>.filled(8, 0.0);
    var total = 0.0;

    for (var i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len < 0.5) continue;

      // atan2 gives angle in radians, convert to 0–2π
      var angle = math.atan2(dy, dx);
      if (angle < 0) angle += 2 * math.pi;

      // Map to 8 bins (each 45°)
      final bin = (angle / (math.pi / 4)).floor() % 8;
      bins[bin] += len;
      total += len;
    }

    if (total > 0) {
      for (var i = 0; i < 8; i++) {
        bins[i] /= total;
      }
    }
    return bins;
  }

  double _totalLength(List<RecognitionPoint> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      total += math.sqrt(dx * dx + dy * dy);
    }
    return total;
  }

  Rect _computeBounds(List<RecognitionPoint> points) {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.x, minY = points.first.y;
    double maxX = minX, maxY = minY;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  int _estimateLoops(List<RecognitionStroke> strokes) {
    // Count strokes with a near-closed shape (start ≈ end).
    var loops = 0;
    for (final s in strokes) {
      if (s.points.length < 4) continue;
      final first = s.points.first;
      final last = s.points.last;
      final dist = math.sqrt(
        math.pow(last.x - first.x, 2) + math.pow(last.y - first.y, 2),
      );
      final len = _totalLength(s.points);
      if (len > 0 && dist / len < 0.25) loops++;
    }
    return loops;
  }

  double _curvatureVariance(List<RecognitionPoint> points) {
    if (points.length < 3) return 0.0;
    final curvatures = <double>[];
    for (var i = 1; i < points.length - 1; i++) {
      final dx1 = points[i].x - points[i - 1].x;
      final dy1 = points[i].y - points[i - 1].y;
      final dx2 = points[i + 1].x - points[i].x;
      final dy2 = points[i + 1].y - points[i].y;
      final cross = (dx1 * dy2 - dy1 * dx2).abs();
      final denom = math.sqrt(dx1 * dx1 + dy1 * dy1) *
          math.sqrt(dx2 * dx2 + dy2 * dy2);
      curvatures.add(denom > 0 ? cross / denom : 0.0);
    }
    if (curvatures.isEmpty) return 0.0;
    final mean = curvatures.reduce((a, b) => a + b) / curvatures.length;
    final variance =
        curvatures.map((c) => math.pow(c - mean, 2)).reduce((a, b) => a + b) /
            curvatures.length;
    return math.sqrt(variance);
  }

  int _quadrant(RecognitionPoint p, Rect bounds) {
    if (bounds.width == 0 || bounds.height == 0) return 0;
    final nx = (p.x - bounds.left) / bounds.width;
    final ny = (p.y - bounds.top) / bounds.height;
    if (ny < 0.5) {
      return nx < 0.5 ? 0 : 1;
    } else {
      return nx < 0.5 ? 3 : 2;
    }
  }
}
