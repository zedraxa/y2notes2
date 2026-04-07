import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum StickerType { emoji, image, washi, stamp }

class StickerElement extends Equatable {
  StickerElement({
    String? id,
    required this.type,
    required this.assetKey,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.zIndex = 0,
    this.isLocked = false,
    DateTime? createdAt,
    this.washiLength,
    this.washiWidth,
    this.washiTint,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final StickerType type;
  final String assetKey;
  final Offset position;
  final double scale;
  final double rotation;
  final double opacity;
  final int zIndex;
  final bool isLocked;
  final DateTime createdAt;
  final double? washiLength;
  final double? washiWidth;
  final Color? washiTint;

  StickerElement copyWith({
    StickerType? type,
    String? assetKey,
    Offset? position,
    double? scale,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? isLocked,
    double? washiLength,
    double? washiWidth,
    Color? washiTint,
  }) =>
      StickerElement(
        id: id,
        type: type ?? this.type,
        assetKey: assetKey ?? this.assetKey,
        position: position ?? this.position,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
        opacity: opacity ?? this.opacity,
        zIndex: zIndex ?? this.zIndex,
        isLocked: isLocked ?? this.isLocked,
        createdAt: createdAt,
        washiLength: washiLength ?? this.washiLength,
        washiWidth: washiWidth ?? this.washiWidth,
        washiTint: washiTint ?? this.washiTint,
      );

  /// Serializes to a JSON-compatible map for persistence.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'assetKey': assetKey,
        'positionX': position.dx,
        'positionY': position.dy,
        'scale': scale,
        'rotation': rotation,
        'opacity': opacity,
        'zIndex': zIndex,
        'isLocked': isLocked,
        'createdAt': createdAt.toIso8601String(),
        if (washiLength != null) 'washiLength': washiLength,
        if (washiWidth != null) 'washiWidth': washiWidth,
        if (washiTint != null) 'washiTint': washiTint!.value,
      };

  /// Deserializes from a JSON-compatible map.
  factory StickerElement.fromJson(Map<String, dynamic> json) => StickerElement(
        id: json['id'] as String,
        type: StickerType.values.byName(json['type'] as String),
        assetKey: json['assetKey'] as String,
        position: Offset(
          (json['positionX'] as num).toDouble(),
          (json['positionY'] as num).toDouble(),
        ),
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
        isLocked: json['isLocked'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        washiLength: (json['washiLength'] as num?)?.toDouble(),
        washiWidth: (json['washiWidth'] as num?)?.toDouble(),
        washiTint:
            json['washiTint'] != null ? Color(json['washiTint'] as int) : null,
      );

  @override
  List<Object?> get props => [
        id,
        type,
        assetKey,
        position,
        scale,
        rotation,
        opacity,
        zIndex,
        isLocked,
        createdAt,
        washiLength,
        washiWidth,
        washiTint,
      ];
}
