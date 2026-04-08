import 'package:flutter/material.dart';
import 'package:biscuits/features/media/domain/entities/media_element.dart';

/// Bottom sheet that lets the user pick an audio or video
/// file to insert onto the canvas.
///
/// In production this would integrate with `file_picker` and
/// the device media gallery.  For now it surfaces the two
/// entry-points so the UI is wired end-to-end.
class MediaPickerPanel extends StatelessWidget {
  const MediaPickerPanel({
    super.key,
    required this.onSelected,
  });

  /// Called with a newly constructed [MediaElement] when
  /// the user picks a file.
  final void Function(MediaElement element) onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Row(
                children: [
                  Text(
                    'Insert Media',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _MediaOptionTile(
                    icon: Icons.audiotrack_rounded,
                    title: 'Audio File',
                    subtitle:
                        'Insert an audio recording '
                        'or music file',
                    onTap: () =>
                        _pickMedia(context, MediaType.audio),
                  ),
                  const SizedBox(height: 12),
                  _MediaOptionTile(
                    icon: Icons.videocam_rounded,
                    title: 'Video File',
                    subtitle:
                        'Insert a video clip',
                    onTap: () =>
                        _pickMedia(context, MediaType.video),
                  ),
                  const SizedBox(height: 12),
                  _MediaOptionTile(
                    icon: Icons.mic_rounded,
                    title: 'Record Audio',
                    subtitle:
                        'Record audio directly '
                        'from the microphone',
                    onTap: () => _pickMedia(
                      context,
                      MediaType.audio,
                      isRecording: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// Simulates file picking.  In production this would
  /// call `FilePicker` and create a real [MediaElement]
  /// from the result.
  void _pickMedia(
    BuildContext context,
    MediaType type, {
    bool isRecording = false,
  }) {
    final now = DateTime.now();
    final label = isRecording
        ? 'Recording ${now.hour}:${now.minute.toString().padLeft(2, '0')}'
        : type == MediaType.audio
            ? 'audio_sample.mp3'
            : 'video_sample.mp4';

    final element = MediaElement(
      type: type,
      filePath: '/media/$label',
      fileName: label,
      position: const Offset(100, 100),
      size: type == MediaType.audio
          ? const Size(280, 120)
          : const Size(320, 220),
      durationMs: type == MediaType.audio ? 45000 : 60000,
    );

    Navigator.of(context).pop();
    onSelected(element);
  }
}

class _MediaOptionTile extends StatelessWidget {
  const _MediaOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      );
}
