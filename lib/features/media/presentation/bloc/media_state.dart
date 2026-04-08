import 'package:equatable/equatable.dart';
import 'package:biscuits/features/media/domain/entities/media_element.dart';

/// Immutable state for the media feature.
class MediaState extends Equatable {
  const MediaState({
    this.elements = const [],
    this.selectedElementId,
    this.playbackState = PlaybackState.idle,
    this.positionMs = 0,
    this.durationMs = 0,
    this.volume = 1.0,
    this.errorMessage,
  });

  /// All media elements on the current page.
  final List<MediaElement> elements;

  /// ID of the currently selected/playing element.
  final String? selectedElementId;

  /// Current playback state.
  final PlaybackState playbackState;

  /// Current playback position in milliseconds.
  final int positionMs;

  /// Total duration of the active track in milliseconds.
  final int durationMs;

  /// Current volume (0.0–1.0).
  final double volume;

  /// Human-readable error message, if any.
  final String? errorMessage;

  /// The selected element, or `null`.
  MediaElement? get selectedElement {
    if (selectedElementId == null) return null;
    final matches = elements.where(
      (e) => e.id == selectedElementId,
    );
    return matches.isEmpty ? null : matches.first;
  }

  bool get isPlaying =>
      playbackState == PlaybackState.playing;

  bool get isPaused =>
      playbackState == PlaybackState.paused;

  bool get hasError =>
      playbackState == PlaybackState.error;

  /// Progress ratio 0.0–1.0.
  double get progress =>
      durationMs > 0 ? positionMs / durationMs : 0.0;

  MediaState copyWith({
    List<MediaElement>? elements,
    String? selectedElementId,
    bool clearSelection = false,
    PlaybackState? playbackState,
    int? positionMs,
    int? durationMs,
    double? volume,
    String? errorMessage,
    bool clearError = false,
  }) =>
      MediaState(
        elements: elements ?? this.elements,
        selectedElementId: clearSelection
            ? null
            : (selectedElementId ?? this.selectedElementId),
        playbackState:
            playbackState ?? this.playbackState,
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
        volume: volume ?? this.volume,
        errorMessage: clearError
            ? null
            : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        elements,
        selectedElementId,
        playbackState,
        positionMs,
        durationMs,
        volume,
        errorMessage,
      ];
}
