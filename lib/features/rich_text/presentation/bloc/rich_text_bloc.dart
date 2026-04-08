import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rich_text_element.dart';
import '../../domain/entities/rich_text_node.dart';
import '../../engine/markdown_parser.dart';
import 'rich_text_event.dart';
import 'rich_text_state.dart';

/// Maximum number of undo steps to keep.
const _maxUndoHistory = 50;

/// BLoC that manages rich text elements on a canvas page.
class RichTextBloc
    extends Bloc<RichTextEvent, RichTextState> {
  RichTextBloc() : super(const RichTextState()) {
    // Element lifecycle
    on<CreateRichTextElement>(_onCreateElement);
    on<DeleteRichTextElement>(_onDeleteElement);
    on<SelectRichTextElement>(_onSelectElement);
    on<DeselectRichTextElement>(_onDeselectElement);

    // Content editing
    on<UpdateRichTextContent>(_onUpdateContent);
    on<InsertNode>(_onInsertNode);
    on<RemoveNode>(_onRemoveNode);
    on<UpdateNode>(_onUpdateNode);

    // Formatting
    on<ToggleInlineStyle>(_onToggleInlineStyle);
    on<ChangeHeadingLevel>(_onChangeHeadingLevel);
    on<SetSpanColor>(_onSetSpanColor);

    // Table operations
    on<UpdateTableCell>(_onUpdateTableCell);
    on<AddTableRow>(_onAddTableRow);
    on<AddTableColumn>(_onAddTableColumn);
    on<RemoveTableRow>(_onRemoveTableRow);
    on<RemoveTableColumn>(_onRemoveTableColumn);

    // Transform
    on<MoveRichTextElement>(_onMoveElement);
    on<ResizeRichTextElement>(_onResizeElement);

    // Undo / Redo
    on<UndoRichText>(_onUndo);
    on<RedoRichText>(_onRedo);

    // Find & replace
    on<FindInRichText>(_onFind);
    on<ReplaceInRichText>(_onReplace);
    on<ClearFind>(_onClearFind);

    // Bulk
    on<LoadRichTextElements>(_onLoadElements);
  }

  final _parser = const MarkdownParser();

  // ── Helpers ───────────────────────────────────────────────

  List<RichTextElement> _replaceElement(
    String id,
    RichTextElement Function(RichTextElement e) updater,
  ) =>
      state.elements
          .map((e) => e.id == id ? updater(e) : e)
          .toList();

  /// Push current elements onto the undo stack and clear redo.
  void _pushUndo(Emitter<RichTextState> emit) {
    final stack = [
      ...state.undoStack,
      state.elements,
    ];
    // Trim to max history size.
    final trimmed = stack.length > _maxUndoHistory
        ? stack.sublist(stack.length - _maxUndoHistory)
        : stack;
    emit(state.copyWith(
      undoStack: trimmed,
      redoStack: const [],
    ));
  }

  // ── Undo / Redo ───────────────────────────────────────────

  void _onUndo(
    UndoRichText event,
    Emitter<RichTextState> emit,
  ) {
    if (!state.canUndo) return;
    final previous = state.undoStack.last;
    final newUndo = state.undoStack
        .sublist(0, state.undoStack.length - 1);
    emit(state.copyWith(
      elements: previous,
      undoStack: newUndo,
      redoStack: [...state.redoStack, state.elements],
    ));
  }

  void _onRedo(
    RedoRichText event,
    Emitter<RichTextState> emit,
  ) {
    if (!state.canRedo) return;
    final next = state.redoStack.last;
    final newRedo = state.redoStack
        .sublist(0, state.redoStack.length - 1);
    emit(state.copyWith(
      elements: next,
      undoStack: [...state.undoStack, state.elements],
      redoStack: newRedo,
    ));
  }

  // ── Handlers ──────────────────────────────────────────────

  void _onCreateElement(
    CreateRichTextElement event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);

    final nodes = event.initialMarkdown != null
        ? _parser.parse(event.initialMarkdown!)
        : <RichTextNode>[
            const RichTextNode(
              type: RichTextNodeType.paragraph,
              spans: [RichTextSpan(text: '')],
            ),
          ];

    final element = RichTextElement(
      position: event.position,
      width: event.width,
      nodes: nodes,
      isEditing: true,
    );

    emit(state.copyWith(
      elements: [...state.elements, element],
      selectedElementId: element.id,
    ));
  }

  void _onDeleteElement(
    DeleteRichTextElement event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    final updated = state.elements
        .where((e) => e.id != event.elementId)
        .toList();
    final clearSel =
        state.selectedElementId == event.elementId;
    emit(state.copyWith(
      elements: updated,
      clearSelection: clearSel,
    ));
  }

  void _onSelectElement(
    SelectRichTextElement event,
    Emitter<RichTextState> emit,
  ) {
    final updated = state.elements
        .map(
          (e) => e.copyWith(
            isEditing: e.id == event.elementId,
          ),
        )
        .toList();
    emit(state.copyWith(
      elements: updated,
      selectedElementId: event.elementId,
    ));
  }

  void _onDeselectElement(
    DeselectRichTextElement event,
    Emitter<RichTextState> emit,
  ) {
    final updated = state.elements
        .map((e) => e.copyWith(isEditing: false))
        .toList();
    emit(state.copyWith(
      elements: updated,
      clearSelection: true,
    ));
  }

  void _onUpdateContent(
    UpdateRichTextContent event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    final nodes = _parser.parse(event.markdown);
    emit(state.copyWith(
      elements: _replaceElement(
        event.elementId,
        (e) => e.copyWith(nodes: nodes),
      ),
    ));
  }

  void _onInsertNode(
    InsertNode event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes)
          ..insert(event.index, event.node);
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onRemoveNode(
    RemoveNode event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes)
          ..removeAt(event.index);
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onUpdateNode(
    UpdateNode event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes);
        nodes[event.index] = event.node;
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onToggleInlineStyle(
    ToggleInlineStyle event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes);
        final node = nodes[event.nodeIndex];
        final spans = List<RichTextSpan>.of(node.spans);
        final span = spans[event.spanIndex];
        final styles = Set<InlineStyle>.of(span.styles);
        if (styles.contains(event.style)) {
          styles.remove(event.style);
        } else {
          styles.add(event.style);
        }
        spans[event.spanIndex] =
            span.copyWith(styles: styles);
        nodes[event.nodeIndex] =
            node.copyWith(spans: spans);
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onChangeHeadingLevel(
    ChangeHeadingLevel event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes);
        final node = nodes[event.nodeIndex];
        if (event.level == 0) {
          nodes[event.nodeIndex] = node.copyWith(
            type: RichTextNodeType.paragraph,
          );
        } else {
          nodes[event.nodeIndex] = node.copyWith(
            type: RichTextNodeType.heading,
            headingLevel: event.level,
          );
        }
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onSetSpanColor(
    SetSpanColor event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes);
        final node = nodes[event.nodeIndex];
        final spans = List<RichTextSpan>.of(node.spans);
        spans[event.spanIndex] = spans[event.spanIndex]
            .copyWith(
              color: event.color,
              clearColor: event.color == null,
            );
        nodes[event.nodeIndex] =
            node.copyWith(spans: spans);
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onUpdateTableCell(
    UpdateTableCell event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes);
        final node = nodes[event.nodeIndex];
        if (node.tableData == null) return e;
        final data = node.tableData!
            .map((r) => List<String>.of(r))
            .toList();
        data[event.row][event.col] = event.value;
        nodes[event.nodeIndex] =
            node.copyWith(tableData: data);
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onAddTableRow(
    AddTableRow event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes);
        final node = nodes[event.nodeIndex];
        if (node.tableData == null) return e;
        final cols = node.tableData!.isNotEmpty
            ? node.tableData!.first.length
            : 1;
        final data =
            List<List<String>>.of(node.tableData!)
              ..add(List.filled(cols, ''));
        nodes[event.nodeIndex] =
            node.copyWith(tableData: data);
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onAddTableColumn(
    AddTableColumn event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes);
        final node = nodes[event.nodeIndex];
        if (node.tableData == null) return e;
        final data = node.tableData!
            .map((r) => [...r, ''])
            .toList();
        nodes[event.nodeIndex] =
            node.copyWith(tableData: data);
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onRemoveTableRow(
    RemoveTableRow event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes);
        final node = nodes[event.nodeIndex];
        if (node.tableData == null ||
            node.tableData!.length <= 1) {
          return e;
        }
        final data = node.tableData!
            .map((r) => List<String>.of(r))
            .toList()
          ..removeAt(event.row);
        nodes[event.nodeIndex] =
            node.copyWith(tableData: data);
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onRemoveTableColumn(
    RemoveTableColumn event,
    Emitter<RichTextState> emit,
  ) {
    _pushUndo(emit);
    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = List<RichTextNode>.of(e.nodes);
        final node = nodes[event.nodeIndex];
        if (node.tableData == null) return e;
        if (node.tableData!.isNotEmpty &&
            node.tableData!.first.length <= 1) {
          return e;
        }
        final data = node.tableData!
            .map((r) {
              final row = List<String>.of(r);
              if (event.col < row.length) {
                row.removeAt(event.col);
              }
              return row;
            })
            .toList();
        nodes[event.nodeIndex] =
            node.copyWith(tableData: data);
        return e.copyWith(nodes: nodes);
      }),
    ));
  }

  void _onMoveElement(
    MoveRichTextElement event,
    Emitter<RichTextState> emit,
  ) =>
      emit(state.copyWith(
        elements: _replaceElement(
          event.elementId,
          (e) => e.copyWith(position: event.position),
        ),
      ));

  void _onResizeElement(
    ResizeRichTextElement event,
    Emitter<RichTextState> emit,
  ) =>
      emit(state.copyWith(
        elements: _replaceElement(
          event.elementId,
          (e) => e.copyWith(width: event.width),
        ),
      ));

  // ── Find & Replace ────────────────────────────────────────

  void _onFind(
    FindInRichText event,
    Emitter<RichTextState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(state.copyWith(
        findQuery: '',
        findMatchCount: 0,
      ));
      return;
    }
    final query = event.query.toLowerCase();
    var count = 0;
    for (final element in state.elements) {
      final text = element.plainText.toLowerCase();
      var idx = 0;
      while (true) {
        idx = text.indexOf(query, idx);
        if (idx == -1) break;
        count++;
        idx += query.length;
      }
    }
    emit(state.copyWith(
      findQuery: event.query,
      findMatchCount: count,
    ));
  }

  void _onReplace(
    ReplaceInRichText event,
    Emitter<RichTextState> emit,
  ) {
    if (event.query.isEmpty) return;
    _pushUndo(emit);

    emit(state.copyWith(
      elements: _replaceElement(event.elementId, (e) {
        final nodes = e.nodes.map((node) {
          if (node.spans.isEmpty) return node;
          final updatedSpans = node.spans.map((span) {
            var text = span.text;
            if (event.replaceAll) {
              text = text.replaceAll(
                event.query,
                event.replacement,
              );
            } else {
              text = text.replaceFirst(
                event.query,
                event.replacement,
              );
            }
            return span.copyWith(text: text);
          }).toList();
          return node.copyWith(spans: updatedSpans);
        }).toList();
        return e.copyWith(nodes: nodes);
      }),
    ));

    // Re-count matches after replacement.
    add(FindInRichText(query: event.query));
  }

  void _onClearFind(
    ClearFind event,
    Emitter<RichTextState> emit,
  ) {
    emit(state.copyWith(
      findQuery: '',
      findMatchCount: 0,
    ));
  }

  void _onLoadElements(
    LoadRichTextElements event,
    Emitter<RichTextState> emit,
  ) =>
      emit(state.copyWith(elements: event.elements));
}
