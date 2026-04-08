import 'package:biscuits/features/media/domain/entities/media_element.dart';

/// Lightweight abstraction over platform media playback.
///
/// In a production app this would wrap a real player plugin
/// (e.g. `just_audio`, `video_player`).  For now it provides
/// the control surface so the BLoC/UI layers are wired up and
/// ready for a real backend.
class MediaPlayerEngine {
  const MediaPlayerEngine();

  /// Simulates starting playback of the given [element].
  ///
  /// Returns the element's known duration (or a default) so
  /// the caller can initialise progress tracking.
  Future<int> play(MediaElement element) async {
    // Stub: in production, delegate to platform player.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return element.durationMs > 0 ? element.durationMs : 30000;
  }

  /// Pauses the currently playing media.
  Future<void> pause() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  /// Resumes playback after a pause.
  Future<void> resume() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  /// Stops playback entirely and resets position.
  Future<void> stop() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  /// Seeks to [positionMs] within the current track.
  Future<void> seek(int positionMs) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  /// Sets the playback volume (0.0–1.0).
  Future<void> setVolume(double volume) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  /// Releases all platform resources.
  Future<void> dispose() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
