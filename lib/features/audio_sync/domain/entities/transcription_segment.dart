import 'package:equatable/equatable.dart';

/// A segment of AI-generated transcription tied to a
/// time range within an [AudioRecording].
class TranscriptionSegment extends Equatable {
  const TranscriptionSegment({
    required this.text,
    required this.startMs,
    required this.endMs,
    this.confidence = 1.0,
  });

  /// Transcribed text for this segment.
  final String text;

  /// Start offset in milliseconds from recording start.
  final int startMs;

  /// End offset in milliseconds from recording start.
  final int endMs;

  /// Confidence score from the speech-to-text engine
  /// (0.0–1.0).
  final double confidence;

  /// Duration of this segment in milliseconds.
  int get durationMs => endMs - startMs;

  Map<String, dynamic> toJson() => {
        'text': text,
        'startMs': startMs,
        'endMs': endMs,
        'confidence': confidence,
      };

  factory TranscriptionSegment.fromJson(
    Map<String, dynamic> json,
  ) =>
      TranscriptionSegment(
        text: json['text'] as String,
        startMs: json['startMs'] as int,
        endMs: json['endMs'] as int,
        confidence:
            (json['confidence'] as num?)?.toDouble() ??
                1.0,
      );

  @override
  List<Object?> get props =>
      [text, startMs, endMs, confidence];
}
