import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_annotation.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_event.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_state.dart';

/// A slide-out panel that lists all annotations across the PDF,
/// grouped by page, with tap-to-navigate and swipe-to-delete.
class PdfAnnotationListPanel extends StatelessWidget {
  const PdfAnnotationListPanel({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PdfAnnotationBloc, PdfAnnotationState>(
        builder: (context, state) {
          if (!state.isAnnotationListOpen) {
            return const SizedBox.shrink();
          }
          final bloc = context.read<PdfAnnotationBloc>();
          final theme = Theme.of(context);
          final annotations = state.annotations;

          // Group by page.
          final byPage = <int, List<PdfAnnotation>>{};
          for (final a in annotations) {
            byPage.putIfAbsent(a.pageIndex, () => []).add(a);
          }
          final sortedPages = byPage.keys.toList()..sort();

          return Container(
            width: 260,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                        semanticLabel: 'Annotations',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Annotations (${annotations.length})',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                        ),
                        tooltip: 'Close annotation list',
                        onPressed: () => bloc.add(
                          const ToggleAnnotationListPanel(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Annotation list grouped by page.
                Expanded(
                  child: annotations.isEmpty
                      ? Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons
                                      .note_alt_outlined,
                                  size: 32,
                                  color: theme.colorScheme
                                      .onSurfaceVariant,
                                  semanticLabel:
                                      'No annotations',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No annotations yet',
                                  style: theme
                                      .textTheme.bodySmall
                                      ?.copyWith(
                                    color: theme
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use the toolbar to'
                                  ' annotate PDF pages',
                                  style: theme
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                    color: theme
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  textAlign:
                                      TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: sortedPages.length,
                          itemBuilder: (context, i) {
                            final pageIdx =
                                sortedPages[i];
                            final pageAnnotations =
                                byPage[pageIdx]!;
                            return _PageAnnotationGroup(
                              pageIndex: pageIdx,
                              annotations:
                                  pageAnnotations,
                              isCurrent: pageIdx ==
                                  state.currentPageIndex,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
}

class _PageAnnotationGroup extends StatelessWidget {
  const _PageAnnotationGroup({
    required this.pageIndex,
    required this.annotations,
    required this.isCurrent,
  });

  final int pageIndex;
  final List<PdfAnnotation> annotations;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<PdfAnnotationBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header.
        InkWell(
          onTap: () => bloc.add(
            NavigateToPdfPage(pageIndex: pageIndex),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            color: isCurrent
                ? theme.colorScheme.primaryContainer
                    .withOpacity(0.3)
                : theme.colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Text(
                  'Page ${pageIndex + 1}',
                  style:
                      theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : theme
                            .colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${annotations.length}',
                  style:
                      theme.textTheme.labelSmall?.copyWith(
                    color: theme
                        .colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Individual annotations.
        ...annotations.map(
          (a) => _AnnotationTile(annotation: a),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _AnnotationTile extends StatelessWidget {
  const _AnnotationTile({required this.annotation});
  final PdfAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<PdfAnnotationBloc>();

    return Dismissible(
      key: Key(annotation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete_rounded,
          color: theme.colorScheme.onError,
          size: 18,
          semanticLabel: 'Delete',
        ),
      ),
      onDismissed: (_) => bloc.add(
        DeletePdfAnnotation(annotationId: annotation.id),
      ),
      child: ListTile(
        dense: true,
        leading: _annotationIcon(annotation.type, theme),
        title: Text(
          _annotationLabel(annotation),
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: annotation.content != null
            ? Text(
                annotation.content!,
                style:
                    theme.textTheme.labelSmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: annotation.color,
            shape: BoxShape.circle,
          ),
        ),
        onTap: () {
          // Navigate to the annotation's page.
          bloc.add(NavigateToPdfPage(
            pageIndex: annotation.pageIndex,
          ));
        },
      ),
    );
  }

  Widget _annotationIcon(
    PdfAnnotationType type,
    ThemeData theme,
  ) {
    IconData icon;
    switch (type) {
      case PdfAnnotationType.highlight:
        icon = Icons.highlight_rounded;
      case PdfAnnotationType.underline:
        icon = Icons.format_underlined_rounded;
      case PdfAnnotationType.strikethrough:
        icon = Icons.format_strikethrough_rounded;
      case PdfAnnotationType.stickyNote:
      case PdfAnnotationType.textNote:
        icon = Icons.sticky_note_2_rounded;
      case PdfAnnotationType.formField:
        icon = Icons.edit_note_rounded;
    }
    return Icon(
      icon,
      size: 16,
      color: theme.colorScheme.onSurfaceVariant,
      semanticLabel: type.name,
    );
  }

  String _annotationLabel(PdfAnnotation annotation) {
    if (annotation.selectedText != null) {
      return '"${annotation.selectedText}"';
    }
    if (annotation.content != null) {
      return annotation.content!;
    }
    if (annotation.formFieldName != null) {
      return annotation.formFieldName!;
    }
    return annotation.type.name[0].toUpperCase() +
        annotation.type.name.substring(1);
  }
}
