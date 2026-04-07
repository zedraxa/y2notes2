import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:y2notes2/features/media/domain/entities/media_element.dart';

/// Base class for all media-feature events.
abstract class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object?> get props => [];
}

// ── Element management ──────────────────────────────────────────

/// Add a new media element to the canvas.
class MediaAdded extends MediaEvent {
  const MediaAdded(this.element);
  final MediaElement element;
  @override
  List<Object?> get props => [element];
}

/// Remove a media element by ID.
class MediaRemoved extends MediaEvent {
  const MediaRemoved(this.elementId);
  final String elementId;
  @override
  List<Object?> get props => [elementId];
}

/// Replace an existing element with an updated copy.
class MediaUpdated extends MediaEvent {
  const MediaUpdated(this.element);
  final MediaElement element;
  @override
  List<Object?> get props => [element];
}

/// Move a media element to a new canvas position.
class MediaMoved extends MediaEvent {
  const MediaMoved({
    required this.elementId,
    required this.position,
  });
  final String elementId;
  final Offset position;
  @override
  List<Object?> get props => [elementId, position];
}

/// Resize a media element.
class MediaResized extends MediaEvent {
  const MediaResized({
    required this.elementId,
    required this.size,
  });
  final String elementId;
  final Size size;
  @override
  List<Object?> get props => [elementId, size];
}

// ── Selection ───────────────────────────────────────────────────

/// Select a media element for playback or editing.
class MediaSelected extends MediaEvent {
  const MediaSelected(this.elementId);
  final String elementId;
  @override
  List<Object?> get props => [elementId];
}

/// Deselect the currently selected media element.
class MediaDeselected extends MediaEvent {
  const MediaDeselected();
}

// ── Playback ────────────────────────────────────────────────────

/// Start or resume playback of the selected element.
class MediaPlayRequested extends MediaEvent {
  const MediaPlayRequested();
}

/// Pause playback.
class MediaPauseRequested extends MediaEvent {
  const MediaPauseRequested();
}

/// Stop playback and reset position.
class MediaStopRequested extends MediaEvent {
  const MediaStopRequested();
}

/// Seek to a specific position (in milliseconds).
class MediaSeekRequested extends MediaEvent {
  const MediaSeekRequested(this.positionMs);
  final int positionMs;
  @override
  List<Object?> get props => [positionMs];
}

/// Change the playback volume (0.0–1.0).
class MediaVolumeChanged extends MediaEvent {
  const MediaVolumeChanged(this.volume);
  final double volume;
  @override
  List<Object?> get props => [volume];
}

// ── Bulk operations ─────────────────────────────────────────────

/// Load a list of media elements (e.g. from persistence).
class MediaElementsLoaded extends MediaEvent {
  const MediaElementsLoaded(this.elements);
  final List<MediaElement> elements;
  @override
  List<Object?> get props => [elements];
}
