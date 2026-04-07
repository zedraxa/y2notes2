import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuitse/features/handwriting/domain/entities/recognition_result.dart';

/// Character / word segmentation from a list of strokes.
///
/// Uses spatial proximity and temporal gaps to group strokes into characters
/// and characters into words.
class CharacterSegmenter {
  const CharacterSegmenter({
    this.temporalGapMs = 300,
    this.spatialGapFactor = 0.8,
  });

  /// Pause longer than this (ms) = new character boundary.
  final int temporalGapMs;

  /// Gap wider than [spatialGapFactor] × avg-char-width = word boundary.
  final double spatialGapFactor;

  /// Segment [strokes] into groups, each group representing one character.
  List<List<RecognitionStroke>> segmentIntoCharacters(
      List<RecognitionStroke> strokes) {
    if (strokes.isEmpty) return [];

    final groups = <List<RecognitionStroke>>[];
    var current = <RecognitionStroke>[strokes.first];

    for (var i = 1; i < strokes.length; i++) {
      final prev = strokes[i - 1];
      final curr = strokes[i];

      final temporalGap = _temporalGap(prev, curr);
      final spatialGap = _spatialGap(prev, curr);

      // Short pause or nearby = same character
      if (temporalGap < temporalGapMs && spatialGap < _avgCharWidth(current) * 1.5) {
        current.add(curr);
      } else {
        groups.add(List.unmodifiable(current));
        current = [curr];
      }
    }
    if (current.isNotEmpty) groups.add(List.unmodifiable(current));
    return groups;
  }

  /// Segment into words (groups of character groups separated by larger gaps).
  List<List<List<RecognitionStroke>>> segmentIntoWords(
      List<RecognitionStroke> strokes) {
    final chars = segmentIntoCharacters(strokes);
    if (chars.isEmpty) return [];

    final words = <List<List<RecognitionStroke>>>[];
    var currentWord = <List<RecognitionStroke>>[chars.first];

    for (var i = 1; i < chars.length; i++) {
      final prevBounds = _bounds(chars[i - 1]);
      final currBounds = _bounds(chars[i]);
      final gap = currBounds.left - prevBounds.right;
      final avgCharW = _avgCharWidthFromGroups(currentWord);

      if (gap > avgCharW * spatialGapFactor) {
        words.add(List.unmodifiable(currentWord));
        currentWord = [chars[i]];
      } else {
        currentWord.add(chars[i]);
      }
    }
    if (currentWord.isNotEmpty) words.add(List.unmodifiable(currentWord));
    return words;
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  int _temporalGap(RecognitionStroke a, RecognitionStroke b) {
    final aEnd = a.points.isEmpty ? 0 : a.points.last.timestampMs;
    final bStart = b.points.isEmpty ? 0 : b.points.first.timestampMs;
    return (bStart - aEnd).abs();
  }

  double _spatialGap(RecognitionStroke a, RecognitionStroke b) {
    final aBounds = _strokeBounds(a);
    final bBounds = _strokeBounds(b);
    return math.max(0, bBounds.left - aBounds.right);
  }

  double _avgCharWidth(List<RecognitionStroke> group) {
    if (group.isEmpty) return 20.0;
    final b = _bounds(group);
    return math.max(b.width, 10.0);
  }

  double _avgCharWidthFromGroups(List<List<RecognitionStroke>> groups) {
    if (groups.isEmpty) return 20.0;
    final widths = groups.map((g) => _avgCharWidth(g)).toList();
    return widths.reduce((a, b) => a + b) / widths.length;
  }

  Rect _bounds(List<RecognitionStroke> strokes) {
    if (strokes.isEmpty) return Rect.zero;
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final s in strokes) {
      final b = _strokeBounds(s);
      minX = math.min(minX, b.left);
      minY = math.min(minY, b.top);
      maxX = math.max(maxX, b.right);
      maxY = math.max(maxY, b.bottom);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Rect _strokeBounds(RecognitionStroke s) {
    if (s.points.isEmpty) return Rect.zero;
    double minX = s.points.first.x, minY = s.points.first.y;
    double maxX = minX, maxY = minY;
    for (final p in s.points) {
      minX = math.min(minX, p.x);
      minY = math.min(minY, p.y);
      maxX = math.max(maxX, p.x);
      maxY = math.max(maxY, p.y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
