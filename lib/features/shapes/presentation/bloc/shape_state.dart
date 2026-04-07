import 'package:equatable/equatable.dart';
import '../../engine/snap_guide_engine.dart';

/// Immutable state for the shape interaction BLoC.
///
/// Shapes themselves live in [CanvasBloc.shapes]; this state only tracks
/// interactive editing UI (selection, drag, snap guides).
class ShapeState extends Equatable {
  const ShapeState({
    this.selectedShapeId,
    this.snapGuides = const [],
    this.isDragging = false,
    this.isResizing = false,
  });

  final String? selectedShapeId;
  final List<SnapGuide> snapGuides;
  final bool isDragging;
  final bool isResizing;

  ShapeState copyWith({
    String? selectedShapeId,
    bool clearSelection = false,
    List<SnapGuide>? snapGuides,
    bool? isDragging,
    bool? isResizing,
  }) =>
      ShapeState(
        selectedShapeId:
            clearSelection ? null : (selectedShapeId ?? this.selectedShapeId),
        snapGuides: snapGuides ?? this.snapGuides,
        isDragging: isDragging ?? this.isDragging,
        isResizing: isResizing ?? this.isResizing,
      );

  @override
  List<Object?> get props => [
        selectedShapeId,
        snapGuides,
        isDragging,
        isResizing,
      ];
}
