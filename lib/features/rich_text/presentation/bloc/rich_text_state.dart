import 'package:equatable/equatable.dart';

import '../../domain/entities/rich_text_element.dart';

/// Immutable state snapshot for the rich text feature.
class RichTextState extends Equatable {
  const RichTextState({
    this.elements = const [],
    this.selectedElementId,
  });

  /// All rich text elements on the current canvas / page.
  final List<RichTextElement> elements;

  /// ID of the element being edited, or `null`.
  final String? selectedElementId;

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
  }) =>
      RichTextState(
        elements: elements ?? this.elements,
        selectedElementId: clearSelection
            ? null
            : (selectedElementId ?? this.selectedElementId),
      );

  @override
  List<Object?> get props =>
      [elements, selectedElementId];
}
