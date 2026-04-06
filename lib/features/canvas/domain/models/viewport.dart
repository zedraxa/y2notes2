import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:y2notes2/core/constants/app_constants.dart';

/// Current viewport state (pan + zoom).
class Viewport extends Equatable {
  const Viewport({
    this.zoom = AppConstants.defaultZoom,
    this.panOffset = Offset.zero,
  });

  final double zoom;
  final Offset panOffset;

  Viewport copyWith({double? zoom, Offset? panOffset}) => Viewport(
        zoom: zoom ?? this.zoom,
        panOffset: panOffset ?? this.panOffset,
      );

  /// Convert a canvas-space point to screen-space.
  Offset toScreen(Offset canvasPoint) =>
      canvasPoint * zoom + panOffset;

  /// Convert a screen-space point to canvas-space.
  Offset toCanvas(Offset screenPoint) =>
      (screenPoint - panOffset) / zoom;

  @override
  List<Object?> get props => [zoom, panOffset];
}
