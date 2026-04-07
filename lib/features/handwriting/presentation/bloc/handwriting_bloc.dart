import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/handwriting/domain/entities/text_block.dart';
import 'package:y2notes2/features/handwriting/engine/backends/heuristic_recognizer.dart';
import 'package:y2notes2/features/handwriting/engine/handwriting_search.dart';
import 'package:y2notes2/features/handwriting/engine/math_recognizer.dart';
import 'package:y2notes2/features/handwriting/engine/recognition_engine.dart';
import 'package:y2notes2/features/handwriting/engine/recognition_manager.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_event.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_state.dart';

/// BLoC that manages handwriting recognition state.
class HandwritingBloc extends Bloc<HandwritingEvent, HandwritingState> {
  HandwritingBloc({
    RecognitionManager? manager,
    List<Stroke> Function()? strokesProvider,
  }) : super(const HandwritingState()) {
    _manager = manager ??
        RecognitionManager(primaryBackend: HeuristicRecognizer());
    _strokesProvider = strokesProvider ?? () => const [];

    on<RecognitionRequested>(_onRecognitionRequested);
    on<RealTimeRecognitionToggled>(_onRealTimeToggled);
    on<CandidateAccepted>(_onCandidateAccepted);
    on<CandidateRejected>(_onCandidateRejected);
    on<TextBlockCreated>(_onTextBlockCreated);
    on<TextBlockEdited>(_onTextBlockEdited);
    on<TextBlockDeleted>(_onTextBlockDeleted);
    on<RevertToHandwriting>(_onRevertToHandwriting);
    on<LanguageChanged>(_onLanguageChanged);
    on<RecognitionModeChanged>(_onModeChanged);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<RecognizeAllRequested>(_onRecognizeAll);
    on<MathExpressionDetected>(_onMathDetected);
    on<TextBlockMoved>(_onTextBlockMoved);
  }

  late final RecognitionManager _manager;
  late final List<Stroke> Function() _strokesProvider;
  final _mathRecognizer = const MathRecognizer();
  final _search = HandwritingSearch();

  @override
  Future<void> close() async {
    await _manager.dispose();
    return super.close();
  }

  // ─── Event handlers ──────────────────────────────────────────────────────

