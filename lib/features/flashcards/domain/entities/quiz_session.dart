import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'flash_card.dart';

/// The type of quiz being taken.
enum QuizType {
  /// User types the answer.
  written,

  /// User picks from multiple options.
  multipleChoice,

  /// User matches fronts to backs.
  matching,
}

/// A single question within a quiz.
class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.card,
    required this.type,
    this.options = const [],
    this.userAnswer,
    this.isCorrect,
  });

  /// The flash card this question is based on.
  final FlashCard card;

  /// How this question should be presented.
  final QuizType type;

  /// For [QuizType.multipleChoice]: the list of answer options (one is correct).
  final List<String> options;

  /// The answer the user gave.
  final String? userAnswer;

  /// Whether the user's answer was correct.
  final bool? isCorrect;

  QuizQuestion copyWith({
    String? userAnswer,
    bool? isCorrect,
  }) =>
      QuizQuestion(
        card: card,
        type: type,
        options: options,
        userAnswer: userAnswer ?? this.userAnswer,
        isCorrect: isCorrect ?? this.isCorrect,
      );

  @override
  List<Object?> get props => [card, type, options, userAnswer, isCorrect];
}

/// A quiz session over a set of flash cards.
class QuizSession extends Equatable {
  QuizSession({
    String? id,
    required this.deckId,
    required this.quizType,
    required this.questions,
    DateTime? startedAt,
    this.completedAt,
    this.currentIndex = 0,
  })  : id = id ?? const Uuid().v4(),
        startedAt = startedAt ?? DateTime.now();

  final String id;
  final String deckId;
  final QuizType quizType;
  final List<QuizQuestion> questions;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int currentIndex;

  int get totalQuestions => questions.length;

  int get answeredCount => questions.where((q) => q.userAnswer != null).length;

  int get correctCount =>
      questions.where((q) => q.isCorrect == true).length;

  int get incorrectCount =>
      questions.where((q) => q.isCorrect == false).length;

  double get scorePercent {
    if (answeredCount == 0) return 0;
    return correctCount / answeredCount;
  }

  bool get isComplete => completedAt != null;

  QuizQuestion? get currentQuestion {
    if (currentIndex < 0 || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  QuizSession copyWith({
    List<QuizQuestion>? questions,
    DateTime? completedAt,
    int? currentIndex,
  }) =>
      QuizSession(
        id: id,
        deckId: deckId,
        quizType: quizType,
        questions: questions ?? this.questions,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
        currentIndex: currentIndex ?? this.currentIndex,
      );

  @override
  List<Object?> get props =>
      [id, deckId, quizType, questions, startedAt, completedAt, currentIndex];
}
