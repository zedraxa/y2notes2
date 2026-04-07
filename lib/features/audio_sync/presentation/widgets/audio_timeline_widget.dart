import 'package:flutter/material.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/audio_recording.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/stroke_timestamp.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/transcription_segment.dart';

/// Visualises the audio timeline for a single recording,
/// showing stroke markers and transcription segments.
///
/// Tapping a stroke marker invokes [onSeek] so the
/// caller can jump playback to that moment.
class AudioTimelineWidget extends StatelessWidget {
  const AudioTimelineWidget({
    super.key,
    required this.recording,
    required this.playbackProgress,
    required this.isPlaying,
    this.highlightedStrokeIds = const {},
    this.onSeek,
    this.height = 64,
  });

  final AudioRecording recording;
  final double playbackProgress;
  final bool isPlaying;
  final Set<String> highlightedStrokeIds;
  final ValueChanged<int>? onSeek;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              onTapDown: (details) =>
                  _handleTap(details, width),
              child: CustomPaint(
                painter: _TimelinePainter(
                  recording: recording,
                  progress: playbackProgress,
                  isPlaying: isPlaying,
                  highlightedStrokeIds:
                      highlightedStrokeIds,
                ),
                size: Size(width, height),
              ),
            );
          },
        ),
      );

  void _handleTap(
    TapDownDetails details,
    double totalWidth,
  ) {
    if (onSeek == null || recording.durationMs == 0) {
      return;
    }
    final fraction =
        (details.localPosition.dx / totalWidth)
            .clamp(0.0, 1.0);
    onSeek!((fraction * recording.durationMs).round());
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.recording,
    required this.progress,
    required this.isPlaying,
    required this.highlightedStrokeIds,
  });

  final AudioRecording recording;
  final double progress;
  final bool isPlaying;
  final Set<String> highlightedStrokeIds;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWaveform(canvas, size);
    _drawStrokeMarkers(canvas, size);
    _drawTranscription(canvas, size);
    if (isPlaying) {
      _drawPlayhead(canvas, size);
    }
  }

  void _drawWaveform(Canvas canvas, Size size) {
    final waveform = recording.waveform;
    if (waveform.isEmpty) return;

    final mid = size.height * 0.35;
    final step = size.width / waveform.length;
    final playheadX = progress * size.width;

    for (var i = 0; i < waveform.length; i++) {
      final x = i * step + step / 2;
      final h = waveform[i] * (mid - 2);
      final isActive = x <= playheadX;
      final paint = Paint()
        ..color = isActive
            ? Colors.blue
            : Colors.grey.shade300
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, mid - h),
        Offset(x, mid + h),
        paint,
      );
    }
  }

  void _drawStrokeMarkers(Canvas canvas, Size size) {
    if (recording.durationMs == 0) return;

    final markerY = size.height * 0.35;
    for (final StrokeTimestamp st
        in recording.strokeTimestamps) {
      final x = (st.offsetMs / recording.durationMs) *
          size.width;
      final isHighlighted =
          highlightedStrokeIds.contains(st.strokeId);
      final paint = Paint()
        ..color = isHighlighted
            ? Colors.orange
            : Colors.blue.shade200
        ..strokeWidth = isHighlighted ? 3.0 : 1.5;

      canvas.drawLine(
        Offset(x, markerY - 6),
        Offset(x, markerY + 6),
        paint,
      );

      // Small triangle marker.
      final path = Path()
        ..moveTo(x - 3, markerY - 8)
        ..lineTo(x + 3, markerY - 8)
        ..lineTo(x, markerY - 4)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = isHighlighted
              ? Colors.orange
              : Colors.blue.shade300,
      );
    }
  }

  void _drawTranscription(Canvas canvas, Size size) {
    if (recording.durationMs == 0) return;

    final segments = recording.transcriptionSegments;
    if (segments.isEmpty) return;

    final textY = size.height * 0.75;

    for (final TranscriptionSegment seg in segments) {
      final startX =
          (seg.startMs / recording.durationMs) *
              size.width;
      final endX =
          (seg.endMs / recording.durationMs) *
              size.width;
      final segWidth = (endX - startX).clamp(20.0, 200.0);

      // Background bar.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX,
            textY - 8,
            segWidth,
            16,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.blue.withAlpha(25),
      );

      // Text.
      final tp = TextPainter(
        text: TextSpan(
          text: seg.text,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade600,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: segWidth - 4);
      tp.paint(canvas, Offset(startX + 2, textY - 6));
    }
  }

  void _drawPlayhead(Canvas canvas, Size size) {
    final x = progress * size.width;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 1.5,
    );
    // Playhead handle.
    canvas.drawCircle(
      Offset(x, 4),
      4,
      Paint()..color = Colors.red,
    );
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.progress != progress ||
      old.isPlaying != isPlaying ||
      old.highlightedStrokeIds !=
          highlightedStrokeIds ||
      old.recording != recording;
}
