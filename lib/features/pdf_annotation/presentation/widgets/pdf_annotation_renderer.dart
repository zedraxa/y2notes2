import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_annotation.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_event.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_state.dart';

/// Renders all annotations for the current PDF page on top of the
/// rasterised content.
///
/// Highlights are translucent rectangles, underlines and
/// strikethroughs are styled lines, and sticky notes render as
/// small coloured icons that expand into an editable card on tap.
class PdfAnnotationRenderer extends StatelessWidget {
  const PdfAnnotationRenderer({
    super.key,
    required this.pageSize,
  });

  /// Size of the rendered PDF page widget.
  final Size pageSize;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PdfAnnotationBloc, PdfAnnotationState>(
        builder: (context, state) {
          final annotations = state.currentPageAnnotations;
          if (annotations.isEmpty) {
            return SizedBox.fromSize(size: pageSize);
          }

          return SizedBox.fromSize(
            size: pageSize,
            child: Stack(
              children: annotations.map((a) {
                switch (a.type) {
                  case PdfAnnotationType.highlight:
                    return _HighlightAnnotation(
                      annotation: a,
                    );
                  case PdfAnnotationType.underline:
                    return _UnderlineAnnotation(
                      annotation: a,
                    );
                  case PdfAnnotationType.strikethrough:
                    return _StrikethroughAnnotation(
                      annotation: a,
                    );
                  case PdfAnnotationType.stickyNote:
                  case PdfAnnotationType.textNote:
                    return _StickyNoteAnnotation(
                      annotation: a,
                    );
                  case PdfAnnotationType.formField:
                    return _FormFieldAnnotation(
                      annotation: a,
                    );
                }
              }).toList(),
            ),
          );
        },
      );
}

// ── Highlight ──────────────────────────────────────────────────

class _HighlightAnnotation extends StatelessWidget {
  const _HighlightAnnotation({required this.annotation});
  final PdfAnnotation annotation;

  @override
  Widget build(BuildContext context) => Positioned(
        left: annotation.rect.left,
        top: annotation.rect.top,
        width: annotation.rect.width,
        height: annotation.rect.height,
        child: GestureDetector(
          onLongPress: () => _showAnnotationMenu(
            context,
            annotation,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: annotation.color
                  .withOpacity(annotation.opacity * 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
}

// ── Underline ──────────────────────────────────────────────────

class _UnderlineAnnotation extends StatelessWidget {
  const _UnderlineAnnotation({required this.annotation});
  final PdfAnnotation annotation;

  @override
  Widget build(BuildContext context) => Positioned(
        left: annotation.rect.left,
        top: annotation.rect.bottom - 2,
        width: annotation.rect.width,
        height: 2,
        child: GestureDetector(
          onLongPress: () => _showAnnotationMenu(
            context,
            annotation,
          ),
          child: Container(color: annotation.color),
        ),
      );
}

// ── Strikethrough ──────────────────────────────────────────────

class _StrikethroughAnnotation extends StatelessWidget {
  const _StrikethroughAnnotation({required this.annotation});
  final PdfAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final midY = annotation.rect.top +
        annotation.rect.height / 2;
    return Positioned(
      left: annotation.rect.left,
      top: midY - 1,
      width: annotation.rect.width,
      height: 2,
      child: GestureDetector(
        onLongPress: () => _showAnnotationMenu(
          context,
          annotation,
        ),
        child: Container(color: annotation.color),
      ),
    );
  }
}

// ── Sticky note ────────────────────────────────────────────────

class _StickyNoteAnnotation extends StatelessWidget {
  const _StickyNoteAnnotation({required this.annotation});
  final PdfAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: annotation.rect.left,
      top: annotation.rect.top,
      child: GestureDetector(
        onTap: () => _showStickyNoteDialog(
          context,
          annotation,
        ),
        onLongPress: () => _showAnnotationMenu(
          context,
          annotation,
        ),
        child: Tooltip(
          message: annotation.content ?? 'Sticky note',
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: annotation.color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 3,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.sticky_note_2_rounded,
              size: 18,
              color: theme.colorScheme.onSurface,
              semanticLabel: 'Sticky note',
            ),
          ),
        ),
      ),
    );
  }
}

// ── Form field ─────────────────────────────────────────────────

class _FormFieldAnnotation extends StatelessWidget {
  const _FormFieldAnnotation({required this.annotation});
  final PdfAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: annotation.rect.left,
      top: annotation.rect.top,
      width: annotation.rect.width,
      height: annotation.rect.height,
      child: GestureDetector(
        onTap: () => _showFormFieldDialog(
          context,
          annotation,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border.all(
              color: theme.colorScheme.primary
                  .withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            annotation.formFieldValue ?? '',
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────

void _showAnnotationMenu(
  BuildContext context,
  PdfAnnotation annotation,
) {
  final bloc = context.read<PdfAnnotationBloc>();
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (annotation.selectedText != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Text(
                '"${annotation.selectedText}"',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (annotation.type == PdfAnnotationType.stickyNote ||
              annotation.type == PdfAnnotationType.textNote)
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit note'),
              onTap: () {
                Navigator.pop(context);
                _showStickyNoteDialog(context, annotation);
              },
            ),
          // Colour picker row for all annotation types.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                Text(
                  'Colour',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium,
                ),
                const SizedBox(width: 12),
                ..._annotationColors.map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        bloc.add(ChangeAnnotationColor(
                          annotationId: annotation.id,
                          color: c,
                        ));
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: annotation.color == c
                              ? Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  width: 2,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            title: const Text(
              'Delete annotation',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              bloc.add(DeletePdfAnnotation(
                annotationId: annotation.id,
              ));
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

const _annotationColors = [
  Color(0x80FFEB3B), // Yellow
  Color(0x804CAF50), // Green
  Color(0x802196F3), // Blue
  Color(0x80F44336), // Red
  Color(0x80E91E63), // Pink
  Color(0x80FF9800), // Orange
];

void _showStickyNoteDialog(
  BuildContext context,
  PdfAnnotation annotation,
) {
  final bloc = context.read<PdfAnnotationBloc>();
  final controller = TextEditingController(
    text: annotation.content ?? '',
  );
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sticky Note'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Enter your note…',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            bloc.add(UpdatePdfAnnotation(
              annotation: annotation.copyWith(
                content: controller.text,
              ),
            ));
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showFormFieldDialog(
  BuildContext context,
  PdfAnnotation annotation,
) {
  final bloc = context.read<PdfAnnotationBloc>();
  final controller = TextEditingController(
    text: annotation.formFieldValue ?? '',
  );
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        annotation.formFieldName ?? 'Form Field',
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter value…',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            bloc.add(UpdatePdfAnnotation(
              annotation: annotation.copyWith(
                formFieldValue: controller.text,
              ),
            ));
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
