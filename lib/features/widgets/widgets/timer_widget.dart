import 'dart:async';

import 'package:flutter/material.dart';
import 'package:biscuitse/features/widgets/domain/entities/smart_widget.dart';

class TimerWidget extends SmartWidget {
  TimerWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(200, 160),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.timer,
          state: state ??
              const {
                'seconds': 0,
                'isRunning': false,
                'isCountdown': false,
                'targetSeconds': 300,
              },
        );

  @override
  String get label => 'Timer';
  @override
  String get iconEmoji => '⏱️';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      TimerWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _TimerOverlay(widget: this, onStateChanged: onStateChanged);
}

class _TimerOverlay extends StatefulWidget {
  const _TimerOverlay({required this.widget, required this.onStateChanged});
  final TimerWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_TimerOverlay> createState() => _TimerOverlayState();
}

class _TimerOverlayState extends State<_TimerOverlay> {
  late int _seconds;
  late bool _isRunning;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = widget.widget.state['seconds'] as int? ?? 0;
    _isRunning = widget.widget.state['isRunning'] as bool? ?? false;
    if (_isRunning) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      widget.onStateChanged({'seconds': _seconds, 'isRunning': true});
    });
    setState(() => _isRunning = true);
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    widget.onStateChanged({'seconds': _seconds, 'isRunning': false});
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isRunning = false;
    });
    widget.onStateChanged({'seconds': 0, 'isRunning': false});
  }

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⏱️ Timer',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                _format(_seconds),
                style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    onPressed: _isRunning ? _stop : _start,
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: _reset,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
