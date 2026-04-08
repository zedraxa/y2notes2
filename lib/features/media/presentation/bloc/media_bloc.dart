import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/media/domain/entities/media_element.dart';
import 'package:y2notes2/features/media/engine/media_player_engine.dart';
import 'package:y2notes2/features/media/presentation/bloc/media_event.dart';
import 'package:y2notes2/features/media/presentation/bloc/media_state.dart';

/// BLoC managing media elements and playback state.
class MediaBloc extends Bloc<MediaEvent, MediaState> {
  MediaBloc({
    MediaPlayerEngine? playerEngine,
  })  : _player = playerEngine ?? const MediaPlayerEngine(),
        super(const MediaState()) {
    on<MediaAdded>(_onAdded);
    on<MediaRemoved>(_onRemoved);
    on<MediaUpdated>(_onUpdated);
    on<MediaMoved>(_onMoved);
    on<MediaResized>(_onResized);
    on<MediaSelected>(_onSelected);
    on<MediaDeselected>(_onDeselected);
    on<MediaPlayRequested>(_onPlay);
    on<MediaPauseRequested>(_onPause);
    on<MediaStopRequested>(_onStop);
    on<MediaSeekRequested>(_onSeek);
    on<MediaVolumeChanged>(_onVolumeChanged);
    on<MediaElementsLoaded>(_onLoaded);
  }

  final MediaPlayerEngine _player;

  // ── Element CRUD ──────────────────────────────────

  void _onAdded(
    MediaAdded event,
    Emitter<MediaState> emit,
  ) {
    emit(state.copyWith(
      elements: [...state.elements, event.element],
      selectedElementId: event.element.id,
    ));
  }

  void _onRemoved(
    MediaRemoved event,
    Emitter<MediaState> emit,
  ) {
    final wasSelected =
        state.selectedElementId == event.elementId;
    emit(state.copyWith(
      elements: state.elements
          .where((e) => e.id != event.elementId)
          .toList(),
      clearSelection: wasSelected,
      playbackState:
          wasSelected ? PlaybackState.idle : null,
    ));
  }

  void _onUpdated(
    MediaUpdated event,
    Emitter<MediaState> emit,
  ) {
    final updated = state.elements.map((e) {
      return e.id == event.element.id ? event.element : e;
    }).toList();
    emit(state.copyWith(elements: updated));
  }

  void _onMoved(
    MediaMoved event,
    Emitter<MediaState> emit,
  ) {
    final updated = state.elements.map((e) {
      if (e.id != event.elementId) return e;
      return e.copyWith(position: event.position);
    }).toList();
    emit(state.copyWith(elements: updated));
  }

  void _onResized(
    MediaResized event,
    Emitter<MediaState> emit,
  ) {
    final updated = state.elements.map((e) {
      if (e.id != event.elementId) return e;
      return e.copyWith(size: event.size);
    }).toList();
    emit(state.copyWith(elements: updated));
  }

  // ── Selection ─────────────────────────────────────

  Future<void> _onSelected(
    MediaSelected event,
    Emitter<MediaState> emit,
  ) async {
    // Stop any ongoing playback when switching elements.
    if (state.isPlaying || state.isPaused) {
      await _player.stop();
    }
    emit(state.copyWith(
      selectedElementId: event.elementId,
      playbackState: PlaybackState.idle,
      positionMs: 0,
    ));
  }

  Future<void> _onDeselected(
    MediaDeselected event,
    Emitter<MediaState> emit,
  ) async {
    if (state.isPlaying || state.isPaused) {
      await _player.stop();
    }
    emit(state.copyWith(
      clearSelection: true,
      playbackState: PlaybackState.idle,
      positionMs: 0,
    ));
  }

  // ── Playback ──────────────────────────────────────

  Future<void> _onPlay(
    MediaPlayRequested event,
    Emitter<MediaState> emit,
  ) async {
    final element = state.selectedElement;
    if (element == null) return;

    try {
      if (state.isPaused) {
        await _player.resume();
        emit(state.copyWith(
          playbackState: PlaybackState.playing,
        ));
      } else {
        final durationMs = await _player.play(element);
        emit(state.copyWith(
          playbackState: PlaybackState.playing,
          durationMs: durationMs,
          positionMs: 0,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        errorMessage: 'Playback failed: $e',
      ));
    }
  }

  Future<void> _onPause(
    MediaPauseRequested event,
    Emitter<MediaState> emit,
  ) async {
    if (!state.isPlaying) return;
    try {
      await _player.pause();
      emit(state.copyWith(
        playbackState: PlaybackState.paused,
      ));
    } catch (e) {
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        errorMessage: 'Pause failed: $e',
      ));
    }
  }

  Future<void> _onStop(
    MediaStopRequested event,
    Emitter<MediaState> emit,
  ) async {
    try {
      await _player.stop();
      emit(state.copyWith(
        playbackState: PlaybackState.stopped,
        positionMs: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        errorMessage: 'Stop failed: $e',
      ));
    }
  }

  Future<void> _onSeek(
    MediaSeekRequested event,
    Emitter<MediaState> emit,
  ) async {
    try {
      await _player.seek(event.positionMs);
      emit(state.copyWith(positionMs: event.positionMs));
    } catch (e) {
      emit(state.copyWith(
        playbackState: PlaybackState.error,
        errorMessage: 'Seek failed: $e',
      ));
    }
  }

  Future<void> _onVolumeChanged(
    MediaVolumeChanged event,
    Emitter<MediaState> emit,
  ) async {
    final clamped = event.volume.clamp(0.0, 1.0);
    try {
      await _player.setVolume(clamped);
      emit(state.copyWith(volume: clamped));
    } catch (e) {
      // Volume change failure is non-fatal.
      emit(state.copyWith(volume: clamped));
    }
  }

  void _onLoaded(
    MediaElementsLoaded event,
    Emitter<MediaState> emit,
  ) {
    emit(state.copyWith(elements: event.elements));
  }

  @override
  Future<void> close() async {
    await _player.dispose();
    return super.close();
  }
}
