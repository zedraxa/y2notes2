import 'dart:async';

import 'package:flutter/material.dart';
import 'package:biscuits/features/widgets/domain/entities/smart_widget.dart';

/// Pomodoro timer — 25 min work / 5 min break / 15 min long break.
class PomodoroWidget extends SmartWidget {
  PomodoroWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(200, 240),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.stickyTimer,
          state: state ??
              const {
                'seconds': 1500,
                'isRunning': false,
                'isWork': true,
                'sessions': 0,
                'dailyGoal': 8,
                'totalWorkSeconds': 0,
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
  Widget buildInteractiveOverlay(
    BuildContext context, {
    required ValueChanged<Map<String, dynamic>> onStateChanged,
  }) =>
      _PomodoroOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _PomodoroOverlay extends StatefulWidget {
  const _PomodoroOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final PomodoroWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_PomodoroOverlay> createState() =>
      _PomodoroOverlayState();
}

class _PomodoroOverlayState
    extends State<_PomodoroOverlay> {
  late int _seconds;
  late bool _isRunning;
  late bool _isWork;
  late int _sessions;
  late int _dailyGoal;
  late int _totalWorkSeconds;
  late bool _autoStart;
  late int _workDuration;
  late int _breakDuration;
  late int _longBreakDuration;
  Timer? _timer;
  bool _showSettings = false;

  static const int _defaultWorkDuration = 25 * 60;
  static const int _defaultBreakDuration = 5 * 60;
  static const int _defaultLongBreakDuration = 15 * 60;
  static const int _longBreakInterval = 4;

  @override
  void initState() {
    super.initState();
    final s = widget.widget.state;
    _workDuration = s['workDuration'] as int? ??
        _defaultWorkDuration;
    _breakDuration = s['breakDuration'] as int? ??
        _defaultBreakDuration;
    _longBreakDuration =
        s['longBreakDuration'] as int? ??
            _defaultLongBreakDuration;
    _seconds = s['seconds'] as int? ?? _workDuration;
    _isRunning = s['isRunning'] as bool? ?? false;
    _isWork = s['isWork'] as bool? ?? true;
    _sessions = s['sessions'] as int? ?? 0;
    _dailyGoal = s['dailyGoal'] as int? ?? 8;
    _totalWorkSeconds =
        s['totalWorkSeconds'] as int? ?? 0;
    _autoStart = s['autoStart'] as bool? ?? false;
    if (_isRunning) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isLongBreak =>
      !_isWork &&
      _sessions > 0 &&
      _sessions % _longBreakInterval == 0;

  int get _currentBreakDuration => _isLongBreak
      ? _longBreakDuration
      : _breakDuration;

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_seconds <= 1) {
          _timer?.cancel();
          setState(() {
            if (_isWork) {
              _sessions++;
              _totalWorkSeconds += _workDuration;
              _isWork = false;
              _seconds = _sessions %
                          _longBreakInterval ==
                      0
                  ? _longBreakDuration
                  : _breakDuration;
            } else {
              _isWork = true;
              _seconds = _workDuration;
            }
            _isRunning = false;
          });
          _notify();
          // Auto-start next phase if enabled
          if (_autoStart) {
            _start();
          }
          return;
        }
        setState(() {
          _seconds--;
          if (_isWork) _totalWorkSeconds++;
        });
      },
    );
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
      _seconds = _isWork
          ? _workDuration
          : _currentBreakDuration;
      _isRunning = false;
    });
    _notify();
  }

  void _skip() {
    _timer?.cancel();
    setState(() {
      if (_isWork) {
        _sessions++;
        _isWork = false;
        _seconds =
            _sessions % _longBreakInterval == 0
                ? _longBreakDuration
                : _breakDuration;
      } else {
        _isWork = true;
        _seconds = _workDuration;
      }
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
      'dailyGoal': _dailyGoal,
      'totalWorkSeconds': _totalWorkSeconds,
      'autoStart': _autoStart,
      'workDuration': _workDuration,
      'breakDuration': _breakDuration,
      'longBreakDuration': _longBreakDuration,
    });
  }

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}'
        ':${sec.toString().padLeft(2, '0')}';
  }

  String _formatMinutes(int s) {
    final m = s ~/ 60;
    final h = m ~/ 60;
    final rm = m % 60;
    if (h > 0) return '${h}h ${rm}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final total = _isWork
        ? _workDuration
        : _currentBreakDuration;
    final progress = total > 0 ? _seconds / total : 0.0;
    final goalProgress = _dailyGoal > 0
        ? (_sessions / _dailyGoal).clamp(0.0, 1.0)
        : 0.0;

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
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            // Phase label + settings
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  _isWork
                      ? '🍅 Work'
                      : _isLongBreak
                          ? '🌴 Long Break'
                          : '☕ Break',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(
                    () => _showSettings =
                        !_showSettings,
                  ),
                  child: Icon(
                    Icons.settings,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            // Settings panel
            if (_showSettings) ...[
              const SizedBox(height: 4),
              _durationRow(
                'Work',
                _workDuration ~/ 60,
                (m) {
                  setState(
                    () =>
                        _workDuration = m * 60,
                  );
                  if (_isWork && !_isRunning) {
                    setState(
                      () => _seconds =
                          _workDuration,
                    );
                  }
                  _notify();
                },
              ),
              _durationRow(
                'Break',
                _breakDuration ~/ 60,
                (m) {
                  setState(
                    () =>
                        _breakDuration = m * 60,
                  );
                  _notify();
                },
              ),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    'Auto-start',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    width: 32,
                    child: Switch(
                      value: _autoStart,
                      onChanged: (v) {
                        setState(
                          () => _autoStart = v,
                        );
                        _notify();
                      },
                      materialTapTargetSize:
                          MaterialTapTargetSize
                              .shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            // Progress circle
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor:
                        Colors.grey.shade200,
                    color: _isWork
                        ? Colors.red.shade400
                        : _isLongBreak
                            ? Colors.teal.shade400
                            : Colors.green.shade400,
                  ),
                  Center(
                    child: Text(
                      _format(_seconds),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Controls
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isRunning
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  iconSize: 22,
                  onPressed:
                      _isRunning ? _stop : _start,
                ),
                IconButton(
                  icon:
                      const Icon(Icons.restart_alt),
                  iconSize: 22,
                  onPressed: _reset,
                ),
                IconButton(
                  icon:
                      const Icon(Icons.skip_next),
                  iconSize: 22,
                  onPressed: _skip,
                  tooltip: 'Skip to next phase',
                ),
              ],
            ),
            // Session counter + total focus time
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  'Sessions: $_sessions',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '⏱ ${_formatMinutes(_totalWorkSeconds)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade400,
                  ),
                ),
              ],
            ),
            // Daily goal progress
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Goal: $_sessions/$_dailyGoal',
                  style: TextStyle(
                    fontSize: 10,
                    color: _sessions >= _dailyGoal
                        ? Colors.green
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: goalProgress,
                      minHeight: 4,
                      backgroundColor:
                          Colors.grey.shade200,
                      color:
                          _sessions >= _dailyGoal
                              ? Colors.green
                              : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationRow(
    String label,
    int minutes,
    ValueChanged<int> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 1,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (minutes > 1) {
                  onChanged(minutes - 1);
                }
              },
              child: Icon(
                Icons.remove_circle_outline,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(
              width: 30,
              child: Text(
                '${minutes}m',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (minutes < 60) {
                  onChanged(minutes + 1);
                }
              },
              child: Icon(
                Icons.add_circle_outline,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
}
