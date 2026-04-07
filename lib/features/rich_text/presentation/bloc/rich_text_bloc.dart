import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rich_text_element.dart';
import '../../domain/entities/rich_text_node.dart';
import '../../engine/markdown_parser.dart';
import 'rich_text_event.dart';
import 'rich_text_state.dart';

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

    // Table operations
    on<UpdateTableCell>(_onUpdateTableCell);
    on<AddTableRow>(_onAddTableRow);
    on<AddTableColumn>(_onAddTableColumn);

    // Transform
    on<MoveRichTextElement>(_onMoveElement);
    on<ResizeRichTextElement>(_onResizeElement);

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

  // ── Handlers ──────────────────────────────────────────────

  void _onCreateElement(
    CreateRichTextElement event,
    Emitter<RichTextState> emit,
  ) {
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
    // Mark the selected element as editing, others as
    // not editing.
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
  ) =>
      emit(state.copyWith(
        elements: _replaceElement(event.elementId, (e) {
          final nodes = List<RichTextNode>.of(e.nodes)
            ..insert(event.index, event.node);
          return e.copyWith(nodes: nodes);
        }),
      ));

  void _onRemoveNode(
    RemoveNode event,
    Emitter<RichTextState> emit,
  ) =>
      emit(state.copyWith(
        elements: _replaceElement(event.elementId, (e) {
          final nodes = List<RichTextNode>.of(e.nodes)
            ..removeAt(event.index);
          return e.copyWith(nodes: nodes);
        }),
      ));

  void _onUpdateNode(
    UpdateNode event,
    Emitter<RichTextState> emit,
  ) =>
      emit(state.copyWith(
        elements: _replaceElement(event.elementId, (e) {
          final nodes = List<RichTextNode>.of(e.nodes);
          nodes[event.index] = event.node;
          return e.copyWith(nodes: nodes);
        }),
      ));

  void _onToggleInlineStyle(
    ToggleInlineStyle event,
    Emitter<RichTextState> emit,
  ) =>
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

  void _onChangeHeadingLevel(
    ChangeHeadingLevel event,
    Emitter<RichTextState> emit,
  ) =>
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

  void _onUpdateTableCell(
    UpdateTableCell event,
    Emitter<RichTextState> emit,
  ) =>
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

  void _onAddTableRow(
    AddTableRow event,
    Emitter<RichTextState> emit,
  ) =>
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

  void _onAddTableColumn(
    AddTableColumn event,
    Emitter<RichTextState> emit,
  ) =>
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

  void _onLoadElements(
    LoadRichTextElements event,
    Emitter<RichTextState> emit,
  ) =>
      emit(state.copyWith(elements: event.elements));
}
