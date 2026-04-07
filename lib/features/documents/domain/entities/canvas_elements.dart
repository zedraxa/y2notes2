import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A single drawn shape element on a notebook page.
/// This is a forward-compatible placeholder for shape elements introduced in
/// PR 3 (Shape Recognition & Geometry System).
class ShapeElement extends Equatable {
  const ShapeElement({
    required this.id,
    required this.shapeType,
    required this.bounds,
    required this.color,
    required this.strokeWidth,
    this.isFilled = false,
  });

  final String id;
  final String shapeType;
  final Rect bounds;
  final Color color;
  final double strokeWidth;
  final bool isFilled;

  @override
  List<Object?> get props =>
      [id, shapeType, bounds, color, strokeWidth, isFilled];
}

/// A sticker / stamp placed on a notebook page.
/// Placeholder for sticker elements introduced in PR 4 (Stickers & Stamps).
class StickerElement extends Equatable {
  const StickerElement({
    required this.id,
    required this.stickerId,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.renderedImage,
  });

  final String id;
  final String stickerId;
  final Offset position;
  final double scale;
  final double rotation;
  final ui.Image? renderedImage;

  @override
  List<Object?> get props => [id, stickerId, position, scale, rotation];
}
