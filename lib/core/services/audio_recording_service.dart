import 'dart:async';
import 'dart:io' if (dart.library.html) 'package:biscuits/core/io/io_stub.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service that wraps platform microphone recording and audio playback.
///
/// Each [AudioRecordingService] manages a single [AudioRecorder] and
/// [AudioPlayer] instance. Call [dispose] when done.
class AudioRecordingService {
  AudioRecordingService();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  /// Whether the recorder is currently capturing audio.
  bool get isRecording => _isRecording;
  bool _isRecording = false;

  /// Whether the player is currently playing audio.
  bool get isPlaying => _isPlaying;
  bool _isPlaying = false;

  /// Stream of playback progress values in [0.0, 1.0].
  ///
  /// Emits values while audio is playing. Emits `0.0` when stopped.
  Stream<double> get playbackProgress => _progressController.stream;
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  /// Stream of amplitude values in [0.0, 1.0] during recording.
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  Duration _totalDuration = Duration.zero;
  Timer? _amplitudeTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  /// Returns `true` when the platform grants microphone access.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Begin recording to a new file.
  ///
  /// Returns the absolute file path where audio is being saved.
  /// Throws if microphone permission is not granted.
  Future<String> startRecording() async {
    if (_isRecording) return '';

    final hasAccess = await _recorder.hasPermission();
    if (!hasAccess) {
      throw StateError('Microphone permission not granted');
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    _isRecording = true;

    // Poll amplitude while recording.
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) async {
        if (!_isRecording) return;
        try {
          final amp = await _recorder.getAmplitude();
          // amp.current is in dBFS (negative values, 0 = max).
          // Normalize to 0-1 range.
          final normalised =
              ((amp.current + 50) / 50).clamp(0.0, 1.0);
          _amplitudeController.add(normalised);
        } catch (_) {
          // Recorder may have been stopped; ignore.
        }
      },
    );

    return filePath;
  }

  /// Stop the current recording.
  ///
  /// Returns the saved file path, or `null` if nothing was being recorded.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    _amplitudeTimer?.cancel();
    _isRecording = false;

    final path = await _recorder.stop();
    _amplitudeController.add(0.0);
    return path;
  }

  /// Play back an audio file at the given [filePath].
  Future<void> play(String filePath) async {
    await stopPlayback();

    // Read total duration first so we can compute progress.
    await _player.setSourceDeviceFile(filePath);
    _totalDuration = await _player.getDuration() ?? Duration.zero;

    _positionSub?.cancel();
    _positionSub = _player.onPositionChanged.listen((pos) {
      if (_totalDuration.inMilliseconds > 0) {
        final progress =
            pos.inMilliseconds / _totalDuration.inMilliseconds;
        _progressController.add(progress.clamp(0.0, 1.0));
      }
    });

    _stateSub?.cancel();
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed ||
          state == PlayerState.stopped) {
        _isPlaying = false;
        _progressController.add(0.0);
      }
    });

    await _player.play(DeviceFileSource(filePath));
    _isPlaying = true;
  }

  /// Stop audio playback.
  Future<void> stopPlayback() async {
    _positionSub?.cancel();
    _stateSub?.cancel();
    await _player.stop();
    _isPlaying = false;
    _progressController.add(0.0);
  }

  /// Delete the audio file at [filePath] from disk.
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Release all resources.
  Future<void> dispose() async {
    _amplitudeTimer?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    await _recorder.dispose();
    await _player.dispose();
    await _progressController.close();
    await _amplitudeController.close();
  }
}
