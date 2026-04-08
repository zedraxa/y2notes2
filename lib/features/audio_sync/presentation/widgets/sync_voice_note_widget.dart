import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/audio_sync/domain/entities/audio_recording.dart';
import 'package:biscuits/features/audio_sync/presentation/bloc/audio_sync_bloc.dart';
import 'package:biscuits/features/audio_sync/presentation/bloc/audio_sync_event.dart';
import 'package:biscuits/features/audio_sync/presentation/bloc/audio_sync_state.dart';
import 'package:biscuits/features/audio_sync/presentation/widgets/audio_timeline_widget.dart';

/// Enhanced voice-note widget with stroke-synchronised
/// recording and timeline playback.
///
/// Unlike the basic [VoiceNoteWidget], this widget
/// integrates with [AudioSyncBloc] to:
/// 1. Time-stamp strokes during recording.
/// 2. Highlight strokes during playback.
/// 3. Display a visual timeline with stroke markers.
/// 4. Offer AI transcription.
class SyncVoiceNoteWidget extends StatelessWidget {
  const SyncVoiceNoteWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AudioSyncBloc, AudioSyncState>(
        builder: (context, state) => Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, state),
                const SizedBox(height: 6),
                Expanded(
                  child: _buildBody(context, state),
                ),
                const SizedBox(height: 4),
                _buildRecordButton(context, state),
              ],
            ),
          ),
        ),
      );

  Widget _buildHeader(
    BuildContext context,
    AudioSyncState state,
  ) =>
      Row(
        children: [
          const Text(
            '🎙️ Sync Voice Notes',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (state.isRecording)
            _RecordingIndicator(
              elapsedMs: state.recordingElapsedMs,
              isPaused: state.isPaused,
            )
          else
            Text(
              '${state.recordings.length} clip'
              '${state.recordings.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      );

  Widget _buildBody(
    BuildContext context,
    AudioSyncState state,
  ) {
    if (state.recordings.isEmpty && !state.isRecording) {
      return Center(
        child: Text(
          'Tap record to start\n'
          'Strokes will be time-stamped',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return ListView(
      children: [
        if (state.isRecording) _buildRecordingRow(state),
        ...state.recordings.asMap().entries.map(
              (e) => _RecordingTile(
                index: e.key,
                recording: e.value,
                isPlaying:
                    state.activePlaybackIndex == e.key,
                playbackProgress: state.isPlaying &&
                        state.activePlaybackIndex ==
                            e.key
                    ? state.playbackProgress
                    : 0,
                highlightedStrokeIds:
                    state.highlightedStrokeIds,
                isTranscribing:
                    state.isTranscribing &&
                        state.transcribingIndex == e.key,
              ),
            ),
      ],
    );
  }

  Widget _buildRecordingRow(AudioSyncState state) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              state.isPaused
                  ? 'Paused '
                  : 'Recording... ',
              style: TextStyle(
                fontSize: 12,
                color: state.isPaused
                    ? Colors.orange
                    : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _formatMs(state.recordingElapsedMs),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildRecordButton(
    BuildContext context,
    AudioSyncState state,
  ) {
    final bloc = context.read<AudioSyncBloc>();

    if (state.isRecording) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pause / Resume
          GestureDetector(
            onTap: () => state.isPaused
                ? bloc.add(
                    const AudioRecordingResumed(),
                  )
                : bloc.add(
                    const AudioRecordingPaused(),
                  ),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.shade100,
                border: Border.all(
                  color: Colors.orange,
                  width: 2,
                ),
              ),
              child: Icon(
                state.isPaused
                    ? Icons.play_arrow
                    : Icons.pause,
                color: Colors.orange,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Stop
          GestureDetector(
            onTap: () => bloc.add(
              const AudioRecordingStopped(),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                border: Border.all(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.stop,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () =>
          bloc.add(const AudioRecordingStarted()),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade100,
          border: Border.all(
            color: Colors.red,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.red,
          size: 20,
        ),
      ),
    );
  }

  static String _formatMs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ── Recording indicator ──────────────────────────────

class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator({
    required this.elapsedMs,
    required this.isPaused,
  });

  final int elapsedMs;
  final bool isPaused;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isPaused
                  ? Colors.orange
                  : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            SyncVoiceNoteWidget._formatMs(elapsedMs),
            style: TextStyle(
              fontSize: 10,
              color: isPaused
                  ? Colors.orange
                  : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

// ── Single recording tile ────────────────────────────

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({
    required this.index,
    required this.recording,
    required this.isPlaying,
    required this.playbackProgress,
    required this.highlightedStrokeIds,
    required this.isTranscribing,
  });

  final int index;
  final AudioRecording recording;
  final bool isPlaying;
  final double playbackProgress;
  final Set<String> highlightedStrokeIds;
  final bool isTranscribing;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AudioSyncBloc>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: () => isPlaying
                    ? bloc.add(
                        const AudioPlaybackStopped(),
                      )
                    : bloc.add(AudioPlaybackStarted(
                        recordingIndex: index,
                      )),
                child: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  recording.label ?? 'Recording',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Stroke count badge
              if (recording
                  .strokeTimestamps.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${recording.strokeTimestamps.length}'
                    ' ✏️',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                recording.formattedDuration,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              // Transcribe button
              GestureDetector(
                onTap: isTranscribing
                    ? null
                    : () => bloc.add(
                          TranscriptionRequested(
                            recordingIndex: index,
                          ),
                        ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 4),
                  child: isTranscribing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 1.5,
                          ),
                        )
                      : Icon(
                          Icons.text_snippet_outlined,
                          size: 14,
                          color: recording
                                  .transcriptionSegments
                                  .isNotEmpty
                              ? Colors.green
                              : Colors.grey.shade400,
                        ),
                ),
              ),
              // Delete button
              GestureDetector(
                onTap: () => bloc.add(
                  AudioRecordingDeleted(
                    recordingIndex: index,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
          // ── Timeline ───────────────────────────────
          const SizedBox(height: 4),
          AudioTimelineWidget(
            recording: recording,
            playbackProgress: playbackProgress,
            isPlaying: isPlaying,
            highlightedStrokeIds:
                highlightedStrokeIds,
            onSeek: isPlaying
                ? (ms) => bloc.add(
                      AudioPlaybackSeeked(
                        positionMs: ms,
                      ),
                    )
                : null,
            height: 48,
          ),
          // ── Transcription ──────────────────────────
          if (recording
              .transcriptionSegments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                recording.transcriptionSegments
                    .map((s) => s.text)
                    .join(' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
