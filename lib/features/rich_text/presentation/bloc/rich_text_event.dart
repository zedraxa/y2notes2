import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/rich_text_element.dart';
import '../../domain/entities/rich_text_node.dart';

/// Base class for all rich text editor events.
abstract class RichTextEvent extends Equatable {
  const RichTextEvent();

  @override
  List<Object?> get props => [];
}

// ── Element lifecycle ───────────────────────────────────────

/// Create a new rich text element at the given position.
class CreateRichTextElement extends RichTextEvent {
  const CreateRichTextElement({
    required this.position,
    this.width = 400.0,
    this.initialMarkdown,
  });

  final Offset position;
  final double width;
  final String? initialMarkdown;

  @override
  List<Object?> get props =>
      [position, width, initialMarkdown];
}

/// Remove a rich text element by ID.
class DeleteRichTextElement extends RichTextEvent {
  const DeleteRichTextElement({required this.elementId});
  final String elementId;

  @override
  List<Object?> get props => [elementId];
}

/// Select an element for editing.
class SelectRichTextElement extends RichTextEvent {
  const SelectRichTextElement({required this.elementId});
  final String elementId;

  @override
  List<Object?> get props => [elementId];
}

/// Deselect the currently active element.
class DeselectRichTextElement extends RichTextEvent {
  const DeselectRichTextElement();
}

// ── Content editing ─────────────────────────────────────────

/// Replace the full markdown content of an element.
class UpdateRichTextContent extends RichTextEvent {
  const UpdateRichTextContent({
    required this.elementId,
    required this.markdown,
  });

  final String elementId;
  final String markdown;

  @override
  List<Object?> get props => [elementId, markdown];
}

/// Insert a new node at the given index within an element.
class InsertNode extends RichTextEvent {
  const InsertNode({
    required this.elementId,
    required this.index,
    required this.node,
  });

  final String elementId;
  final int index;
  final RichTextNode node;

  @override
  List<Object?> get props => [elementId, index, node];
}

/// Remove a node at the given index.
class RemoveNode extends RichTextEvent {
  const RemoveNode({
    required this.elementId,
    required this.index,
  });

  final String elementId;
  final int index;

  @override
  List<Object?> get props => [elementId, index];
}

/// Replace the node at [index] with [node].
class UpdateNode extends RichTextEvent {
  const UpdateNode({
    required this.elementId,
    required this.index,
    required this.node,
  });

  final String elementId;
  final int index;
  final RichTextNode node;

  @override
  List<Object?> get props => [elementId, index, node];
}

// ── Formatting ──────────────────────────────────────────────

/// Toggle an inline style on the active selection.
class ToggleInlineStyle extends RichTextEvent {
  const ToggleInlineStyle({
    required this.elementId,
    required this.nodeIndex,
    required this.spanIndex,
    required this.style,
  });

  final String elementId;
  final int nodeIndex;
  final int spanIndex;
  final InlineStyle style;

  @override
  List<Object?> get props =>
      [elementId, nodeIndex, spanIndex, style];
}

/// Change the heading level of a node.
class ChangeHeadingLevel extends RichTextEvent {
  const ChangeHeadingLevel({
    required this.elementId,
    required this.nodeIndex,
    required this.level,
  });

  final String elementId;
  final int nodeIndex;

  /// 0 = convert to paragraph; 1–6 = heading level.
  final int level;

  @override
  List<Object?> get props =>
      [elementId, nodeIndex, level];
}

// ── Table operations ────────────────────────────────────────

/// Update a cell value in a table node.
class UpdateTableCell extends RichTextEvent {
  const UpdateTableCell({
    required this.elementId,
    required this.nodeIndex,
    required this.row,
    required this.col,
    required this.value,
  });

  final String elementId;
  final int nodeIndex;
  final int row;
  final int col;
  final String value;

  @override
  List<Object?> get props =>
      [elementId, nodeIndex, row, col, value];
}

/// Add a row to a table node.
class AddTableRow extends RichTextEvent {
  const AddTableRow({
    required this.elementId,
    required this.nodeIndex,
  });

  final String elementId;
  final int nodeIndex;

  @override
  List<Object?> get props => [elementId, nodeIndex];
}

/// Add a column to a table node.
class AddTableColumn extends RichTextEvent {
  const AddTableColumn({
    required this.elementId,
    required this.nodeIndex,
  });

  final String elementId;
  final int nodeIndex;

  @override
  List<Object?> get props => [elementId, nodeIndex];
}

// ── Element transform ───────────────────────────────────────

/// Move a rich text element to a new position.
class MoveRichTextElement extends RichTextEvent {
  const MoveRichTextElement({
    required this.elementId,
    required this.position,
  });

  final String elementId;
  final Offset position;

  @override
  List<Object?> get props => [elementId, position];
}

/// Resize the width of a rich text element.
class ResizeRichTextElement extends RichTextEvent {
  const ResizeRichTextElement({
    required this.elementId,
    required this.width,
  });

  final String elementId;
  final double width;

  @override
  List<Object?> get props => [elementId, width];
}

// ── Bulk operations ─────────────────────────────────────────

/// Load a list of elements (e.g. from persisted state).
class LoadRichTextElements extends RichTextEvent {
  const LoadRichTextElements({
    required this.elements,
  });

  final List<RichTextElement> elements;

  @override
  List<Object?> get props => [elements];
}
