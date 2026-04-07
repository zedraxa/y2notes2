import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';

enum LayerDirection { front, back, forward, backward }

abstract class StickerEvent extends Equatable {
  const StickerEvent();
}

class StickerPlacementPending extends StickerEvent {
  const StickerPlacementPending(this.template);
  final StickerElement template;
  @override
  List<Object?> get props => [template];
}

class StickerPlaced extends StickerEvent {
  const StickerPlaced(this.sticker);
  final StickerElement sticker;
  @override
  List<Object?> get props => [sticker];
}

class StickerMoved extends StickerEvent {
  const StickerMoved(this.id, this.position);
  final String id;
  final Offset position;
  @override
  List<Object?> get props => [id, position];
}

class StickerScaled extends StickerEvent {
  const StickerScaled(this.id, this.scale);
  final String id;
  final double scale;
  @override
  List<Object?> get props => [id, scale];
}

class StickerRotated extends StickerEvent {
  const StickerRotated(this.id, this.rotation);
  final String id;
  final double rotation;
  @override
  List<Object?> get props => [id, rotation];
}

class StickerDeleted extends StickerEvent {
  const StickerDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class StickerDuplicated extends StickerEvent {
  const StickerDuplicated(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class StickerLayerChanged extends StickerEvent {
  const StickerLayerChanged(this.id, this.direction);
  final String id;
  final LayerDirection direction;
  @override
  List<Object?> get props => [id, direction];
}

class StickerLocked extends StickerEvent {
  const StickerLocked(this.id, {required this.isLocked});
  final String id;
  final bool isLocked;
  @override
  List<Object?> get props => [id, isLocked];
}

class StickerSelected extends StickerEvent {
  const StickerSelected(this.id);
  final String? id;
  @override
  List<Object?> get props => [id];
}

class StickerOpacityChanged extends StickerEvent {
  const StickerOpacityChanged(this.id, this.opacity);
  final String id;
  final double opacity;
  @override
  List<Object?> get props => [id, opacity];
}

class StickerUndoRequested extends StickerEvent {
  const StickerUndoRequested();
  @override
  List<Object?> get props => [];
}

class StickerRedoRequested extends StickerEvent {
  const StickerRedoRequested();
  @override
  List<Object?> get props => [];
}
