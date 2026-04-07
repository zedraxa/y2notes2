import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

/// Record/play audio note marker (stub for audio, visual waveform).
class VoiceNoteWidget extends SmartWidget {
  VoiceNoteWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(220, 80),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.voiceNote,
          state: state ??
              const {
                'hasRecording': false,
                'isPlaying': false,
                'durationSeconds': 0,
              },
        );

  @override
  String get label => 'Voice Note';
  @override
  String get iconEmoji => '🎙️';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      VoiceNoteWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _VoiceNoteOverlay(widget: this, onStateChanged: onStateChanged);
}

class _VoiceNoteOverlay extends StatefulWidget {
  const _VoiceNoteOverlay(
      {required this.widget, required this.onStateChanged});
  final VoiceNoteWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_VoiceNoteOverlay> createState() => _VoiceNoteOverlayState();
}

class _VoiceNoteOverlayState extends State<_VoiceNoteOverlay> {
  late bool _hasRecording;
  late bool _isPlaying;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _hasRecording = widget.widget.state['hasRecording'] as bool? ?? false;
    _isPlaying = widget.widget.state['isPlaying'] as bool? ?? false;
    _duration = widget.widget.state['durationSeconds'] as int? ?? 0;
  }

  void _notify() {
    widget.onStateChanged({
      'hasRecording': _hasRecording,
      'isPlaying': _isPlaying,
      'durationSeconds': _duration,
    });
  }

  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _hasRecording
                      ? (_isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill)
                      : Icons.mic,
                  color: _hasRecording ? Colors.blue : Colors.red,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    if (_hasRecording) {
                      _isPlaying = !_isPlaying;
                    } else {
                      _hasRecording = true;
                      _duration = 5; // Stub recording
                    }
                  });
                  _notify();
                },
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stub waveform
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CustomPaint(
                        painter: _WaveformPainter(
                          hasRecording: _hasRecording,
                        ),
                        size: const Size(double.infinity, 20),
                      ),
                    ),
                    if (_hasRecording)
                      Text('${_duration}s',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (_hasRecording)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _hasRecording = false;
                      _isPlaying = false;
                      _duration = 0;
                    });
                    _notify();
                  },
                ),
            ],
          ),
        ),
      );
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.hasRecording});
  final bool hasRecording;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = hasRecording ? Colors.blue.shade300 : Colors.grey.shade300
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final mid = size.height / 2;
    const count = 20;
    final step = size.width / count;
    for (int i = 0; i < count; i++) {
      final h = hasRecording ? (i % 3 + 1) * 3.0 : 2.0;
      canvas.drawLine(
        Offset(i * step + step / 2, mid - h),
        Offset(i * step + step / 2, mid + h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.hasRecording != hasRecording;
}
