import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';

/// Hit-tests sticker elements to find which sticker is at a given canvas point.
class StickerHitTester {
  const StickerHitTester._();

  /// Returns the topmost (highest zIndex) sticker whose bounding box contains [point].
  static StickerElement? hitTest(
    List<StickerElement> stickers,
    Offset point,
  ) {
    StickerElement? hit;
    for (final sticker in stickers) {
      if (sticker.isLocked) continue;
      if (_containsPoint(sticker, point)) {
        if (hit == null || sticker.zIndex >= hit.zIndex) {
          hit = sticker;
        }
      }
    }
    return hit;
  }

  static bool _containsPoint(StickerElement sticker, Offset point) {
    final dx = point.dx - sticker.position.dx;
    final dy = point.dy - sticker.position.dy;

    // Apply inverse rotation
    final cos = math.cos(-sticker.rotation);
    final sin = math.sin(-sticker.rotation);
    final lx = (dx * cos - dy * sin) / sticker.scale;
    final ly = (dx * sin + dy * cos) / sticker.scale;
    final local = Offset(lx, ly);

    final bounds = _getLocalBounds(sticker);
    return bounds.contains(local);
  }

  static Rect _getLocalBounds(StickerElement sticker) {
    switch (sticker.type) {
      case StickerType.emoji:
      case StickerType.image:
        const half = 32.0;
        return const Rect.fromLTRB(-half, -half, half, half);
      case StickerType.stamp:
        return const Rect.fromLTRB(-56, -56, 56, 56);
      case StickerType.washi:
        final length = sticker.washiLength ?? 200.0;
        final width = sticker.washiWidth ?? 40.0;
        return Rect.fromCenter(
            center: Offset.zero, width: length, height: width);
    }
  }
}
