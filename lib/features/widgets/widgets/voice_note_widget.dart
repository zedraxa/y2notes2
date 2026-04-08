import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:biscuits/core/services/audio_recording_service.dart';
import 'package:biscuits/features/widgets/domain/entities/smart_widget.dart';

/// Voice note widget with real microphone recording and audio playback.
///
/// Uses [AudioRecordingService] for platform microphone capture and
/// [audioplayers] for playback. Falls back to simulated recording when
/// microphone permission is denied.
class VoiceNoteWidget extends SmartWidget {
  VoiceNoteWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(240, 140),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.voiceNote,
          state: state ??
              const {
                'recordings': <Map<String, dynamic>>[],
                'activeIndex': -1,
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
  Widget buildInteractiveOverlay(
    BuildContext context, {
    required ValueChanged<Map<String, dynamic>> onStateChanged,
  }) =>
      _VoiceNoteOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _VoiceNoteOverlay extends StatefulWidget {
  const _VoiceNoteOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final VoiceNoteWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_VoiceNoteOverlay> createState() =>
      _VoiceNoteOverlayState();
}

class _VoiceNoteOverlayState
    extends State<_VoiceNoteOverlay> {
  late List<Map<String, dynamic>> _recordings;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  int _playingIndex = -1;
  double _playbackProgress = 0;
  double _playbackSpeed = 1.0;
  Timer? _timer;
  int _renamingIndex = -1;
  final _renameCtrl = TextEditingController();

  static const _speeds = [0.5, 1.0, 1.5, 2.0];

  // Real audio backend
  AudioRecordingService? _audioService;
  String? _currentRecordingPath;
  final List<double> _liveAmplitudes = [];
  StreamSubscription<double>? _ampSub;
  StreamSubscription<double>? _progressSub;
  bool _useRealMic = false;

  @override
  void initState() {
    super.initState();
    final raw =
        widget.widget.state['recordings'] as List?;
    _recordings = raw
            ?.map(
              (e) =>
                  Map<String, dynamic>.from(e as Map),
            )
            .toList() ??
        [];

    _initAudioService();
  }

  Future<void> _initAudioService() async {
    try {
      final service = AudioRecordingService();
      final hasPermission = await service.hasPermission();
      if (!mounted) {
        await service.dispose();
        return;
      }
      setState(() {
        _audioService = service;
        _useRealMic = hasPermission;
      });

      // Listen to playback progress from the real player.
      _progressSub = service.playbackProgress.listen((progress) {
        if (!mounted) return;
        setState(() => _playbackProgress = progress);
        if (progress <= 0 && _playingIndex >= 0) {
          setState(() {
            _playingIndex = -1;
            _playbackProgress = 0;
          });
        }
      });
    } catch (_) {
      // Platform doesn't support recording — keep simulation mode.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _renameCtrl.dispose();
    _ampSub?.cancel();
    _progressSub?.cancel();
    _audioService?.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onStateChanged({
      'recordings': _recordings,
      'activeIndex': _playingIndex,
    });
  }

  int get _totalDuration => _recordings.fold(
        0,
        (sum, r) =>
            sum + (r['duration'] as int? ?? 0),
      );

  // --------------- Recording ---------------

  Future<void> _startRecording() async {
    _timer?.cancel();

    if (_useRealMic && _audioService != null) {
      await _startRealRecording();
    } else {
      _startSimulatedRecording();
    }
  }

  Future<void> _startRealRecording() async {
    try {
      final path = await _audioService!.startRecording();
      if (!mounted) return;

      _currentRecordingPath = path;
      _liveAmplitudes.clear();

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // Tick seconds counter.
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted) return;
          setState(() => _recordingSeconds++);
          if (_recordingSeconds >= 120) {
            _stopRecording();
          }
        },
      );

      // Collect amplitude samples for waveform visualization.
      _ampSub?.cancel();
      _ampSub = _audioService!.amplitudeStream.listen((amp) {
        if (!mounted) return;
        _liveAmplitudes.add(amp);
      });
    } catch (_) {
      // Fall back to simulated recording on any error.
      _useRealMic = false;
      _startSimulatedRecording();
    }
  }

