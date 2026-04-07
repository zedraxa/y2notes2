import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/stroke_timestamp.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/transcription_segment.dart';

/// Status of an audio recording session.
enum RecordingStatus {
  idle,
  recording,
  paused,
  completed,
}

/// A single audio recording associated with a notebook page.
///
/// Stores metadata about the recording and the
/// stroke-timestamp mappings that enable synchronized
/// playback with handwritten notes.
class AudioRecording extends Equatable {
  AudioRecording({
    String? id,
    required this.durationMs,
    this.status = RecordingStatus.completed,
    this.strokeTimestamps = const [],
    this.transcriptionSegments = const [],
    this.label,
    this.waveform = const [],
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Unique identifier for this recording.
  final String id;

  /// Total duration of the recording in milliseconds.
  final int durationMs;

  /// Current status of this recording.
  final RecordingStatus status;

  /// Stroke-to-timestamp mappings captured during
  /// recording.
  final List<StrokeTimestamp> strokeTimestamps;

  /// AI-generated transcription segments.
  final List<TranscriptionSegment> transcriptionSegments;

  /// Optional user-assigned label.
  final String? label;

  /// Normalized waveform amplitudes (0.0–1.0) for
  /// visualisation.
  final List<double> waveform;

  /// When the recording was created.
  final DateTime createdAt;

  /// Duration formatted as m:ss.
  String get formattedDuration {
    final totalSeconds = durationMs ~/ 1000;
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  AudioRecording copyWith({
    int? durationMs,
    RecordingStatus? status,
    List<StrokeTimestamp>? strokeTimestamps,
    List<TranscriptionSegment>? transcriptionSegments,
    String? label,
    bool clearLabel = false,
    List<double>? waveform,
  }) =>
      AudioRecording(
        id: id,
        durationMs: durationMs ?? this.durationMs,
        status: status ?? this.status,
        strokeTimestamps:
            strokeTimestamps ?? this.strokeTimestamps,
        transcriptionSegments:
            transcriptionSegments ??
                this.transcriptionSegments,
        label: clearLabel
            ? null
            : (label ?? this.label),
        waveform: waveform ?? this.waveform,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'durationMs': durationMs,
        'status': status.name,
        'strokeTimestamps': strokeTimestamps
            .map((s) => s.toJson())
            .toList(),
        'transcriptionSegments': transcriptionSegments
            .map((t) => t.toJson())
            .toList(),
        'label': label,
        'waveform': waveform,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AudioRecording.fromJson(
    Map<String, dynamic> json,
  ) =>
      AudioRecording(
        id: json['id'] as String,
        durationMs: json['durationMs'] as int,
        status: RecordingStatus.values
            .byName(json['status'] as String),
        strokeTimestamps:
            (json['strokeTimestamps'] as List?)
                    ?.map(
                      (e) =>
                          StrokeTimestamp.fromJson(
                        e as Map<String, dynamic>,
                      ),
                    )
                    .toList() ??
                [],
        transcriptionSegments:
            (json['transcriptionSegments'] as List?)
                    ?.map(
                      (e) =>
                          TranscriptionSegment.fromJson(
                        e as Map<String, dynamic>,
                      ),
                    )
                    .toList() ??
                [],
        label: json['label'] as String?,
        waveform: (json['waveform'] as List?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [],
        createdAt:
            DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        durationMs,
        status,
        strokeTimestamps,
        transcriptionSegments,
        label,
        waveform,
        createdAt,
      ];
}
