import 'package:equatable/equatable.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/audio_recording.dart';

/// Immutable snapshot of the audio sync feature state.
class AudioSyncState extends Equatable {
  const AudioSyncState({
    this.recordings = const [],
    this.isRecording = false,
    this.isPaused = false,
    this.recordingElapsedMs = 0,
    this.activePlaybackIndex = -1,
    this.playbackPositionMs = 0,
    this.highlightedStrokeIds = const {},
    this.isTranscribing = false,
    this.transcribingIndex = -1,
  });

  /// All recordings on the current page.
  final List<AudioRecording> recordings;

  /// Whether a recording session is active.
  final bool isRecording;

  /// Whether the active recording session is paused.
  final bool isPaused;

  /// Elapsed milliseconds since recording started.
  final int recordingElapsedMs;

  /// Index of the recording currently being played,
  /// or -1 if nothing is playing.
  final int activePlaybackIndex;

  /// Current playback position in milliseconds.
  final int playbackPositionMs;

  /// Stroke IDs that should be highlighted on the
  /// canvas at the current playback position.
  final Set<String> highlightedStrokeIds;

  /// Whether a transcription request is in progress.
  final bool isTranscribing;

  /// Index of the recording being transcribed.
  final int transcribingIndex;

  /// Whether audio is currently playing.
  bool get isPlaying => activePlaybackIndex >= 0;

  /// The recording that is currently playing, if any.
  AudioRecording? get activePlaybackRecording =>
      isPlaying ? recordings[activePlaybackIndex] : null;

  /// Playback progress as a fraction (0.0–1.0).
  double get playbackProgress {
    final rec = activePlaybackRecording;
    if (rec == null || rec.durationMs == 0) return 0;
    return (playbackPositionMs / rec.durationMs)
        .clamp(0.0, 1.0);
  }

  AudioSyncState copyWith({
    List<AudioRecording>? recordings,
    bool? isRecording,
    bool? isPaused,
    int? recordingElapsedMs,
    int? activePlaybackIndex,
    int? playbackPositionMs,
    Set<String>? highlightedStrokeIds,
    bool? isTranscribing,
    int? transcribingIndex,
  }) =>
      AudioSyncState(
        recordings: recordings ?? this.recordings,
        isRecording: isRecording ?? this.isRecording,
        isPaused: isPaused ?? this.isPaused,
        recordingElapsedMs:
            recordingElapsedMs ?? this.recordingElapsedMs,
        activePlaybackIndex:
            activePlaybackIndex ??
                this.activePlaybackIndex,
        playbackPositionMs:
            playbackPositionMs ?? this.playbackPositionMs,
        highlightedStrokeIds:
            highlightedStrokeIds ??
                this.highlightedStrokeIds,
        isTranscribing:
            isTranscribing ?? this.isTranscribing,
        transcribingIndex:
            transcribingIndex ?? this.transcribingIndex,
      );

  @override
  List<Object?> get props => [
        recordings,
        isRecording,
        isPaused,
        recordingElapsedMs,
        activePlaybackIndex,
        playbackPositionMs,
        highlightedStrokeIds,
        isTranscribing,
        transcribingIndex,
      ];
}