  void _startSimulatedRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 60) {
          _stopRecording();
        }
      },
    );
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _ampSub?.cancel();

    if (_recordingSeconds <= 0) {
      if (_isRecording && _audioService != null && _useRealMic) {
        await _audioService!.stopRecording();
      }
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      return;
    }

    if (_useRealMic && _audioService != null) {
      await _stopRealRecording();
    } else {
      _stopSimulatedRecording();
    }
  }

  Future<void> _stopRealRecording() async {
    final path = await _audioService!.stopRecording();

    // Downsample live amplitudes to 20 bars for the waveform display.
    final waveform = _downsampleAmplitudes(_liveAmplitudes, 20);

    setState(() {
      _recordings.add({
        'duration': _recordingSeconds,
        'waveform': waveform,
        'label': 'Note ${_recordings.length + 1}',
        'filePath': path ?? _currentRecordingPath,
      });
      _isRecording = false;
      _recordingSeconds = 0;
      _currentRecordingPath = null;
    });
    _notify();
  }

  void _stopSimulatedRecording() {
    // Generate random waveform data for simulated mode.
    final rng = Random(DateTime.now().millisecond);
    final waveform = List.generate(
      20,
      (_) => (rng.nextDouble() * 0.8 + 0.2),
    );
    setState(() {
      _recordings.add({
        'duration': _recordingSeconds,
        'waveform': waveform,
        'label': 'Note ${_recordings.length + 1}',
      });
      _isRecording = false;
      _recordingSeconds = 0;
    });
    _notify();
  }

  /// Downsamples a list of amplitude values to [targetCount] bars.
  List<double> _downsampleAmplitudes(
    List<double> samples,
    int targetCount,
  ) {
    if (samples.isEmpty) {
      return List.generate(targetCount, (_) => 0.2);
    }
    if (samples.length <= targetCount) {
      return List<double>.from(samples);
    }
    final chunkSize = samples.length / targetCount;
    return List.generate(targetCount, (i) {
      final start = (i * chunkSize).floor();
      final end = ((i + 1) * chunkSize).floor().clamp(start + 1, samples.length);
      final chunk = samples.sublist(start, end);
      final avg = chunk.reduce((a, b) => a + b) / chunk.length;
      // Ensure a minimum bar height.
      return avg.clamp(0.1, 1.0);
    });
  }

  // --------------- Playback ---------------

  Future<void> _play(int index) async {
    _timer?.cancel();

    final rec = _recordings[index];
    final filePath = rec['filePath'] as String?;

    if (filePath != null && _audioService != null) {
      await _playReal(index, filePath);
    } else {
      _playSimulated(index);
    }
  }

  Future<void> _playReal(int index, String filePath) async {
    try {
      setState(() {
        _playingIndex = index;
        _playbackProgress = 0;
      });
      await _audioService!.play(filePath);
    } catch (_) {
      // Fall back to simulated playback on error.
      _playSimulated(index);
    }
  }

  void _playSimulated(int index) {
    final dur =
        _recordings[index]['duration'] as int? ?? 5;
    setState(() {
      _playingIndex = index;
      _playbackProgress = 0;
    });
    // Adjust steps based on playback speed
    final adjustedDur = (dur / _playbackSpeed).round();
    final steps = adjustedDur * 10;
    int step = 0;
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        step++;
        setState(
          () => _playbackProgress = step / steps,
        );
        if (step >= steps) {
          _timer?.cancel();
          setState(() {
            _playingIndex = -1;
            _playbackProgress = 0;
          });
        }
      },
    );
  }

  Future<void> _stopPlayback() async {
    _timer?.cancel();
    if (_audioService != null) {
      await _audioService!.stopPlayback();
    }
    setState(() {
      _playingIndex = -1;
      _playbackProgress = 0;
    });
  }

  Future<void> _deleteRecording(int index) async {
    if (_playingIndex == index) {
      await _stopPlayback();
    }
    final rec = _recordings[index];
    final filePath = rec['filePath'] as String?;
    if (filePath != null && _audioService != null) {
      await _audioService!.deleteFile(filePath);
    }
    setState(() => _recordings.removeAt(index));
    _notify();
  }

  void _cycleSpeed() {
    setState(() {
      final idx = _speeds.indexOf(_playbackSpeed);
      _playbackSpeed =
          _speeds[(idx + 1) % _speeds.length];
    });
  }

  String _formatDuration(int s) =>
      '${(s ~/ 60).toString().padLeft(1, '0')}'
      ':${(s % 60).toString().padLeft(2, '0')}';

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
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    '🎙️ Voice Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  // Speed toggle
                  GestureDetector(
                    onTap: _cycleSpeed,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _playbackSpeed != 1.0
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_playbackSpeed}x',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w600,
                          color: _playbackSpeed != 1.0
                              ? Colors
                                  .blue.shade600
                              : Colors
                                  .grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_recordings.length} clip'
                    '${_recordings.length != 1 ? 's' : ''}'
                    ' · ${_formatDuration(_totalDuration)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Recordings list
              Expanded(
                child: _recordings.isEmpty &&
                        !_isRecording
                    ? Center(
                        child: Text(
                          _useRealMic
                              ? 'Tap record to start'
                              : 'Tap record to start (simulated)',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Colors.grey.shade400,
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          if (_isRecording)
                            _buildRecordingRow(),
                          ..._recordings
                              .asMap()
                              .entries
                              .map(
                                (e) =>
                                    _buildRecordingItem(
                                  e.key,
                                  e.value,
                                ),
                              ),
                        ],
                      ),
              ),
              const SizedBox(height: 4),
              // Record button
              GestureDetector(
                onTap: () => _isRecording
                    ? _stopRecording()
                    : _startRecording(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.red
                        : Colors.red.shade100,
                    border: Border.all(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isRecording
                        ? Icons.stop
                        : Icons.mic,
                    color: _isRecording
                        ? Colors.white
                        : Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildRecordingRow() => Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Pulsing indicator
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Recording... '
              '${_formatDuration(_recordingSeconds)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildRecordingItem(
    int index,
    Map<String, dynamic> rec,
  ) {
    final dur = rec['duration'] as int? ?? 0;
    final label =
        rec['label'] as String? ?? 'Note';
    final waveform =
        (rec['waveform'] as List?)
                ?.map(
                  (e) => (e as num).toDouble(),
                )
                .toList() ??
            [];
    final isPlaying = _playingIndex == index;
    final isRenaming = _renamingIndex == index;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // Label row
          if (isRenaming)
            SizedBox(
              height: 18,
              child: TextField(
                controller: _renameCtrl,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 10,
                ),
                decoration:
                    const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.zero,
                ),
                onSubmitted: (v) {
                  if (v.isNotEmpty) {
                    setState(() {
                      _recordings[index]
                          ['label'] = v;
                    });
                    _notify();
                  }
                  setState(
                    () => _renamingIndex = -1,
                  );
                },
              ),
            )
          else
            GestureDetector(
              onDoubleTap: () {
                setState(() {
                  _renamingIndex = index;
                  _renameCtrl.text = label;
                });
              },
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            children: [
              // Play/pause button
              GestureDetector(
                onTap: () => isPlaying
                    ? _stopPlayback()
                    : _play(index),
                child: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 6),
              // Waveform
              Expanded(
                child: SizedBox(
                  height: 20,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      waveform: waveform,
                      progress: isPlaying
                          ? _playbackProgress
                          : 0,
                      activeColor: Colors.blue,
                      inactiveColor:
                          Colors.grey.shade300,
                    ),
                    size: const Size(
                      double.infinity,
                      20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Duration
              Text(
                _formatDuration(dur),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              // Delete
              GestureDetector(
                onTap: () =>
                    _deleteRecording(index),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.waveform,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<double> waveform;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;
    final mid = size.height / 2;
    final step = size.width / waveform.length;
    final progressX = progress * size.width;

    for (int i = 0; i < waveform.length; i++) {
      final x = i * step + step / 2;
      final h = waveform[i] * (size.height / 2 - 1);
      final isActive = x <= progressX;
      final paint = Paint()
        ..color =
            isActive ? activeColor : inactiveColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, mid - h),
        Offset(x, mid + h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.waveform != waveform;
}
