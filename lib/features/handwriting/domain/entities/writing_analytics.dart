import 'package:equatable/equatable.dart';

class WritingAnalytics extends Equatable {
  const WritingAnalytics({
    this.averageCharacterSize = 0.0,
    this.writingSpeedCpm = 0.0,
    this.consistencyScore = 0.0,
    this.averageSlantAngle = 0.0,
    this.averagePressure = 0.0,
    this.totalCharactersRecognized = 0,
    this.commonErrors = const [],
    this.sessionDurationSeconds = 0,
  });

  final double averageCharacterSize;
  final double writingSpeedCpm; // characters per minute
  final double consistencyScore; // 0.0–1.0
  final double averageSlantAngle; // degrees
  final double averagePressure; // 0.0–1.0
  final int totalCharactersRecognized;
  final List<String> commonErrors;
  final int sessionDurationSeconds;

  WritingAnalytics copyWith({
    double? averageCharacterSize,
    double? writingSpeedCpm,
    double? consistencyScore,
    double? averageSlantAngle,
    double? averagePressure,
    int? totalCharactersRecognized,
    List<String>? commonErrors,
    int? sessionDurationSeconds,
  }) =>
      WritingAnalytics(
        averageCharacterSize: averageCharacterSize ?? this.averageCharacterSize,
        writingSpeedCpm: writingSpeedCpm ?? this.writingSpeedCpm,
        consistencyScore: consistencyScore ?? this.consistencyScore,
        averageSlantAngle: averageSlantAngle ?? this.averageSlantAngle,
        averagePressure: averagePressure ?? this.averagePressure,
        totalCharactersRecognized: totalCharactersRecognized ?? this.totalCharactersRecognized,
        commonErrors: commonErrors ?? this.commonErrors,
        sessionDurationSeconds: sessionDurationSeconds ?? this.sessionDurationSeconds,
      );

  @override
  List<Object?> get props => [
        averageCharacterSize,
        writingSpeedCpm,
        consistencyScore,
        averageSlantAngle,
        averagePressure,
        totalCharactersRecognized,
        commonErrors,
        sessionDurationSeconds,
      ];
}
