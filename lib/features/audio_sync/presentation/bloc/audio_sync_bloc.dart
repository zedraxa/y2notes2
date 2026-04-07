import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/audio_recording.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/stroke_timestamp.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/transcription_segment.dart';
import 'package:y2notes2/features/audio_sync/presentation/bloc/audio_sync_event.dart';
import 'package:y2notes2/features/audio_sync/presentation/bloc/audio_sync_state.dart';

/// BLoC that manages audio recording, playback, and
/// synchronisation with canvas strokes.
///
/// During recording a periodic timer tracks elapsed time
/// and strokes committed via [StrokeCommittedDuringRecording]
/// are tagged with the current offset.  During playback
/// the timer advances the position and the bloc emits
/// [highlightedStrokeIds] for the canvas to use.
class AudioSyncBloc
    extends Bloc<AudioSyncEvent, AudioSyncState> {
  AudioSyncBloc() : super(const AudioSyncState()) {
    on<AudioRecordingStarted>(_onRecordingStarted);
    on<AudioRecordingPaused>(_onRecordingPaused);
    on<AudioRecordingResumed>(_onRecordingResumed);
    on<AudioRecordingStopped>(_onRecordingStopped);
    on<StrokeCommittedDuringRecording>(
      _onStrokeCommitted,
    );
    on<AudioPlaybackStarted>(_onPlaybackStarted);
    on<AudioPlaybackPositionChanged>(
      _onPlaybackPositionChanged,
    );
    on<AudioPlaybackStopped>(_onPlaybackStopped);
    on<AudioPlaybackSeeked>(_onPlaybackSeeked);
    on<AudioRecordingDeleted>(_onRecordingDeleted);
    on<AudioRecordingRenamed>(_onRecordingRenamed);
    on<TranscriptionRequested>(_onTranscriptionRequested);
    on<TranscriptionCompleted>(_onTranscriptionCompleted);
    on<AudioRecordingsLoaded>(_onRecordingsLoaded);
  }

  Timer? _recordingTimer;
  Timer? _playbackTimer;
  DateTime? _recordingStartedAt;

  /// Stroke timestamps accumulated during the current
  /// recording session.
  final List<StrokeTimestamp> _pendingTimestamps = [];

  // ── Recording lifecycle ────────────────────────────

  void _onRecordingStarted(
    AudioRecordingStarted event,
    Emitter<AudioSyncState> emit,
  ) {
    _stopTimers();
    _pendingTimestamps.clear();
    _recordingStartedAt = DateTime.now();

    emit(state.copyWith(
      isRecording: true,
      isPaused: false,
      recordingElapsedMs: 0,
    ));

    _recordingTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (!state.isRecording || state.isPaused) return;
        final elapsed = DateTime.now()
            .difference(_recordingStartedAt!)
            .inMilliseconds;
        // ignore: invalid_use_of_visible_for_testing_member
        add(AudioPlaybackPositionChanged(
          positionMs: elapsed,
        ));
      },
    );
  }

  void _onRecordingPaused(
    AudioRecordingPaused event,
    Emitter<AudioSyncState> emit,
  ) {
    if (!state.isRecording) return;
    emit(state.copyWith(isPaused: true));
  }

  void _onRecordingResumed(
    AudioRecordingResumed event,
    Emitter<AudioSyncState> emit,
  ) {
    if (!state.isRecording || !state.isPaused) return;
    emit(state.copyWith(isPaused: false));
  }

  void _onRecordingStopped(
    AudioRecordingStopped event,
    Emitter<AudioSyncState> emit,
  ) {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    if (!state.isRecording) return;

    final elapsed = state.recordingElapsedMs;
    if (elapsed < 500) {
      // Too short — discard.
      _pendingTimestamps.clear();
      emit(state.copyWith(
        isRecording: false,
        isPaused: false,
        recordingElapsedMs: 0,
      ));
      return;
    }

    // Generate simulated waveform data.
    final rng = Random(DateTime.now().millisecond);
    final waveform = List<double>.generate(
      20,
      (_) => rng.nextDouble() * 0.8 + 0.2,
    );

    final recording = AudioRecording(
      durationMs: elapsed,
      strokeTimestamps:
          List<StrokeTimestamp>.from(_pendingTimestamps),
      label: 'Recording ${state.recordings.length + 1}',
      waveform: waveform,
    );

    _pendingTimestamps.clear();
    _recordingStartedAt = null;

    emit(state.copyWith(
      isRecording: false,
      isPaused: false,
      recordingElapsedMs: 0,
      recordings: [...state.recordings, recording],
    ));
  }

  // ── Stroke synchronisation ─────────────────────────

  void _onStrokeCommitted(
    StrokeCommittedDuringRecording event,
    Emitter<AudioSyncState> emit,
  ) {
    if (!state.isRecording || state.isPaused) return;

    final offset = _recordingStartedAt != null
        ? DateTime.now()
            .difference(_recordingStartedAt!)
            .inMilliseconds
        : state.recordingElapsedMs;

    _pendingTimestamps.add(StrokeTimestamp(
      strokeId: event.strokeId,
      offsetMs: offset,
    ));
  }

  // ── Playback ───────────────────────────────────────

  void _onPlaybackStarted(
    AudioPlaybackStarted event,
    Emitter<AudioSyncState> emit,
  ) {
    _stopPlaybackTimer();
    final idx = event.recordingIndex;
    if (idx < 0 || idx >= state.recordings.length) return;

    emit(state.copyWith(
      activePlaybackIndex: idx,
      playbackPositionMs: 0,
      highlightedStrokeIds: const {},
    ));

    final rec = state.recordings[idx];
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        final pos = state.playbackPositionMs + 100;
        if (pos >= rec.durationMs) {
          add(const AudioPlaybackStopped());
        } else {
          add(AudioPlaybackPositionChanged(
            positionMs: pos,
          ));
        }
      },
    );
  }

  void _onPlaybackPositionChanged(
    AudioPlaybackPositionChanged event,
    Emitter<AudioSyncState> emit,
  ) {
    // During recording, update elapsed time.
    if (state.isRecording) {
      emit(state.copyWith(
        recordingElapsedMs: event.positionMs,
      ));
      return;
    }

    // During playback, update position and highlighted
    // strokes.
    final rec = state.activePlaybackRecording;
    if (rec == null) return;

    // Highlight strokes written up to the current
    // playback position (within a 2-second window for
    // a fading highlight effect).
    const windowMs = 2000;
    final highlighted = rec.strokeTimestamps
        .where(
          (st) =>
              st.offsetMs <= event.positionMs &&
              st.offsetMs >
                  event.positionMs - windowMs,
        )
        .map((st) => st.strokeId)
        .toSet();

    emit(state.copyWith(
      playbackPositionMs: event.positionMs,
      highlightedStrokeIds: highlighted,
    ));
  }

  void _onPlaybackStopped(
    AudioPlaybackStopped event,
    Emitter<AudioSyncState> emit,
  ) {
    _stopPlaybackTimer();
    emit(state.copyWith(
      activePlaybackIndex: -1,
      playbackPositionMs: 0,
      highlightedStrokeIds: const {},
    ));
  }

  void _onPlaybackSeeked(
    AudioPlaybackSeeked event,
    Emitter<AudioSyncState> emit,
  ) {
    if (!state.isPlaying) return;
    add(AudioPlaybackPositionChanged(
      positionMs: event.positionMs,
    ));
  }

  // ── Recording management ───────────────────────────

  void _onRecordingDeleted(
    AudioRecordingDeleted event,
    Emitter<AudioSyncState> emit,
  ) {
    final idx = event.recordingIndex;
    if (idx < 0 || idx >= state.recordings.length) return;

    if (state.activePlaybackIndex == idx) {
      _stopPlaybackTimer();
    }

    final updated =
        List<AudioRecording>.from(state.recordings)
          ..removeAt(idx);

    emit(state.copyWith(
      recordings: updated,
      activePlaybackIndex:
          state.activePlaybackIndex == idx
              ? -1
              : state.activePlaybackIndex,
      playbackPositionMs:
          state.activePlaybackIndex == idx
              ? 0
              : state.playbackPositionMs,
      highlightedStrokeIds:
          state.activePlaybackIndex == idx
              ? const {}
              : state.highlightedStrokeIds,
    ));
  }

  void _onRecordingRenamed(
    AudioRecordingRenamed event,
    Emitter<AudioSyncState> emit,
  ) {
    final idx = event.recordingIndex;
    if (idx < 0 || idx >= state.recordings.length) return;

    final updated =
        List<AudioRecording>.from(state.recordings);
    updated[idx] = updated[idx].copyWith(
      label: event.label,
    );

    emit(state.copyWith(recordings: updated));
  }

  // ── Transcription ──────────────────────────────────

  void _onTranscriptionRequested(
    TranscriptionRequested event,
    Emitter<AudioSyncState> emit,
  ) {
    final idx = event.recordingIndex;
    if (idx < 0 || idx >= state.recordings.length) return;

    emit(state.copyWith(
      isTranscribing: true,
      transcribingIndex: idx,
    ));

    // Simulate async transcription with placeholder
    // segments.  A real implementation would call a
    // speech-to-text API here.
    final rec = state.recordings[idx];
    final segments = _generateSimulatedTranscription(
      rec.durationMs,
    );

    add(TranscriptionCompleted(
      recordingIndex: idx,
      segments: segments,
    ));
  }

  void _onTranscriptionCompleted(
    TranscriptionCompleted event,
    Emitter<AudioSyncState> emit,
  ) {
    final idx = event.recordingIndex;
    if (idx < 0 || idx >= state.recordings.length) return;

    final updated =
        List<AudioRecording>.from(state.recordings);
    updated[idx] = updated[idx].copyWith(
      transcriptionSegments: event.segments,
    );

    emit(state.copyWith(
      recordings: updated,
      isTranscribing: false,
      transcribingIndex: -1,
    ));
  }

  // ── Bulk load ──────────────────────────────────────

  void _onRecordingsLoaded(
    AudioRecordingsLoaded event,
    Emitter<AudioSyncState> emit,
  ) {
    // Ready for persistence; no-op for now.
  }

  // ── Helpers ────────────────────────────────────────

  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  void _stopTimers() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _stopPlaybackTimer();
  }

  /// Generates placeholder transcription segments.
  List<TranscriptionSegment> _generateSimulatedTranscription(
    int durationMs,
  ) {
    const phrases = [
      'Today we will discuss',
      'the main topic is',
      'as you can see here',
      'this is important because',
      'let me explain further',
      'in summary',
    ];

    final rng = Random(durationMs);
    final segmentCount =
        (durationMs / 5000).ceil().clamp(1, phrases.length);
    final segmentDuration = durationMs ~/ segmentCount;

    return List.generate(segmentCount, (i) {
      final start = i * segmentDuration;
      final end = (i + 1) * segmentDuration;
      return TranscriptionSegment(
        text: phrases[i % phrases.length],
        startMs: start,
        endMs: end.clamp(0, durationMs),
        confidence: 0.7 + rng.nextDouble() * 0.3,
      );
    });
  }

  @override
  Future<void> close() {
    _stopTimers();
    return super.close();
  }
}
