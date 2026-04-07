import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class RecognitionPoint extends Equatable {
  const RecognitionPoint({
    required this.x,
    required this.y,
    this.pressure = 0.5,
    this.timestampMs = 0,
  });
  final double x;
  final double y;
  final double pressure;
  final int timestampMs;
  @override
  List<Object?> get props => [x, y, pressure, timestampMs];
}

class RecognitionStroke extends Equatable {
  const RecognitionStroke({required this.points, required this.strokeId});
  final List<RecognitionPoint> points;
  final int strokeId;
  @override
  List<Object?> get props => [strokeId, points];
}

class RecognitionContext {
  const RecognitionContext({this.previousText, this.expectedFormat, this.dictionary});
  final String? previousText;
  final String? expectedFormat; // 'text', 'number', 'email', 'url', 'math'
  final List<String>? dictionary;
}

class TextSegment extends Equatable {
  const TextSegment({
    required this.text,
    required this.bounds,
    required this.confidence,
    this.alternatives = const [],
  });
  final String text;
  final Rect bounds;
  final double confidence;
  final List<String> alternatives;
  @override
  List<Object?> get props => [text, bounds, confidence];
}

class RecognitionCandidate extends Equatable {
  const RecognitionCandidate({
    required this.text,
    required this.confidence,
    this.segments = const [],
    this.boundingBox = Rect.zero,
  });
  final String text;
  final double confidence; // 0.0–1.0
  final List<TextSegment> segments;
  final Rect boundingBox;
  @override
  List<Object?> get props => [text, confidence];
}

class RecognitionResult extends Equatable {
  const RecognitionResult({
    required this.candidates,
    required this.processingTimeMs,
    required this.backendUsed,
  });
  final List<RecognitionCandidate> candidates;
  final double processingTimeMs;
  final String backendUsed;

  static const empty = RecognitionResult(candidates: [], processingTimeMs: 0, backendUsed: 'none');

  RecognitionCandidate? get best => candidates.isEmpty ? null : candidates.first;
  bool get isEmpty => candidates.isEmpty;

  @override
  List<Object?> get props => [candidates, processingTimeMs, backendUsed];
}
