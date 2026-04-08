import 'package:biscuits/core/utils/result.dart';
import 'package:biscuits/features/flashcards/domain/entities/flash_card_deck.dart';
import 'package:biscuits/features/flashcards/domain/entities/study_stats.dart';

/// Contract for flash-card deck and study statistics persistence.
abstract class IFlashCardRepository {
  /// Loads all persisted decks.
  Future<Result<List<FlashCardDeck>>> loadDecks();

  /// Persists the full list of [decks].
  Future<Result<void>> saveDecks(List<FlashCardDeck> decks);

  /// Loads all study statistics.
  Future<Result<List<StudyStats>>> loadStats();

  /// Persists the full list of study [stats].
  Future<Result<void>> saveStats(List<StudyStats> stats);
}
