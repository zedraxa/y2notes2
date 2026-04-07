import 'package:flutter/material.dart';
import 'package:biscuitse/features/stickers/domain/entities/sticker_element.dart';

/// Generates a trail of stamp [StickerElement]s along a drag path.
class StampBrushEngine {
  StampBrushEngine({
    required this.stampId,
    this.spacing = 60.0,
    this.scale = 0.5,
    this.opacity = 0.85,
  });

  final String stampId;
  final double spacing;
  final double scale;
  final double opacity;

  final List<StickerElement> _trail = [];
  Offset? _lastPlacedPosition;

  List<StickerElement> get trail => List.unmodifiable(_trail);

  void onDragStart(Offset position) {
    _lastPlacedPosition = null;
    _placeStamp(position);
  }

  void onDragUpdate(Offset position) {
    if (_lastPlacedPosition == null) {
      _placeStamp(position);
      return;
    }
    final dist = (position - _lastPlacedPosition!).distance;
    if (dist >= spacing) {
      _placeStamp(position);
    }
  }

  List<StickerElement> onDragEnd() {
    final result = List<StickerElement>.from(_trail);
    _trail.clear();
    _lastPlacedPosition = null;
    return result;
  }

  void _placeStamp(Offset position) {
    final sticker = StickerElement(
      type: StickerType.stamp,
      assetKey: stampId,
      position: position,
      scale: scale,
      opacity: opacity,
    );
    _trail.add(sticker);
    _lastPlacedPosition = position;
  }
}
