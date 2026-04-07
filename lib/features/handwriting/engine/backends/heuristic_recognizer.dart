import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/handwriting/data/character_templates.dart';
import 'package:y2notes2/features/handwriting/data/common_dictionary.dart';
import 'package:y2notes2/features/handwriting/domain/entities/recognition_result.dart';
import 'package:y2notes2/features/handwriting/engine/character_segmenter.dart';
import 'package:y2notes2/features/handwriting/engine/feature_extractor.dart';
import 'package:y2notes2/features/handwriting/engine/recognition_engine.dart';

/// Built-in, offline, heuristic stroke-based recognizer.
///
/// Works without any external dependencies. Uses template matching with
/// weighted Euclidean distance in feature space.
class HeuristicRecognizer implements RecognitionBackend {
  HeuristicRecognizer({
    this.maxCandidates = 5,
    this.minConfidence = 0.05,
  });

  final int maxCandidates;
  final double minConfidence;

  final _segmenter = const CharacterSegmenter();
  final _extractor = const FeatureExtractor();

  @override
  String get id => 'heuristic';

  @override
  String get name => 'Built-in Recognizer';

  @override
  bool get isAvailable => true;

  @override
  Future<bool> supportsLanguage(String languageCode) async =>
      languageCode.startsWith('en');

  @override
  Future<void> downloadModel(String languageCode) async {
    // Built-in — nothing to download.
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<RecognitionResult> recognize(
    List<RecognitionStroke> strokes, {
    String? languageHint,
    RecognitionContext? context,
  }) async {
    final sw = Stopwatch()..start();

    if (strokes.isEmpty) {
      return RecognitionResult(
        candidates: const [],
        processingTimeMs: 0,
        backendUsed: id,
      );
    }

    // 1. Segment strokes into words
    final wordGroups = _segmenter.segmentIntoWords(strokes);

    // 2. Recognize each word
    final wordStrings = wordGroups.map((wordGroup) {
      final chars = wordGroup.map((charGroup) {
        return _recognizeCharacter(charGroup);
      }).toList();
      return chars.join();
    }).toList();

    // 3. Assemble raw text
    final rawText = wordStrings.join(' ').trim();

    // 4. Post-processing
    final correctedWords = rawText.split(' ').map((w) {
      // Skip short words and numbers
      if (w.length <= 2 || _isNumber(w)) return w;
      final corrected = CommonDictionary.correct(w, maxDistance: 1);
      return corrected ?? w;
    }).toList();

    // Apply contextual capitalization
    final text = _applyCapitalization(correctedWords, context?.previousText);

    // 5. Compute overall confidence
    final confidence = _computeConfidence(wordGroups, strokes);

    // 6. Build candidates
    final candidates = <RecognitionCandidate>[];
    if (text.isNotEmpty) {
      candidates.add(RecognitionCandidate(
        text: text,
        confidence: confidence,
        boundingBox: _allBounds(strokes),
      ));

      // Add slight variants as additional candidates
      if (candidates.first.confidence < (1.0 - minConfidence)) {
        final alt = _alternativeText(text);
        if (alt != text) {
          candidates.add(RecognitionCandidate(
            text: alt,
            confidence: (confidence * 0.7).clamp(0.0, 1.0),
            boundingBox: _allBounds(strokes),
          ));
        }
      }
    }

    sw.stop();
    return RecognitionResult(
      candidates: candidates.take(maxCandidates).toList(),
      processingTimeMs: sw.elapsedMicroseconds / 1000.0,
      backendUsed: id,
    );
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  String _recognizeCharacter(List<RecognitionStroke> strokes) {
    if (strokes.isEmpty) return '';

    final features = _extractor.extract(strokes);
    final fv = features.toVector();

    String bestChar = '?';
    var bestDist = double.infinity;

    for (final entry in CharacterTemplates.all.entries) {
      final template = entry.value;
      if (template.length != fv.length) continue;
      final dist = _euclideanDistance(fv, template);
      if (dist < bestDist) {
        bestDist = dist;
        bestChar = entry.key;
      }
    }

    // Confidence gate: if distance is too high, return placeholder
    if (bestDist > 3.5) return '?';
    return bestChar;
  }

  double _euclideanDistance(List<double> a, List<double> b) {
    var sum = 0.0;
    // Weights: direction histogram gets higher weight
    const weights = [
      2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, // direction (8)
      1.5, 1.0, 1.5, 1.0, 1.0, 0.8, 0.5, 0.5,  // structural (7)
    ];
    for (var i = 0; i < a.length && i < b.length; i++) {
      final w = i < weights.length ? weights[i] : 1.0;
      sum += w * math.pow(a[i] - b[i], 2);
    }
    return math.sqrt(sum);
  }

  double _computeConfidence(
    List<List<List<RecognitionStroke>>> wordGroups,
    List<RecognitionStroke> all,
  ) {
    // More strokes = more data = better confidence, up to a point.
    // wordGroups count also influences confidence.
    final strokeCount = all.length;
    final wordCount = wordGroups.length;
    final base = ((strokeCount + wordCount) / 12.0).clamp(0.1, 0.7);
    return base;
  }

  bool _isNumber(String s) => double.tryParse(s) != null;

  String _applyCapitalization(List<String> words, String? previousText) {
    if (words.isEmpty) return '';

    final result = List<String>.from(words);

    // Capitalize first word if beginning of sentence
    final shouldCapFirst = previousText == null ||
        previousText.isEmpty ||
        previousText.trimRight().endsWith('.');

    if (shouldCapFirst && result.isNotEmpty && result.first.isNotEmpty) {
      result[0] = result.first[0].toUpperCase() + result.first.substring(1);
    }

    // Capitalize after periods
    for (var i = 1; i < result.length; i++) {
      if (result[i - 1].endsWith('.') && result[i].isNotEmpty) {
        result[i] = result[i][0].toUpperCase() + result[i].substring(1);
      }
    }

    return result.join(' ');
  }

  String _alternativeText(String original) {
    // Simple alternatives: toggle case of first letter
    if (original.isEmpty) return original;
    final first = original[0];
    final toggled = first == first.toUpperCase()
        ? first.toLowerCase()
        : first.toUpperCase();
    return toggled + original.substring(1);
  }

  Rect _allBounds(List<RecognitionStroke> strokes) {
    if (strokes.isEmpty) return Rect.zero;
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final s in strokes) {
      for (final p in s.points) {
        if (p.x < minX) minX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
