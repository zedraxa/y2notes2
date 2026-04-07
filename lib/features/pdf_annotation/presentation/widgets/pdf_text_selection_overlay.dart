import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_annotation.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_text_span.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_event.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_state.dart';

/// Overlay that renders selectable text spans on top of the
/// rasterised PDF page.
///
/// Allows the user to tap-and-drag to select text, then apply
/// highlight / underline / strikethrough or copy the selection.
class PdfTextSelectionOverlay extends StatefulWidget {
  const PdfTextSelectionOverlay({
    super.key,
    required this.pageSize,
  });

  /// The rendered page size in logical pixels so we can scale the
  /// text-span rectangles from PDF coordinates to widget
  /// coordinates.
  final Size pageSize;

  @override
  State<PdfTextSelectionOverlay> createState() =>
      _PdfTextSelectionOverlayState();
}

class _PdfTextSelectionOverlayState
    extends State<PdfTextSelectionOverlay> {
  int? _dragStartIndex;

  int? _hitTestSpan(
    Offset localPosition,
    List<PdfTextSpan> spans,
  ) {
    for (int i = 0; i < spans.length; i++) {
      if (spans[i].rect.contains(localPosition)) return i;
    }
    return null;
  }

  void _onPanStart(
    DragStartDetails details,
    List<PdfTextSpan> spans,
    PdfAnnotationBloc bloc,
  ) {
    final idx = _hitTestSpan(details.localPosition, spans);
    if (idx != null) {
      _dragStartIndex = idx;
      bloc.add(SelectPdfText(
        startSpanIndex: idx,
        endSpanIndex: idx,
      ));
    }
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    List<PdfTextSpan> spans,
    PdfAnnotationBloc bloc,
  ) {
    if (_dragStartIndex == null) return;
    final idx = _hitTestSpan(details.localPosition, spans);
    if (idx != null) {
      bloc.add(SelectPdfText(
        startSpanIndex: _dragStartIndex!,
        endSpanIndex: idx,
      ));
    }
  }

  void _onPanEnd(
    DragEndDetails details,
    PdfAnnotationState state,
    PdfAnnotationBloc bloc,
  ) {
    _dragStartIndex = null;
    // If a text-markup tool is active, create annotation
    // immediately.
    if (state.hasSelection && state.selectionRect != null) {
      final tool = state.activeTool;
      PdfAnnotationType? type;
      switch (tool) {
        case PdfAnnotationTool.highlight:
          type = PdfAnnotationType.highlight;
        case PdfAnnotationTool.underline:
          type = PdfAnnotationType.underline;
        case PdfAnnotationTool.strikethrough:
          type = PdfAnnotationType.strikethrough;
        default:
          break;
      }
      if (type != null) {
        bloc.add(AddPdfAnnotation(
          annotation: PdfAnnotation(
            pageIndex: state.currentPageIndex,
            type: type,
            rect: state.selectionRect!,
            color: state.activeColor,
            selectedText: state.selectedText,
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PdfAnnotationBloc, PdfAnnotationState>(
        builder: (context, state) {
          final bloc = context.read<PdfAnnotationBloc>();
          final spans = state.currentPageTextSpans;
          final isTextTool = state.activeTool ==
                  PdfAnnotationTool.textSelect ||
              state.activeTool == PdfAnnotationTool.highlight ||
              state.activeTool == PdfAnnotationTool.underline ||
              state.activeTool ==
                  PdfAnnotationTool.strikethrough;

          if (spans.isEmpty || !isTextTool) {
            return const SizedBox.expand();
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (d) => _onPanStart(d, spans, bloc),
            onPanUpdate: (d) =>
                _onPanUpdate(d, spans, bloc),
            onPanEnd: (d) => _onPanEnd(d, state, bloc),
            child: CustomPaint(
              size: widget.pageSize,
              painter: _TextSelectionPainter(
                spans: spans,
                startIndex: state.selectedStartSpanIndex,
                endIndex: state.selectedEndSpanIndex,
                selectionColor:
                    state.activeColor.withOpacity(0.35),
              ),
              child: state.hasSelection
                  ? _SelectionActionBar(
                      selectedText: state.selectedText,
                      onCopy: () {
                        final text = state.selectedText;
                        if (text != null) {
                          Clipboard.setData(
                            ClipboardData(text: text),
                          );
                        }
                        bloc.add(
                          const ClearPdfTextSelection(),
                        );
                      },
                      onHighlight: () {
                        if (state.selectionRect == null) {
                          return;
                        }
                        bloc.add(AddPdfAnnotation(
                          annotation: PdfAnnotation(
                            pageIndex:
                                state.currentPageIndex,
                            type:
                                PdfAnnotationType.highlight,
                            rect: state.selectionRect!,
                            color: state.activeColor,
                            selectedText:
                                state.selectedText,
                          ),
                        ));
                      },
                      onDismiss: () => bloc.add(
                        const ClearPdfTextSelection(),
                      ),
                    )
                  : null,
            ),
          );
        },
      );
}

/// Paints the selection highlight over the selected text spans.
class _TextSelectionPainter extends CustomPainter {
  _TextSelectionPainter({
    required this.spans,
    required this.startIndex,
    required this.endIndex,
    required this.selectionColor,
  });

  final List<PdfTextSpan> spans;
  final int? startIndex;
  final int? endIndex;
  final Color selectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (startIndex == null || endIndex == null) return;
    final lo = startIndex! < endIndex!
        ? startIndex!
        : endIndex!;
    final hi = startIndex! < endIndex!
        ? endIndex!
        : startIndex!;
    if (lo < 0 || hi >= spans.length) return;

    final paint = Paint()..color = selectionColor;
    for (int i = lo; i <= hi; i++) {
      canvas.drawRect(spans[i].rect, paint);
    }
  }

  @override
  bool shouldRepaint(_TextSelectionPainter old) =>
      old.startIndex != startIndex ||
      old.endIndex != endIndex ||
      old.selectionColor != selectionColor;
}

/// Floating action bar shown above a text selection with Copy /
/// Highlight / Dismiss buttons.
class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.selectedText,
    required this.onCopy,
    required this.onHighlight,
    required this.onDismiss,
  });

  final String? selectedText;
  final VoidCallback onCopy;
  final VoidCallback onHighlight;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  iconSize: 18,
                  tooltip: 'Copy',
                  onPressed: onCopy,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.highlight_rounded,
                  ),
                  iconSize: 18,
                  tooltip: 'Highlight',
                  onPressed: onHighlight,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 18,
                  tooltip: 'Dismiss',
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
