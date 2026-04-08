import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'flash_card.dart';

/// A named collection of [FlashCard]s.
class FlashCardDeck extends Equatable {
  FlashCardDeck({
    String? id,
    required this.name,
    this.description,
    this.emoji = '🗂️',
    this.color = const Color(0xFF4A90D9),
    this.cards = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.notebookId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final String? description;
  final String emoji;
  final Color color;
  final List<FlashCard> cards;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional notebook link (for decks created from notebook notes).
  final String? notebookId;

  int get cardCount => cards.length;

  /// Cards that are due for review right now.
  List<FlashCard> get dueCards => cards.where((c) => c.isDue).toList();

  /// Cards that have never been reviewed.
  List<FlashCard> get newCards => cards.where((c) => c.isNew).toList();

  /// Cards that have been reviewed at least once and are not currently due.
  List<FlashCard> get learnedCards =>
      cards.where((c) => !c.isNew && !c.isDue).toList();

  /// Mastery percentage: cards with ≥ 3 consecutive correct reviews / total.
  double get masteryPercent {
    if (cards.isEmpty) return 0;
    final mastered = cards.where((c) => c.correctStreak >= 3).length;
    return mastered / cards.length;
  }

  FlashCardDeck copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    String? emoji,
    Color? color,
    List<FlashCard>? cards,
    DateTime? updatedAt,
    String? notebookId,
  }) =>
      FlashCardDeck(
        id: id,
        name: name ?? this.name,
        description:
            clearDescription ? null : (description ?? this.description),
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        cards: cards ?? this.cards,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        notebookId: notebookId ?? this.notebookId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'emoji': emoji,
        'color': color.value,
        'cards': cards.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'notebookId': notebookId,
      };

  factory FlashCardDeck.fromJson(Map<String, dynamic> m) => FlashCardDeck(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        emoji: m['emoji'] as String? ?? '🗂️',
        color: Color(m['color'] as int? ?? 0xFF4A90D9),
        cards: (m['cards'] as List?)
                ?.map((c) => FlashCard.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        notebookId: m['notebookId'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, name, description, emoji, color, cards, createdAt, notebookId];
}
