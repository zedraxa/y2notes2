import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/flash_card_repository.dart';
import '../../domain/entities/flash_card.dart';
import '../../domain/entities/flash_card_deck.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/entities/spaced_repetition.dart';
import '../../domain/entities/study_stats.dart';
import 'flash_card_event.dart';
import 'flash_card_state.dart';

/// BLoC that manages flash card decks, study sessions, quizzes, and stats.
class FlashCardBloc extends Bloc<FlashCardEvent, FlashCardState> {
  FlashCardBloc({required FlashCardRepository repository})
      : _repository = repository,
        super(const FlashCardState()) {
    on<FlashCardsLoaded>(_onLoaded);
    // Deck CRUD
    on<DeckCreated>(_onDeckCreated);
    on<DeckUpdated>(_onDeckUpdated);
    on<DeckDeleted>(_onDeckDeleted);
    // Card CRUD
    on<CardAdded>(_onCardAdded);
    on<CardUpdated>(_onCardUpdated);
    on<CardDeleted>(_onCardDeleted);
    // Study session
    on<StudySessionStarted>(_onStudySessionStarted);
    on<CardReviewed>(_onCardReviewed);
    on<StudySessionEnded>(_onStudySessionEnded);
    // Quiz
    on<QuizStarted>(_onQuizStarted);
    on<QuizAnswered>(_onQuizAnswered);
    on<QuizNextQuestion>(_onQuizNextQuestion);
    on<QuizEnded>(_onQuizEnded);
    // Navigation
    on<DeckSelected>(_onDeckSelected);
    on<DeckDeselected>(_onDeckDeselected);
  }

  final FlashCardRepository _repository;
  final _random = Random();

  // ── Persistence helpers ────────────────────────────────────────────────────

  Future<void> _persist(List<FlashCardDeck> decks) =>
      _repository.saveDecks(decks);

  Future<void> _persistStats(List<StudyStats> stats) =>
      _repository.saveStats(stats);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> _onLoaded(
      FlashCardsLoaded event, Emitter<FlashCardState> emit) async {
    emit(state.copyWith(status: FlashCardStatus.loading));
    try {
      final decks = await _repository.loadDecks();
      final stats = await _repository.loadStats();
      emit(state.copyWith(
        status: FlashCardStatus.loaded,
        decks: decks,
        allStats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FlashCardStatus.error,
        errorMessage: 'Failed to load flash cards: $e',
      ));
    }
  }

  // ── Deck CRUD ──────────────────────────────────────────────────────────────

  Future<void> _onDeckCreated(
      DeckCreated event, Emitter<FlashCardState> emit) async {
    final deck = FlashCardDeck(
      name: event.name,
      description: event.description,
      emoji: event.emoji ?? '🗂️',
    );
    final updated = [...state.decks, deck];
    emit(state.copyWith(decks: updated));
    await _persist(updated);
  }

  Future<void> _onDeckUpdated(
      DeckUpdated event, Emitter<FlashCardState> emit) async {
    final updated = state.decks.map((d) {
      if (d.id != event.deckId) return d;
      return d.copyWith(
        name: event.name,
        description: event.description,
        emoji: event.emoji,
      );
    }).toList();
    emit(state.copyWith(decks: updated));
    await _persist(updated);
  }

  Future<void> _onDeckDeleted(
      DeckDeleted event, Emitter<FlashCardState> emit) async {
    final updated = state.decks.where((d) => d.id != event.deckId).toList();
    emit(state.copyWith(
      decks: updated,
      clearSelectedDeck: state.selectedDeckId == event.deckId,
    ));
    await _persist(updated);
  }

  // ── Card CRUD ──────────────────────────────────────────────────────────────

  Future<void> _onCardAdded(
      CardAdded event, Emitter<FlashCardState> emit) async {
    final card = FlashCard(
      front: event.front,
      back: event.back,
      deckId: event.deckId,
      tags: event.tags,
    );
    final updated = state.decks.map((d) {
      if (d.id != event.deckId) return d;
      return d.copyWith(cards: [...d.cards, card]);
    }).toList();
    emit(state.copyWith(decks: updated));
    await _persist(updated);
  }

