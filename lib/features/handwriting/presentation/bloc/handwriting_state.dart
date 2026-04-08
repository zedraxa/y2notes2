import 'package:equatable/equatable.dart';
import 'package:biscuits/features/handwriting/domain/entities/recognition_result.dart';
import 'package:biscuits/features/handwriting/domain/entities/text_block.dart';
import 'package:biscuits/features/handwriting/domain/entities/writing_analytics.dart';
import 'package:biscuits/features/handwriting/domain/models/search_match.dart';
import 'package:biscuits/features/handwriting/engine/recognition_engine.dart';
import 'package:biscuits/features/handwriting/engine/math_recognizer.dart';

class HandwritingState extends Equatable {
  const HandwritingState({
    this.mode = RecognitionMode.manual,
    this.activeLanguage = 'en-US',
    this.latestResult,
    this.textBlocks = const [],
    this.isProcessing = false,
    this.processingProgress = 0.0,
    this.searchQuery,
    this.searchMatches = const [],
    this.analytics,
    this.pendingStrokeIds = const [],
    this.mathResult,
    this.errorMessage,
  });

  final RecognitionMode mode;
  final String activeLanguage;
  final RecognitionResult? latestResult;
  final List<TextBlock> textBlocks;
  final bool isProcessing;
  final double processingProgress; // 0.0–1.0
  final String? searchQuery;
  final List<SearchMatch> searchMatches;
  final WritingAnalytics? analytics;
  final List<String> pendingStrokeIds; // strokes awaiting recognition
  final MathRecognitionResult? mathResult;
  final String? errorMessage;

  bool get hasResult => latestResult != null && !latestResult!.isEmpty;
  bool get isSearching => searchQuery != null && searchQuery!.isNotEmpty;

  HandwritingState copyWith({
    RecognitionMode? mode,
    String? activeLanguage,
    RecognitionResult? latestResult,
    bool clearLatestResult = false,
    List<TextBlock>? textBlocks,
    bool? isProcessing,
    double? processingProgress,
    String? searchQuery,
    bool clearSearchQuery = false,
    List<SearchMatch>? searchMatches,
    WritingAnalytics? analytics,
    List<String>? pendingStrokeIds,
    MathRecognitionResult? mathResult,
    bool clearMathResult = false,
    String? errorMessage,
    bool clearError = false,
  }) =>
      HandwritingState(
        mode: mode ?? this.mode,
        activeLanguage: activeLanguage ?? this.activeLanguage,
        latestResult: clearLatestResult ? null : (latestResult ?? this.latestResult),
        textBlocks: textBlocks ?? this.textBlocks,
        isProcessing: isProcessing ?? this.isProcessing,
        processingProgress: processingProgress ?? this.processingProgress,
        searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
        searchMatches: searchMatches ?? this.searchMatches,
        analytics: analytics ?? this.analytics,
        pendingStrokeIds: pendingStrokeIds ?? this.pendingStrokeIds,
        mathResult: clearMathResult ? null : (mathResult ?? this.mathResult),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        mode,
        activeLanguage,
        latestResult,
        textBlocks,
        isProcessing,
        processingProgress,
        searchQuery,
        searchMatches,
        analytics,
        pendingStrokeIds,
        mathResult,
        errorMessage,
      ];
}
