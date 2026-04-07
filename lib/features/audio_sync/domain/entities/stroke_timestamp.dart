import 'package:equatable/equatable.dart';

/// Maps a stroke to a specific moment in an audio
/// recording.
///
/// When the user draws while recording, each committed
/// stroke receives a [StrokeTimestamp] that records:
/// - The stroke's unique ID
/// - The offset (in ms) from the recording start
///
/// During playback, strokes whose [offsetMs] falls
/// within the current playback position can be
/// highlighted on the canvas.
class StrokeTimestamp extends Equatable {
  const StrokeTimestamp({
    required this.strokeId,
    required this.offsetMs,
  });

  /// ID of the associated [Stroke].
  final String strokeId;

  /// Milliseconds from the start of the recording when
  /// this stroke was committed.
  final int offsetMs;

  Map<String, dynamic> toJson() => {
        'strokeId': strokeId,
        'offsetMs': offsetMs,
      };

  factory StrokeTimestamp.fromJson(
    Map<String, dynamic> json,
  ) =>
      StrokeTimestamp(
        strokeId: json['strokeId'] as String,
        offsetMs: json['offsetMs'] as int,
      );

  @override
  List<Object?> get props => [strokeId, offsetMs];
}