  Future<void> _onCardUpdated(
      CardUpdated event, Emitter<FlashCardState> emit) async {
    final updated = state.decks.map((d) {
      if (d.id != event.deckId) return d;
      final cards = d.cards.map((c) {
        if (c.id != event.cardId) return c;
        return c.copyWith(
          front: event.front,
          back: event.back,
          tags: event.tags,
        );
      }).toList();
      return d.copyWith(cards: cards);
    }).toList();
    emit(state.copyWith(decks: updated));
    await _persist(updated);
  }

  Future<void> _onCardDeleted(
      CardDeleted event, Emitter<FlashCardState> emit) async {
    final updated = state.decks.map((d) {
      if (d.id != event.deckId) return d;
      final cards = d.cards.where((c) => c.id != event.cardId).toList();
      return d.copyWith(cards: cards);
    }).toList();
    emit(state.copyWith(decks: updated));
    await _persist(updated);
  }

  // ── Study Session ──────────────────────────────────────────────────────────

  void _onStudySessionStarted(
      StudySessionStarted event, Emitter<FlashCardState> emit) {
    final deck = state.decks.firstWhere((d) => d.id == event.deckId,
        orElse: () => FlashCardDeck(name: ''));
    if (deck.cards.isEmpty) return;

    // Build study queue: due cards first, then new cards, shuffled.
    final due = List<FlashCard>.of(deck.dueCards)..shuffle(_random);
    final newCards = List<FlashCard>.of(deck.newCards)..shuffle(_random);
    // If no due or new cards, study all cards.
    var queue = [...due, ...newCards];
    if (queue.isEmpty) {
      queue = List<FlashCard>.of(deck.cards)..shuffle(_random);
    }

    emit(state.copyWith(
      status: FlashCardStatus.studying,
      selectedDeckId: event.deckId,
      studyQueue: queue,
      studyIndex: 0,
      isCardFlipped: false,
      studyStartTime: DateTime.now(),
      sessionCorrect: 0,
      sessionIncorrect: 0,
    ));
  }

  Future<void> _onCardReviewed(
      CardReviewed event, Emitter<FlashCardState> emit) async {
    final card = state.currentStudyCard;
    if (card == null || card.id != event.cardId) return;

    final reviewed = SpacedRepetition.review(card, event.difficulty);
    final isCorrect = event.difficulty != CardDifficulty.again;

    // Update the card in the deck.
    final updatedDecks = state.decks.map((d) {
      if (d.id != state.selectedDeckId) return d;
      final cards = d.cards.map((c) {
        if (c.id != event.cardId) return c;
        return reviewed;
      }).toList();
      return d.copyWith(cards: cards);
    }).toList();

    // Also update the study queue entry.
    final updatedQueue = List<FlashCard>.of(state.studyQueue);
    updatedQueue[state.studyIndex] = reviewed;

    final nextIndex = state.studyIndex + 1;
    emit(state.copyWith(
      decks: updatedDecks,
      studyQueue: updatedQueue,
      studyIndex: nextIndex,
      isCardFlipped: false,
      sessionCorrect: state.sessionCorrect + (isCorrect ? 1 : 0),
      sessionIncorrect: state.sessionIncorrect + (isCorrect ? 0 : 1),
    ));

    await _persist(updatedDecks);
  }

