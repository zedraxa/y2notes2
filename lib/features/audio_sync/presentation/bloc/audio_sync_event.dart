import 'package:equatable/equatable.dart';
import 'package:biscuits/features/audio_sync/domain/entities/transcription_segment.dart';

/// Base class for all audio sync events.
abstract class AudioSyncEvent extends Equatable {
  const AudioSyncEvent();

  @override
  List<Object?> get props => [];
}

// ── Recording lifecycle ──────────────────────────────

/// Start a new synchronized recording session.
class AudioRecordingStarted extends AudioSyncEvent {
  const AudioRecordingStarted();
}

/// Pause the current recording.
class AudioRecordingPaused extends AudioSyncEvent {
  const AudioRecordingPaused();
}

/// Resume a paused recording.
class AudioRecordingResumed extends AudioSyncEvent {
  const AudioRecordingResumed();
}

/// Stop and finalize the current recording.
class AudioRecordingStopped extends AudioSyncEvent {
  const AudioRecordingStopped();
}

// ── Stroke synchronisation ───────────────────────────

/// Register a stroke committed while recording.
///
/// The bloc computes the offset from recording start
/// and stores a [StrokeTimestamp] entry.
class StrokeCommittedDuringRecording
    extends AudioSyncEvent {
  const StrokeCommittedDuringRecording({
    required this.strokeId,
  });

  final String strokeId;

  @override
  List<Object?> get props => [strokeId];
}

// ── Playback ─────────────────────────────────────────

/// Start playing back a specific recording by index.
class AudioPlaybackStarted extends AudioSyncEvent {
  const AudioPlaybackStarted({
    required this.recordingIndex,
  });

  final int recordingIndex;

  @override
  List<Object?> get props => [recordingIndex];
}

/// Update the current playback position (driven by a
/// timer during simulated playback).
class AudioPlaybackPositionChanged
    extends AudioSyncEvent {
  const AudioPlaybackPositionChanged({
    required this.positionMs,
  });

  final int positionMs;

  @override
  List<Object?> get props => [positionMs];
}

/// Update the recording elapsed time (driven by a
/// timer during recording).
class RecordingElapsedTimeUpdated
    extends AudioSyncEvent {
  const RecordingElapsedTimeUpdated({
    required this.elapsedMs,
  });

  final int elapsedMs;

  @override
  List<Object?> get props => [elapsedMs];
}

/// Stop the current playback.
class AudioPlaybackStopped extends AudioSyncEvent {
  const AudioPlaybackStopped();
}

/// Seek to a specific position in the recording.
class AudioPlaybackSeeked extends AudioSyncEvent {
  const AudioPlaybackSeeked({required this.positionMs});

  final int positionMs;

  @override
  List<Object?> get props => [positionMs];
}

// ── Recording management ─────────────────────────────

/// Delete a recording by index.
class AudioRecordingDeleted extends AudioSyncEvent {
  const AudioRecordingDeleted({
    required this.recordingIndex,
  });

  final int recordingIndex;

  @override
  List<Object?> get props => [recordingIndex];
}

/// Rename a recording.
class AudioRecordingRenamed extends AudioSyncEvent {
  const AudioRecordingRenamed({
    required this.recordingIndex,
    required this.label,
  });

  final int recordingIndex;
  final String label;

  @override
  List<Object?> get props => [recordingIndex, label];
}

// ── Transcription ────────────────────────────────────

/// Request AI transcription for a recording.
class TranscriptionRequested extends AudioSyncEvent {
  const TranscriptionRequested({
    required this.recordingIndex,
  });

  final int recordingIndex;

  @override
  List<Object?> get props => [recordingIndex];
}

/// Transcription completed — store results.
class TranscriptionCompleted extends AudioSyncEvent {
  const TranscriptionCompleted({
    required this.recordingIndex,
    required this.segments,
  });

  final int recordingIndex;
  final List<TranscriptionSegment> segments;

  @override
  List<Object?> get props => [recordingIndex, segments];
}

// ── Bulk load ────────────────────────────────────────

/// Load recordings from a notebook page.
class AudioRecordingsLoaded extends AudioSyncEvent {
  const AudioRecordingsLoaded();
}
