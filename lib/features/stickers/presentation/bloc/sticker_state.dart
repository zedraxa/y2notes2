import 'package:equatable/equatable.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';

class StickerState extends Equatable {
  const StickerState({
    this.stickers = const [],
    this.selectedStickerId,
    this.undoStack = const [],
    this.redoStack = const [],
    this.pendingPlacement,
    this.stampBrushId,
  });

  final List<StickerElement> stickers;
  final String? selectedStickerId;
  final List<List<StickerElement>> undoStack;
  final List<List<StickerElement>> redoStack;
  final StickerElement? pendingPlacement;

  /// When non-null, stamp brush mode is active with this stamp asset key.
  final String? stampBrushId;

  StickerElement? get selectedSticker =>
      selectedStickerId == null
          ? null
          : stickers.where((s) => s.id == selectedStickerId).firstOrNull;

  List<StickerElement> get sortedByZIndex =>
      [...stickers]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  /// Whether stamp brush painting mode is active.
  bool get isStampBrushActive => stampBrushId != null;

  StickerState copyWith({
    List<StickerElement>? stickers,
    Object? selectedStickerId = _sentinel,
    List<List<StickerElement>>? undoStack,
    List<List<StickerElement>>? redoStack,
    Object? pendingPlacement = _sentinel,
    Object? stampBrushId = _sentinel,
  }) =>
      StickerState(
        stickers: stickers ?? this.stickers,
        selectedStickerId: selectedStickerId == _sentinel
            ? this.selectedStickerId
            : selectedStickerId as String?,
        undoStack: undoStack ?? this.undoStack,
        redoStack: redoStack ?? this.redoStack,
        pendingPlacement: pendingPlacement == _sentinel
            ? this.pendingPlacement
            : pendingPlacement as StickerElement?,
        stampBrushId: stampBrushId == _sentinel
            ? this.stampBrushId
            : stampBrushId as String?,
      );

  @override
  List<Object?> get props => [
        stickers,
        selectedStickerId,
        undoStack,
        redoStack,
        pendingPlacement,
        stampBrushId,
      ];
}

// Sentinel object used to distinguish "not provided" from "null" in copyWith.
const _sentinel = Object();
