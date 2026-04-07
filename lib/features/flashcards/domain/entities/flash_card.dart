import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Difficulty rating given by the user after reviewing a card.
enum CardDifficulty {
  /// Complete blackout — no recall at all.
  again,

  /// Significant difficulty, but some recognition.
  hard,

  /// Correct response with some hesitation.
  good,

  /// Perfect, effortless recall.
  easy,
}

/// A single flash card with a front (question) and back (answer).
class FlashCard extends Equatable {
  FlashCard({
    String? id,
    required this.front,
    required this.back,
    this.deckId = '',
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    // ── SM-2 fields ────────────────────────────────────────────────────────
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.interval = 0,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    this.totalReviews = 0,
    this.correctStreak = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        nextReviewAt = nextReviewAt ?? DateTime.now(),
        lastReviewedAt = lastReviewedAt;

  final String id;

  /// The question / prompt shown on the front of the card.
  final String front;

  /// The answer / explanation shown on the back of the card.
  final String back;

  /// The deck this card belongs to.
  final String deckId;

  /// Optional tags for filtering.
  final List<String> tags;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ── SM-2 spaced-repetition state ──────────────────────────────────────────

  /// Number of consecutive correct reviews (resets to 0 on [CardDifficulty.again]).
  final int repetitions;

  /// Ease factor (≥ 1.3). Higher means longer intervals between reviews.
  final double easeFactor;

  /// Current inter-repetition interval in **days**.
  final int interval;

  /// The next date/time this card should be shown for review.
  final DateTime nextReviewAt;

  /// When the card was last reviewed.
  final DateTime? lastReviewedAt;

  /// Lifetime review count.
  final int totalReviews;

  /// Current streak of [CardDifficulty.good] or [CardDifficulty.easy] reviews.
  final int correctStreak;

  /// Whether this card is due for review right now.
  bool get isDue => DateTime.now().isAfter(nextReviewAt) ||
      DateTime.now().isAtSameMomentAs(nextReviewAt);

  /// Whether this card has never been reviewed.
  bool get isNew => totalReviews == 0;

  FlashCard copyWith({
    String? front,
    String? back,
    String? deckId,
    List<String>? tags,
    DateTime? updatedAt,
    int? repetitions,
    double? easeFactor,
    int? interval,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    int? totalReviews,
    int? correctStreak,
  }) =>
      FlashCard(
        id: id,
        front: front ?? this.front,
        back: back ?? this.back,
        deckId: deckId ?? this.deckId,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        repetitions: repetitions ?? this.repetitions,
        easeFactor: easeFactor ?? this.easeFactor,
        interval: interval ?? this.interval,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        totalReviews: totalReviews ?? this.totalReviews,
        correctStreak: correctStreak ?? this.correctStreak,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'front': front,
        'back': back,
        'deckId': deckId,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'repetitions': repetitions,
        'easeFactor': easeFactor,
        'interval': interval,
        'nextReviewAt': nextReviewAt.toIso8601String(),
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
        'totalReviews': totalReviews,
        'correctStreak': correctStreak,
      };

  factory FlashCard.fromJson(Map<String, dynamic> m) => FlashCard(
        id: m['id'] as String,
        front: m['front'] as String,
        back: m['back'] as String,
        deckId: m['deckId'] as String? ?? '',
        tags: (m['tags'] as List?)?.cast<String>() ?? const [],
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        repetitions: m['repetitions'] as int? ?? 0,
        easeFactor: (m['easeFactor'] as num?)?.toDouble() ?? 2.5,
        interval: m['interval'] as int? ?? 0,
        nextReviewAt: m['nextReviewAt'] == null
            ? DateTime.now()
            : DateTime.parse(m['nextReviewAt'] as String),
        lastReviewedAt: m['lastReviewedAt'] == null
            ? null
            : DateTime.parse(m['lastReviewedAt'] as String),
        totalReviews: m['totalReviews'] as int? ?? 0,
        correctStreak: m['correctStreak'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
        id,
        front,
        back,
        deckId,
        tags,
        createdAt,
        repetitions,
        easeFactor,
        interval,
        nextReviewAt,
        lastReviewedAt,
        totalReviews,
        correctStreak,
      ];
}
