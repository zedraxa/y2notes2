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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final s = widget.widget.state;
    _seconds = s['seconds'] as int? ?? 0;
    _isRunning = s['isRunning'] as bool? ?? false;
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
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() => _seconds++);
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
      _seconds = 0;
      _isRunning = false;
      _laps = [];
    });
    _notify();
  }

  void _lap() {
    setState(() => _laps.insert(0, _seconds));
    _notify();
  }

  void _notify() {
    widget.onStateChanged({
      'seconds': _seconds,
      'isRunning': _isRunning,
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
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                '⏱️ Timer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              // Time display
              Text(
                _format(_seconds),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
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
                        : _start,
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: _reset,
                  ),
                  if (_isRunning)
                    IconButton(
                      icon: const Icon(Icons.flag),
                      onPressed: _lap,
                      tooltip: 'Lap',
                    ),
                ],
              ),
              // Preset buttons
              if (!_isRunning && _seconds == 0)
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [1, 5, 10, 15]
                      .map(
                        (m) => Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 3,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(
                                () => _seconds =
                                    m * 60,
                              );
                              _notify();
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: Colors
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
                                      .blue
                                      .shade600,
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
