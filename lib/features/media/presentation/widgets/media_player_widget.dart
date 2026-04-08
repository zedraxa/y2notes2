import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/media/domain/entities/media_element.dart';
import 'package:biscuits/features/media/presentation/bloc/media_bloc.dart';
import 'package:biscuits/features/media/presentation/bloc/media_event.dart';
import 'package:biscuits/features/media/presentation/bloc/media_state.dart';

/// Inline media player widget rendered on the canvas.
///
/// Shows a compact audio waveform bar for audio elements or a
/// placeholder thumbnail area for video elements, together with
/// play/pause, stop, seek-bar, and volume controls.
class MediaPlayerWidget extends StatelessWidget {
  const MediaPlayerWidget({
    super.key,
    required this.element,
  });

  final MediaElement element;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MediaBloc, MediaState>(
        builder: (context, state) {
          final isSelected =
              state.selectedElementId == element.id;
          final isActive =
              isSelected && state.isPlaying;

          return GestureDetector(
            onTap: () {
              context
                  .read<MediaBloc>()
                  .add(MediaSelected(element.id));
            },
            child: Container(
              width: element.size.width,
              height: element.size.height,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(60),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // ── Preview area ──────────────────────
                  Expanded(
                    child: _MediaPreview(
                      element: element,
                      isPlaying: isActive,
                    ),
                  ),
                  // ── Controls ──────────────────────────
                  if (isSelected) ...[
                    const Divider(height: 1),
                    _PlaybackControls(
                      state: state,
                      element: element,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
}

/// Preview section: icon/waveform for audio, thumbnail
/// for video.
class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.element,
    required this.isPlaying,
  });

  final MediaElement element;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final icon = element.isAudio
        ? Icons.audiotrack_rounded
        : Icons.videocam_rounded;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: isPlaying
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          const SizedBox(height: 4),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              element.fileName ??
                  element.filePath
                      .split(RegExp(r'[/\\]'))
                      .last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ),
          if (element.durationMs > 0)
            Text(
              element.durationLabel,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

/// Playback control bar with play/pause, stop,
/// seek slider, and volume.
class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.state,
    required this.element,
  });

  final MediaState state;
  final MediaElement element;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MediaBloc>();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Seek bar ─────────────────────────────
          if (state.durationMs > 0)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
              ),
              child: Slider(
                value: state.positionMs
                    .clamp(0, state.durationMs)
                    .toDouble(),
                max: state.durationMs.toDouble(),
                onChanged: (v) => bloc.add(
                  MediaSeekRequested(v.toInt()),
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              // ── Play / Pause ────────────────────
              IconButton(
                icon: Icon(
                  state.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                iconSize: 28,
                onPressed: () {
                  if (state.isPlaying) {
                    bloc.add(
                      const MediaPauseRequested(),
                    );
                  } else {
                    bloc.add(
                      const MediaPlayRequested(),
                    );
                  }
                },
                tooltip: state.isPlaying
                    ? 'Pause'
                    : 'Play',
              ),
              // ── Stop ────────────────────────────
              IconButton(
                icon: const Icon(
                  Icons.stop_rounded,
                ),
                iconSize: 24,
                onPressed: state.isPlaying ||
                        state.isPaused
                    ? () => bloc.add(
                          const MediaStopRequested(),
                        )
                    : null,
                tooltip: 'Stop',
              ),
              const SizedBox(width: 4),
              // ── Volume ──────────────────────────
              Icon(
                state.volume > 0
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                size: 18,
                color: Colors.grey,
              ),
              SizedBox(
                width: 80,
                child: Slider(
                  value: state.volume,
                  onChanged: (v) => bloc.add(
                    MediaVolumeChanged(v),
                  ),
                ),
              ),
              // ── Delete ──────────────────────────
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                ),
                onPressed: () => bloc.add(
                  MediaRemoved(element.id),
                ),
                tooltip: 'Remove',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
