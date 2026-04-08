import 'package:equatable/equatable.dart';

import '../../domain/entities/rich_text_element.dart';

/// Immutable state snapshot for the rich text feature.
class RichTextState extends Equatable {
  const RichTextState({
    this.elements = const [],
    this.selectedElementId,
    this.undoStack = const [],
    this.redoStack = const [],
    this.findQuery = '',
    this.findMatchCount = 0,
  });

  /// All rich text elements on the current canvas / page.
  final List<RichTextElement> elements;

  /// ID of the element being edited, or `null`.
  final String? selectedElementId;

  /// Previous states for undo.
  final List<List<RichTextElement>> undoStack;

  /// States that were undone, for redo.
  final List<List<RichTextElement>> redoStack;

  /// Current find query (empty = no active search).
  final String findQuery;

  /// Number of matches for the current find query.
  final int findMatchCount;

  /// Whether undo is available.
  bool get canUndo => undoStack.isNotEmpty;

  /// Whether redo is available.
  bool get canRedo => redoStack.isNotEmpty;

  /// The currently selected element, if any.
  RichTextElement? get selectedElement =>
      selectedElementId == null
          ? null
          : elements.cast<RichTextElement?>().firstWhere(
                (e) => e?.id == selectedElementId,
                orElse: () => null,
              );

  RichTextState copyWith({
    List<RichTextElement>? elements,
    String? selectedElementId,
    bool clearSelection = false,
    List<List<RichTextElement>>? undoStack,
    List<List<RichTextElement>>? redoStack,
    String? findQuery,
    int? findMatchCount,
  }) =>
      RichTextState(
        elements: elements ?? this.elements,
        selectedElementId: clearSelection
            ? null
            : (selectedElementId ?? this.selectedElementId),
        undoStack: undoStack ?? this.undoStack,
        redoStack: redoStack ?? this.redoStack,
        findQuery: findQuery ?? this.findQuery,
        findMatchCount:
            findMatchCount ?? this.findMatchCount,
      );

  @override
  List<Object?> get props => [
        elements,
        selectedElementId,
        undoStack,
        redoStack,
        findQuery,
        findMatchCount,
      ];
}
