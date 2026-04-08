import 'dart:async';
import 'package:flutter/material.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/handwriting/domain/entities/recognition_result.dart';
import 'package:biscuits/features/handwriting/domain/entities/text_block.dart';
import 'package:biscuits/features/handwriting/domain/models/language_model.dart';
import 'package:biscuits/features/handwriting/domain/models/recognition_options.dart';
import 'package:biscuits/features/handwriting/engine/recognition_engine.dart';

/// Converts app [Stroke]s to recognition strokes.
List<RecognitionStroke> strokesToRecognition(List<Stroke> strokes) {
  return strokes.asMap().entries.map((e) {
    final s = e.value;
    return RecognitionStroke(
      strokeId: e.key,
      points: s.points.map((p) => RecognitionPoint(
        x: p.x,
        y: p.y,
        pressure: p.pressure,
        timestampMs: p.timestamp,
      )).toList(),
    );
  }).toList();
}

/// Orchestrates the recognition pipeline.
class RecognitionManager {
  RecognitionManager({
    required RecognitionBackend primaryBackend,
    RecognitionBackend? fallbackBackend,
    RecognitionOptions options = const RecognitionOptions(),
  })  : _primary = primaryBackend,
        _fallback = fallbackBackend,
        _options = options;

  final RecognitionBackend _primary;
  final RecognitionBackend? _fallback;
  RecognitionOptions _options;

  RecognitionMode _mode = RecognitionMode.manual;
  RecognitionMode get mode => _mode;
  set mode(RecognitionMode m) => _mode = m;

  String _activeLanguage = 'en-US';
  String get activeLanguage => _activeLanguage;

  double autoRecognitionDelay = 0.5;
  double minimumConfidence = 0.2;
  bool continuousMode = false;

  // Real-time stream
  final _resultController = StreamController<RecognitionResult>.broadcast();
  Stream<RecognitionResult> get realTimeResults => _resultController.stream;

  Timer? _debounceTimer;
  List<Stroke> _pendingStrokes = [];

  RecognitionOptions get options => _options;

  void updateOptions(RecognitionOptions opts) {
    _options = opts;
  }

  /// Called as user writes strokes (real-time mode).
  void onStrokesChanged(List<Stroke> strokes) {
    if (_mode != RecognitionMode.realTime) return;
    _pendingStrokes = strokes;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: (autoRecognitionDelay * 1000).round()),
      _runRealTime,
    );
  }

  Future<void> _runRealTime() async {
    if (_pendingStrokes.isEmpty) return;
    final result = await recognizeStrokes(_pendingStrokes);
    if (!_resultController.isClosed &&
        result.best != null &&
        (result.best!.confidence >= minimumConfidence)) {
      _resultController.add(result);
    }
  }

  /// Manual recognition of selected strokes.
  Future<RecognitionResult> recognizeStrokes(List<Stroke> strokes) async {
    final rs = strokesToRecognition(strokes);
    const ctx = RecognitionContext();
    try {
      if (_primary.isAvailable) {
        return await _primary.recognize(rs, languageHint: _activeLanguage, context: ctx);
      }
    } on Exception {
      // Primary backend failed; fall through to fallback.
    }

    if (_fallback != null) {
      return await _fallback!.recognize(rs, languageHint: _activeLanguage, context: ctx);
    }
    return RecognitionResult.empty;
  }

  /// Recognize all strokes on a page.
  Future<RecognitionResult> recognizePage(List<Stroke> allStrokes) =>
      recognizeStrokes(allStrokes);

  /// Convert a recognition result into a TextBlock positioned at [position].
  TextBlock convertToTextBlock(
    RecognitionResult result, {
    required Offset position,
    List<String> originalStrokeIds = const [],
  }) {
    return TextBlock(
      text: result.best?.text ?? '',
      position: position,
      originalStrokeIds: originalStrokeIds,
    );
  }

  Future<List<LanguageModel>> availableLanguages() async {
    // Returns the built-in English model. When an ML Kit backend is active,
    // this would query the backend for its full list of supported languages.
    return const [LanguageModel.builtIn];
  }

  Future<void> setActiveLanguage(String code) async {
    _activeLanguage = code;
    if (!await _primary.supportsLanguage(code)) {
      await _primary.downloadModel(code);
    }
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _resultController.close();
    await _primary.dispose();
    await _fallback?.dispose();
  }
}
