import 'package:equatable/equatable.dart';

import '../../domain/entities/flash_card.dart';
import '../../domain/entities/flash_card_deck.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/entities/study_stats.dart';

/// The current phase of the flash card feature.
enum FlashCardStatus {
  initial,
  loading,
  loaded,
  studying,
  quizzing,
  error,
}

/// Immutable snapshot of flash card feature state.
class FlashCardState extends Equatable {
  const FlashCardState({
    this.status = FlashCardStatus.initial,
    this.decks = const [],
    this.selectedDeckId,
    this.studyQueue = const [],
    this.studyIndex = 0,
    this.isCardFlipped = false,
    this.quizSession,
    this.allStats = const [],
    this.studyStartTime,
    this.sessionCorrect = 0,
    this.sessionIncorrect = 0,
    this.errorMessage,
  });

  final FlashCardStatus status;
  final List<FlashCardDeck> decks;

  /// The currently selected deck (for detail view).
  final String? selectedDeckId;

  // ── Study session state ────────────────────────────────────────────────────

  /// Ordered list of cards to review in the current study session.
  final List<FlashCard> studyQueue;

  /// Index of the card currently being studied.
  final int studyIndex;

  /// Whether the current study card is showing its back (answer).
  final bool isCardFlipped;

  // ── Quiz state ─────────────────────────────────────────────────────────────

  final QuizSession? quizSession;

  // ── Statistics ─────────────────────────────────────────────────────────────

  final List<StudyStats> allStats;

  /// When the current study session started (for duration tracking).
  final DateTime? studyStartTime;

  /// Running count of correct/incorrect during a session.
  final int sessionCorrect;
  final int sessionIncorrect;

  final String? errorMessage;

  // ── Computed helpers ───────────────────────────────────────────────────────

  FlashCardDeck? get selectedDeck {
    if (selectedDeckId == null) return null;
    final matches = decks.where((d) => d.id == selectedDeckId);
    return matches.isEmpty ? null : matches.first;
  }

  FlashCard? get currentStudyCard {
    if (studyIndex < 0 || studyIndex >= studyQueue.length) return null;
    return studyQueue[studyIndex];
  }

  bool get isStudyComplete => studyIndex >= studyQueue.length;

  /// Stats for a specific deck.
  List<StudyStats> statsForDeck(String deckId) =>
      allStats.where((s) => s.deckId == deckId).toList();

  FlashCardState copyWith({
    FlashCardStatus? status,
    List<FlashCardDeck>? decks,
    String? selectedDeckId,
    bool clearSelectedDeck = false,
    List<FlashCard>? studyQueue,
    int? studyIndex,
    bool? isCardFlipped,
    QuizSession? quizSession,
    bool clearQuizSession = false,
    List<StudyStats>? allStats,
    DateTime? studyStartTime,
    bool clearStudyStartTime = false,
    int? sessionCorrect,
    int? sessionIncorrect,
    String? errorMessage,
    bool clearError = false,
  }) =>
      FlashCardState(
        status: status ?? this.status,
        decks: decks ?? this.decks,
        selectedDeckId: clearSelectedDeck
            ? null
            : (selectedDeckId ?? this.selectedDeckId),
        studyQueue: studyQueue ?? this.studyQueue,
        studyIndex: studyIndex ?? this.studyIndex,
        isCardFlipped: isCardFlipped ?? this.isCardFlipped,
        quizSession: clearQuizSession
            ? null
            : (quizSession ?? this.quizSession),
        allStats: allStats ?? this.allStats,
        studyStartTime: clearStudyStartTime
            ? null
            : (studyStartTime ?? this.studyStartTime),
        sessionCorrect: sessionCorrect ?? this.sessionCorrect,
        sessionIncorrect: sessionIncorrect ?? this.sessionIncorrect,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        status,
        decks,
        selectedDeckId,
        studyQueue,
        studyIndex,
        isCardFlipped,
        quizSession,
        allStats,
        studyStartTime,
        sessionCorrect,
        sessionIncorrect,
        errorMessage,
      ];
}
