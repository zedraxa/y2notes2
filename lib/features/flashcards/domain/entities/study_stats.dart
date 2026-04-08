import 'package:equatable/equatable.dart';

/// Statistics tracked for a single study / review session.
class StudyStats extends Equatable {
  const StudyStats({
    required this.deckId,
    required this.date,
    this.cardsStudied = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.averageEase = 2.5,
    this.studyDurationSeconds = 0,
  });

  final String deckId;
  final DateTime date;
  final int cardsStudied;
  final int correctCount;
  final int incorrectCount;
  final double averageEase;
  final int studyDurationSeconds;

  double get accuracyPercent {
    if (cardsStudied == 0) return 0;
    return correctCount / cardsStudied;
  }

  StudyStats copyWith({
    int? cardsStudied,
    int? correctCount,
    int? incorrectCount,
    double? averageEase,
    int? studyDurationSeconds,
  }) =>
      StudyStats(
        deckId: deckId,
        date: date,
        cardsStudied: cardsStudied ?? this.cardsStudied,
        correctCount: correctCount ?? this.correctCount,
        incorrectCount: incorrectCount ?? this.incorrectCount,
        averageEase: averageEase ?? this.averageEase,
        studyDurationSeconds:
            studyDurationSeconds ?? this.studyDurationSeconds,
      );

  Map<String, dynamic> toJson() => {
        'deckId': deckId,
        'date': date.toIso8601String(),
        'cardsStudied': cardsStudied,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'averageEase': averageEase,
        'studyDurationSeconds': studyDurationSeconds,
      };

  factory StudyStats.fromJson(Map<String, dynamic> m) => StudyStats(
        deckId: m['deckId'] as String,
        date: DateTime.parse(m['date'] as String),
        cardsStudied: m['cardsStudied'] as int? ?? 0,
        correctCount: m['correctCount'] as int? ?? 0,
        incorrectCount: m['incorrectCount'] as int? ?? 0,
        averageEase: (m['averageEase'] as num?)?.toDouble() ?? 2.5,
        studyDurationSeconds: m['studyDurationSeconds'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
        deckId,
        date,
        cardsStudied,
        correctCount,
        incorrectCount,
        averageEase,
        studyDurationSeconds,
      ];
}
