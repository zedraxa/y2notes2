import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Supported media types.
enum MediaType { audio, video }

/// Playback state of a media element.
enum PlaybackState { idle, playing, paused, stopped, error }

/// A media element (audio or video) embedded on a notebook page.
class MediaElement extends Equatable {
  MediaElement({
    String? id,
    required this.type,
    required this.filePath,
    required this.position,
    this.size = const Size(320, 180),
    this.fileName,
    this.durationMs = 0,
    this.thumbnailPath,
    this.volume = 1.0,
    this.isLocked = false,
    this.zIndex = 0,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final MediaType type;

  /// Absolute or relative file path to the media resource.
  final String filePath;

  /// Position on the canvas (top-left corner).
  final Offset position;

  /// Display size on the canvas.
  final Size size;

  /// User-visible file name.
  final String? fileName;

  /// Total duration in milliseconds (0 when unknown).
  final int durationMs;

  /// Optional thumbnail image path for video previews.
  final String? thumbnailPath;

  /// Playback volume (0.0–1.0).
  final double volume;

  /// Whether this element is locked from editing.
  final bool isLocked;

  /// Stack order for rendering.
  final int zIndex;

  final DateTime createdAt;

  bool get isAudio => type == MediaType.audio;
  bool get isVideo => type == MediaType.video;

  /// Human-readable duration string (mm:ss).
  String get durationLabel {
    if (durationMs <= 0) return '0:00';
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  MediaElement copyWith({
    MediaType? type,
    String? filePath,
    Offset? position,
    Size? size,
    String? fileName,
    int? durationMs,
    String? thumbnailPath,
    double? volume,
    bool? isLocked,
    int? zIndex,
  }) =>
      MediaElement(
        id: id,
        type: type ?? this.type,
        filePath: filePath ?? this.filePath,
        position: position ?? this.position,
        size: size ?? this.size,
        fileName: fileName ?? this.fileName,
        durationMs: durationMs ?? this.durationMs,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        volume: volume ?? this.volume,
        isLocked: isLocked ?? this.isLocked,
        zIndex: zIndex ?? this.zIndex,
        createdAt: createdAt,
      );

  /// Serializes to a JSON-compatible map for persistence.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'filePath': filePath,
        'positionX': position.dx,
        'positionY': position.dy,
        'width': size.width,
        'height': size.height,
        if (fileName != null) 'fileName': fileName,
        'durationMs': durationMs,
        if (thumbnailPath != null)
          'thumbnailPath': thumbnailPath,
        'volume': volume,
        'isLocked': isLocked,
        'zIndex': zIndex,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserializes from a JSON-compatible map.
  factory MediaElement.fromJson(Map<String, dynamic> json) =>
      MediaElement(
        id: json['id'] as String,
        type: MediaType.values.byName(
          json['type'] as String,
        ),
        filePath: json['filePath'] as String,
        position: Offset(
          (json['positionX'] as num).toDouble(),
          (json['positionY'] as num).toDouble(),
        ),
        size: Size(
          (json['width'] as num?)?.toDouble() ?? 320,
          (json['height'] as num?)?.toDouble() ?? 180,
        ),
        fileName: json['fileName'] as String?,
        durationMs:
            (json['durationMs'] as num?)?.toInt() ?? 0,
        thumbnailPath: json['thumbnailPath'] as String?,
        volume:
            (json['volume'] as num?)?.toDouble() ?? 1.0,
        isLocked: json['isLocked'] as bool? ?? false,
        zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        type,
        filePath,
        position,
        size,
        fileName,
        durationMs,
        thumbnailPath,
        volume,
        isLocked,
        zIndex,
        createdAt,
      ];
}
