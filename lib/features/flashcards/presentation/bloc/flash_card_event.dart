import 'package:equatable/equatable.dart';

import '../../domain/entities/flash_card.dart';
import '../../domain/entities/quiz_session.dart';

/// Events dispatched to [FlashCardBloc].
abstract class FlashCardEvent extends Equatable {
  const FlashCardEvent();
  @override
  List<Object?> get props => [];
}

// ── Lifecycle ────────────────────────────────────────────────────────────────

/// Load all decks and stats from persistent storage.
class FlashCardsLoaded extends FlashCardEvent {
  const FlashCardsLoaded();
}

// ── Deck CRUD ────────────────────────────────────────────────────────────────

/// Create a new deck.
class DeckCreated extends FlashCardEvent {
  const DeckCreated({required this.name, this.description, this.emoji});
  final String name;
  final String? description;
  final String? emoji;
  @override
  List<Object?> get props => [name, description, emoji];
}

/// Update an existing deck's metadata.
class DeckUpdated extends FlashCardEvent {
  const DeckUpdated({
    required this.deckId,
    this.name,
    this.description,
    this.emoji,
  });
  final String deckId;
  final String? name;
  final String? description;
  final String? emoji;
  @override
  List<Object?> get props => [deckId, name, description, emoji];
}

/// Delete a deck and all its cards.
class DeckDeleted extends FlashCardEvent {
  const DeckDeleted(this.deckId);
  final String deckId;
  @override
  List<Object?> get props => [deckId];
}

// ── Card CRUD ────────────────────────────────────────────────────────────────

/// Add a new card to a deck.
class CardAdded extends FlashCardEvent {
  const CardAdded({
    required this.deckId,
    required this.front,
    required this.back,
    this.tags = const [],
  });
  final String deckId;
  final String front;
  final String back;
  final List<String> tags;
  @override
  List<Object?> get props => [deckId, front, back, tags];
}

/// Update an existing card.
class CardUpdated extends FlashCardEvent {
  const CardUpdated({
    required this.deckId,
    required this.cardId,
    this.front,
    this.back,
    this.tags,
  });
  final String deckId;
  final String cardId;
  final String? front;
  final String? back;
  final List<String>? tags;
  @override
  List<Object?> get props => [deckId, cardId, front, back, tags];
}

/// Delete a card from a deck.
class CardDeleted extends FlashCardEvent {
  const CardDeleted({required this.deckId, required this.cardId});
  final String deckId;
  final String cardId;
  @override
  List<Object?> get props => [deckId, cardId];
}

// ── Study Session ────────────────────────────────────────────────────────────

/// Start a spaced-repetition study session for a deck.
class StudySessionStarted extends FlashCardEvent {
  const StudySessionStarted(this.deckId);
  final String deckId;
  @override
  List<Object?> get props => [deckId];
}

/// Rate the current card during a study session.
class CardReviewed extends FlashCardEvent {
  const CardReviewed({required this.cardId, required this.difficulty});
  final String cardId;
  final CardDifficulty difficulty;
  @override
  List<Object?> get props => [cardId, difficulty];
}

/// End the current study session.
class StudySessionEnded extends FlashCardEvent {
  const StudySessionEnded();
}

// ── Quiz Mode ────────────────────────────────────────────────────────────────

/// Start a quiz of the given type for a deck.
class QuizStarted extends FlashCardEvent {
  const QuizStarted({required this.deckId, required this.quizType});
  final String deckId;
  final QuizType quizType;
  @override
  List<Object?> get props => [deckId, quizType];
}

/// Answer the current quiz question.
class QuizAnswered extends FlashCardEvent {
  const QuizAnswered(this.answer);
  final String answer;
  @override
  List<Object?> get props => [answer];
}

/// Move to the next quiz question.
class QuizNextQuestion extends FlashCardEvent {
  const QuizNextQuestion();
}

/// End the current quiz.
class QuizEnded extends FlashCardEvent {
  const QuizEnded();
}

// ── Navigation ───────────────────────────────────────────────────────────────

/// Select a deck to view its details.
class DeckSelected extends FlashCardEvent {
  const DeckSelected(this.deckId);
  final String deckId;
  @override
  List<Object?> get props => [deckId];
}

/// Deselect the current deck (go back to list).
class DeckDeselected extends FlashCardEvent {
  const DeckDeselected();
}