  Future<void> _onStudySessionEnded(
      StudySessionEnded event, Emitter<FlashCardState> emit) async {
    // Record study stats.
    if (state.selectedDeckId != null && state.studyStartTime != null) {
      final duration =
          DateTime.now().difference(state.studyStartTime!).inSeconds;
      final stat = StudyStats(
        deckId: state.selectedDeckId!,
        date: DateTime.now(),
        cardsStudied: state.sessionCorrect + state.sessionIncorrect,
        correctCount: state.sessionCorrect,
        incorrectCount: state.sessionIncorrect,
        studyDurationSeconds: duration,
      );
      final updatedStats = [...state.allStats, stat];
      emit(state.copyWith(
        status: FlashCardStatus.loaded,
        studyQueue: const [],
        studyIndex: 0,
        isCardFlipped: false,
        allStats: updatedStats,
        clearStudyStartTime: true,
        sessionCorrect: 0,
        sessionIncorrect: 0,
      ));
      await _persistStats(updatedStats);
    } else {
      emit(state.copyWith(
        status: FlashCardStatus.loaded,
        studyQueue: const [],
        studyIndex: 0,
        isCardFlipped: false,
        clearStudyStartTime: true,
      ));
    }
  }

  // ── Quiz ───────────────────────────────────────────────────────────────────

  void _onQuizStarted(QuizStarted event, Emitter<FlashCardState> emit) {
    final deck = state.decks.firstWhere((d) => d.id == event.deckId,
        orElse: () => FlashCardDeck(name: ''));
    if (deck.cards.length < 2) return;

    final shuffled = List<FlashCard>.of(deck.cards)..shuffle(_random);
    final questions = shuffled.map((card) {
      List<String> options = [];
      if (event.quizType == QuizType.multipleChoice) {
        // Build 4 options (1 correct + 3 distractors).
        final distractors = deck.cards
            .where((c) => c.id != card.id)
            .toList()
          ..shuffle(_random);
        options = [
          card.back,
          ...distractors.take(3).map((c) => c.back),
        ]..shuffle(_random);
      }
      return QuizQuestion(
        card: card,
        type: event.quizType,
        options: options,
      );
    }).toList();

    final session = QuizSession(
      deckId: event.deckId,
      quizType: event.quizType,
      questions: questions,
    );
    emit(state.copyWith(
      status: FlashCardStatus.quizzing,
      selectedDeckId: event.deckId,
      quizSession: session,
    ));
  }

  void _onQuizAnswered(QuizAnswered event, Emitter<FlashCardState> emit) {
    final session = state.quizSession;
    if (session == null) return;

    final question = session.currentQuestion;
    if (question == null) return;

    bool isCorrect;
    if (session.quizType == QuizType.matching) {
      isCorrect =
          event.answer.toLowerCase() == question.card.back.toLowerCase();
    } else if (session.quizType == QuizType.written) {
      // Flexible matching: trim, case-insensitive.
      isCorrect = event.answer.trim().toLowerCase() ==
          question.card.back.trim().toLowerCase();
    } else {
      isCorrect = event.answer == question.card.back;
    }

    final updatedQuestion = question.copyWith(
      userAnswer: event.answer,
      isCorrect: isCorrect,
    );

    final questions = List<QuizQuestion>.of(session.questions);
    questions[session.currentIndex] = updatedQuestion;

    emit(state.copyWith(
      quizSession: session.copyWith(questions: questions),
    ));
  }

  void _onQuizNextQuestion(
      QuizNextQuestion event, Emitter<FlashCardState> emit) {
    final session = state.quizSession;
    if (session == null) return;

    final nextIndex = session.currentIndex + 1;
    if (nextIndex >= session.totalQuestions) {
      // Quiz complete.
      emit(state.copyWith(
        quizSession: session.copyWith(
          currentIndex: nextIndex,
          completedAt: DateTime.now(),
        ),
      ));
    } else {
      emit(state.copyWith(
        quizSession: session.copyWith(currentIndex: nextIndex),
      ));
    }
  }

  void _onQuizEnded(QuizEnded event, Emitter<FlashCardState> emit) {
    emit(state.copyWith(
      status: FlashCardStatus.loaded,
      clearQuizSession: true,
    ));
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _onDeckSelected(DeckSelected event, Emitter<FlashCardState> emit) {
    emit(state.copyWith(selectedDeckId: event.deckId));
  }

  void _onDeckDeselected(DeckDeselected event, Emitter<FlashCardState> emit) {
    emit(state.copyWith(clearSelectedDeck: true));
  }
}