  Future<void> _onRecognitionRequested(
    RecognitionRequested event,
    Emitter<HandwritingState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, clearError: true));
    try {
      // Use strokes from the event if provided, otherwise fall back to provider.
      final allStrokes = event.strokes.isNotEmpty
          ? event.strokes
          : _strokesProvider();
      final strokes = event.strokeIds.isEmpty
          ? allStrokes
          : allStrokes.where((s) => event.strokeIds.contains(s.id)).toList();

      final result = await _manager.recognizeStrokes(strokes);

      // Check for math
      final mathResult = result.best != null
          ? _mathRecognizer.tryRecognize(result.best!.text)
          : null;

      emit(state.copyWith(
        latestResult: result,
        isProcessing: false,
        pendingStrokeIds: event.strokeIds,
        mathResult: mathResult,
      ));
    } catch (e) {
      emit(state.copyWith(
        isProcessing: false,
        errorMessage: 'Recognition failed: $e',
      ));
    }
  }

  void _onRealTimeToggled(
    RealTimeRecognitionToggled event,
    Emitter<HandwritingState> emit,
  ) {
    final newMode =
        event.enabled ? RecognitionMode.realTime : RecognitionMode.manual;
    _manager.mode = newMode;
    emit(state.copyWith(mode: newMode));
  }

  void _onCandidateAccepted(
    CandidateAccepted event,
    Emitter<HandwritingState> emit,
  ) {
    final result = state.latestResult;
    if (result == null || result.isEmpty) return;
    if (event.candidateIndex >= result.candidates.length) return;

    final candidate = result.candidates[event.candidateIndex];

    // Compute position from bounding box
    final position = candidate.boundingBox.isEmpty
        ? const Offset(100, 100)
        : candidate.boundingBox.topLeft;

    final block = _manager.convertToTextBlock(
      result,
      position: position,
      originalStrokeIds: state.pendingStrokeIds,
    );

    // Use the selected candidate's text
    final finalBlock = block.copyWith(text: candidate.text);

    // Index the new text for search
    _search.indexPage(RecognizedPage(
      pageId: 'current',
      text: state.textBlocks
              .map((b) => b.text)
              .join(' ') +
          ' ' +
          finalBlock.text,
      strokes: const [],
      strokeBounds: const [],
    ));

    emit(state.copyWith(
      textBlocks: [...state.textBlocks, finalBlock],
      clearLatestResult: true,
      pendingStrokeIds: const [],
    ));
  }

  void _onCandidateRejected(
    CandidateRejected event,
    Emitter<HandwritingState> emit,
  ) {
    emit(state.copyWith(
      clearLatestResult: true,
      pendingStrokeIds: const [],
      clearMathResult: true,
    ));
  }

  void _onTextBlockCreated(
    TextBlockCreated event,
    Emitter<HandwritingState> emit,
  ) {
    emit(state.copyWith(
      textBlocks: [...state.textBlocks, event.textBlock],
    ));
  }

  void _onTextBlockEdited(
    TextBlockEdited event,
    Emitter<HandwritingState> emit,
  ) {
    final updated = state.textBlocks.map((b) {
      if (b.id == event.id) return b.copyWith(text: event.newText);
      return b;
    }).toList();
    emit(state.copyWith(textBlocks: updated));
  }

  void _onTextBlockDeleted(
    TextBlockDeleted event,
    Emitter<HandwritingState> emit,
  ) {
    emit(state.copyWith(
      textBlocks: state.textBlocks.where((b) => b.id != event.id).toList(),
    ));
  }

  void _onRevertToHandwriting(
    RevertToHandwriting event,
    Emitter<HandwritingState> emit,
  ) {
    // Remove the text block; original strokes are preserved in CanvasBloc
    emit(state.copyWith(
      textBlocks: state.textBlocks.where((b) => b.id != event.textBlockId).toList(),
    ));
  }

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<HandwritingState> emit,
  ) async {
    await _manager.setActiveLanguage(event.code);
    emit(state.copyWith(activeLanguage: event.code));
  }

  void _onModeChanged(
    RecognitionModeChanged event,
    Emitter<HandwritingState> emit,
  ) {
    _manager.mode = event.mode;
    emit(state.copyWith(mode: event.mode));
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<HandwritingState> emit,
  ) {
    final query = event.query;
    final matches = _search.search(query);
    emit(state.copyWith(
      searchQuery: query,
      searchMatches: matches,
    ));
  }

  Future<void> _onRecognizeAll(
    RecognizeAllRequested event,
    Emitter<HandwritingState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, processingProgress: 0.0));
    try {
      final allStrokes = _strokesProvider();
      final result = await _manager.recognizePage(allStrokes);
      emit(state.copyWith(
        latestResult: result,
        isProcessing: false,
        processingProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isProcessing: false,
        errorMessage: 'Batch recognition failed: $e',
      ));
    }
  }

  void _onMathDetected(
    MathExpressionDetected event,
    Emitter<HandwritingState> emit,
  ) {
    // Math detection is handled as part of _onRecognitionRequested.
    // This event can be used to trigger math-specific UI.
    emit(state.copyWith(pendingStrokeIds: event.strokeIds));
  }

  void _onTextBlockMoved(
    TextBlockMoved event,
    Emitter<HandwritingState> emit,
  ) {
    final pos = event.newPosition as Offset;
    final updated = state.textBlocks.map((b) {
      if (b.id == event.id) return b.copyWith(position: pos);
      return b;
    }).toList();
    emit(state.copyWith(textBlocks: updated));
  }
}
