import 'dart:async';

import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

/// Pomodoro timer — 25 min work / 5 min break with session counter.
class PomodoroWidget extends SmartWidget {
  PomodoroWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(200, 200),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.stickyTimer,
          state: state ??
              const {
                'seconds': 1500, // 25 min
                'isRunning': false,
                'isWork': true,
                'sessions': 0,
              },
        );

  @override
  String get label => 'Pomodoro';
  @override
  String get iconEmoji => '🍅';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      PomodoroWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _PomodoroOverlay(widget: this, onStateChanged: onStateChanged);
}

class _PomodoroOverlay extends StatefulWidget {
  const _PomodoroOverlay(
      {required this.widget, required this.onStateChanged});
  final PomodoroWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_PomodoroOverlay> createState() => _PomodoroOverlayState();
}

class _PomodoroOverlayState extends State<_PomodoroOverlay> {
  late int _seconds;
  late bool _isRunning;
  late bool _isWork;
  late int _sessions;
  Timer? _timer;

  static const int _workDuration = 25 * 60;
  static const int _breakDuration = 5 * 60;

  @override
  void initState() {
    super.initState();
    _seconds = widget.widget.state['seconds'] as int? ?? _workDuration;
    _isRunning = widget.widget.state['isRunning'] as bool? ?? false;
    _isWork = widget.widget.state['isWork'] as bool? ?? true;
    _sessions = widget.widget.state['sessions'] as int? ?? 0;
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
      if (_seconds <= 1) {
        _timer?.cancel();
        setState(() {
          if (_isWork) {
            _sessions++;
            _isWork = false;
            _seconds = _breakDuration;
          } else {
            _isWork = true;
            _seconds = _workDuration;
          }
          _isRunning = false;
        });
        _notify();
        return;
      }
      setState(() => _seconds--);
    });
    setState(() => _isRunning = true);
    _notify();
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _notify();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _seconds = _isWork ? _workDuration : _breakDuration;
      _isRunning = false;
    });
    _notify();
  }

  void _notify() {
    widget.onStateChanged({
      'seconds': _seconds,
      'isRunning': _isRunning,
      'isWork': _isWork,
      'sessions': _sessions,
    });
  }

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _isWork ? _workDuration : _breakDuration;
    final progress = total > 0 ? _seconds / total : 0.0;

    return Material(
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
            Text(
              _isWork ? '🍅 Work' : '☕ Break',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                    color: _isWork ? Colors.red.shade400 : Colors.green.shade400,
                  ),
                  Center(
                    child: Text(
                      _format(_seconds),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
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
                  icon: const Icon(Icons.restart_alt),
                  onPressed: _reset,
                ),
              ],
            ),
            Text('Sessions: $_sessions',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
