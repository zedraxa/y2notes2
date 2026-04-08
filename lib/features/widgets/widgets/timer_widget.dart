import 'dart:async';

import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

class TimerWidget extends SmartWidget {
  TimerWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(220, 220),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.timer,
          state: state ??
              const {
                'seconds': 0,
                'isRunning': false,
                'laps': <int>[],
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
  Widget buildInteractiveOverlay(
    BuildContext context, {
    required ValueChanged<Map<String, dynamic>> onStateChanged,
  }) =>
      _TimerOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _TimerOverlay extends StatefulWidget {
  const _TimerOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final TimerWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_TimerOverlay> createState() =>
      _TimerOverlayState();
}

class _TimerOverlayState extends State<_TimerOverlay> {
  late int _seconds;
  late bool _isRunning;
  late List<int> _laps;
  late bool _isCountdown;
  late int _countdownFrom;
  Timer? _timer;
  bool _editingTime = false;
  final _timeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.widget.state;
    _seconds = s['seconds'] as int? ?? 0;
    _isRunning = s['isRunning'] as bool? ?? false;
    _isCountdown =
        s['isCountdown'] as bool? ?? false;
    _countdownFrom =
        s['countdownFrom'] as int? ?? 0;
    final rawLaps = s['laps'] as List?;
    _laps = rawLaps
            ?.map((e) => e as int)
            .toList() ??
        [];
    if (_isRunning) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    if (_isCountdown && _seconds <= 0) return;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_isCountdown) {
          if (_seconds <= 1) {
            _timer?.cancel();
            setState(() {
              _seconds = 0;
              _isRunning = false;
            });
            _notify();
            return;
          }
          setState(() => _seconds--);
        } else {
          setState(() => _seconds++);
        }
        _notify();
      },
    );
    setState(() => _isRunning = true);
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _notify();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _seconds =
          _isCountdown ? _countdownFrom : 0;
      _isRunning = false;
      _laps = [];
    });
    _notify();
  }

  void _lap() {
    setState(() => _laps.insert(0, _seconds));
    _notify();
  }

  void _setPreset(int minutes) {
    _timer?.cancel();
    setState(() {
      _seconds = minutes * 60;
      _countdownFrom = minutes * 60;
      _isCountdown = true;
      _isRunning = false;
      _laps = [];
    });
    _notify();
  }

  void _toggleMode() {
    _timer?.cancel();
    setState(() {
      _isCountdown = !_isCountdown;
      if (_isCountdown) {
        _countdownFrom = _seconds > 0 ? _seconds : 300;
        _seconds = _countdownFrom;
      } else {
        _seconds = 0;
      }
      _isRunning = false;
      _laps = [];
    });
    _notify();
  }

  void _notify() {
    widget.onStateChanged({
      'seconds': _seconds,
      'isRunning': _isRunning,
      'isCountdown': _isCountdown,
      'countdownFrom': _countdownFrom,
      'laps': _laps,
    });
  }

  String _format(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}'
          ':${m.toString().padLeft(2, '0')}'
          ':${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}'
        ':${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isFinished =
        _isCountdown && _seconds == 0 && !_isRunning;

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
            // Header with mode toggle
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Text(
                  '⏱️ ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _toggleMode,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isCountdown
                          ? '⏳ Countdown'
                          : '⏱ Stopwatch',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Time display
            if (_editingTime)
              SizedBox(
                width: 100,
                height: 36,
                child: TextField(
                  controller: _timeCtrl,
                  autofocus: true,
                  keyboardType:
                      TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  decoration:
                      const InputDecoration(
                    isDense: true,
                    hintText: 'min',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.zero,
                  ),
                  onSubmitted: (v) {
                    final mins =
                        int.tryParse(v) ?? 0;
                    if (mins > 0) {
                      _setPreset(mins);
                    }
                    setState(
                      () => _editingTime = false,
                    );
                  },
                ),
              )
            else
              GestureDetector(
                onDoubleTap: () {
                  if (!_isRunning) {
                    setState(() {
                      _editingTime = true;
                      _timeCtrl.text =
                          '${_seconds ~/ 60}';
                    });
                  }
                },
                child: Text(
                  _format(_seconds),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isFinished
                        ? Colors.red
                        : null,
                  ),
                ),
              ),
            if (isFinished)
              Text(
                '🔔 Time\'s up!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade400,
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
                  onPressed: _isRunning
                      ? _stop
                      : (isFinished ? null : _start),
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: _reset,
                ),
                if (_isRunning && !_isCountdown)
                  IconButton(
                    icon: const Icon(Icons.flag),
                    onPressed: _lap,
                    tooltip: 'Lap',
                  ),
              ],
            ),
            // Preset buttons
            if (!_isRunning && _seconds == 0 ||
                !_isRunning && _isCountdown)
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [1, 5, 10, 15, 30]
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets
                            .symmetric(
                          horizontal: 2,
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              _setPreset(m),
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration:
                                BoxDecoration(
                              color: _isCountdown &&
                                      _countdownFrom ==
                                          m * 60
                                  ? Colors
                                      .blue.shade100
                                  : Colors
                                      .blue.shade50,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                8,
                              ),
                            ),
                            child: Text(
                              '${m}m',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors
                                    .blue.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            // Laps
            if (_laps.isNotEmpty) ...[
              const SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  itemCount: _laps.length,
                  itemBuilder: (_, i) =>
                      Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '#${_laps.length - i}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors
                                .grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _format(_laps[i]),
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily:
                                'monospace',
                          ),
                        ),
                        if (i <
                            _laps.length - 1) ...[
                          const SizedBox(width: 6),
                          Text(
                            '+${_format(_laps[i] - _laps[i + 1])}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors
                                  .blue.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
