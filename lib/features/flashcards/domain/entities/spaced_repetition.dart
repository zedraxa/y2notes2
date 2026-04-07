import 'flash_card.dart';

/// SM-2 spaced repetition algorithm implementation.
///
/// Based on the SuperMemo SM-2 algorithm:
/// https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
///
/// The algorithm adjusts review intervals and ease factors based on
/// the quality of the user's recall.
class SpacedRepetition {
  const SpacedRepetition._();

  /// Quality scores mapped from [CardDifficulty]:
  ///   again → 0, hard → 3, good → 4, easy → 5
  static int _qualityFromDifficulty(CardDifficulty difficulty) {
    switch (difficulty) {
      case CardDifficulty.again:
        return 0;
      case CardDifficulty.hard:
        return 3;
      case CardDifficulty.good:
        return 4;
      case CardDifficulty.easy:
        return 5;
    }
  }

  /// Returns a new [FlashCard] with updated SM-2 scheduling fields
  /// after the user reviews it with the given [difficulty].
  static FlashCard review(FlashCard card, CardDifficulty difficulty) {
    final quality = _qualityFromDifficulty(difficulty);
    final now = DateTime.now();

    int newRepetitions;
    double newEaseFactor;
    int newInterval;

    if (quality < 3) {
      // Failed recall — reset repetitions and show again soon.
      newRepetitions = 0;
      newInterval = 1;
      newEaseFactor = card.easeFactor;
    } else {
      newRepetitions = card.repetitions + 1;

      // Update ease factor using SM-2 formula.
      newEaseFactor = card.easeFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (newEaseFactor < 1.3) newEaseFactor = 1.3;

      // Calculate interval.
      if (newRepetitions == 1) {
        newInterval = 1;
      } else if (newRepetitions == 2) {
        newInterval = 6;
      } else {
        newInterval = (card.interval * newEaseFactor).round();
      }

      // Bonus for easy recall.
      if (difficulty == CardDifficulty.easy) {
        newInterval = (newInterval * 1.3).round();
      }
    }

    // Clamp interval to reasonable range.
    if (newInterval < 1) newInterval = 1;
    if (newInterval > 365) newInterval = 365;

    final nextReview = now.add(Duration(days: newInterval));

    final isCorrect = quality >= 3;

    return card.copyWith(
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      interval: newInterval,
      nextReviewAt: nextReview,
      lastReviewedAt: now,
      totalReviews: card.totalReviews + 1,
      correctStreak: isCorrect ? card.correctStreak + 1 : 0,
      updatedAt: now,
    );
  }
}
