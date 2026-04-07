import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_bookmark.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_event.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_state.dart';

/// Side panel that lists PDF-specific bookmarks and allows the
/// user to add, rename, annotate and delete bookmarks.
class PdfBookmarkPanel extends StatelessWidget {
  const PdfBookmarkPanel({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PdfAnnotationBloc, PdfAnnotationState>(
        builder: (context, state) {
          if (!state.isBookmarkPanelOpen) {
            return const SizedBox.shrink();
          }
          final bloc = context.read<PdfAnnotationBloc>();
          final bookmarks = state.filteredBookmarks;
          final theme = Theme.of(context);

          return Container(
            width: 240,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                left: BorderSide(
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
                        Icons.bookmarks_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                        semanticLabel: 'Bookmarks',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bookmarks',
                          style:
                              theme.textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                        ),
                        tooltip: 'Close bookmarks',
                        onPressed: () => bloc.add(
                          const TogglePdfBookmarkPanel(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Search field.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search bookmarks…',
                      hintStyle:
                          theme.textTheme.bodySmall,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                      ),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.colorScheme
                              .outlineVariant,
                        ),
                      ),
                      suffixIcon:
                          state.bookmarkSearchQuery
                                  .isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 16,
                                  ),
                                  onPressed: () =>
                                      bloc.add(
                                    const SearchPdfBookmarks(
                                      query: '',
                                    ),
                                  ),
                                )
                              : null,
                    ),
                    style: theme.textTheme.bodySmall,
                    onChanged: (q) => bloc.add(
                      SearchPdfBookmarks(query: q),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Add bookmark button.
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.bookmark_add_rounded,
                        size: 16,
                      ),
                      label: Text(
                        state.isCurrentPageBookmarked
                            ? 'Page bookmarked'
                            : 'Bookmark page '
                                '${state.currentPageIndex + 1}',
                        style: theme.textTheme.labelSmall,
                      ),
                      onPressed:
                          state.isCurrentPageBookmarked
                              ? null
                              : () => bloc.add(
                                    AddPdfBookmark(
                                      bookmark:
                                          PdfBookmark(
                                        pageIndex: state
                                            .currentPageIndex,
                                      ),
                                    ),
                                  ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Bookmark list.
                Expanded(
                  child: bookmarks.isEmpty
                      ? Center(
                          child: Text(
                            'No bookmarks yet',
                            style: theme
                                .textTheme.bodySmall
                                ?.copyWith(
                              color: theme.colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: bookmarks.length,
                          separatorBuilder: (_, __) =>
                              const Divider(
                            height: 1,
                            indent: 12,
                            endIndent: 12,
                          ),
                          itemBuilder: (context, i) =>
                              _BookmarkTile(
                            bookmark: bookmarks[i],
                            isCurrent:
                                bookmarks[i].pageIndex ==
                                    state.currentPageIndex,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      );
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.bookmark,
    required this.isCurrent,
  });

  final PdfBookmark bookmark;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<PdfAnnotationBloc>();
    return ListTile(
      dense: true,
      selected: isCurrent,
      leading: Icon(
        Icons.bookmark_rounded,
        size: 18,
        color: isCurrent
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        semanticLabel: 'Bookmark',
      ),
      title: Text(
        bookmark.displayLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight:
              isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: bookmark.note != null
          ? Text(
              bookmark.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      onTap: () => bloc.add(NavigateToPdfPage(
        pageIndex: bookmark.pageIndex,
      )),
      onLongPress: () =>
          _showBookmarkOptions(context, bookmark),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          size: 16,
          color: theme.colorScheme.error,
          semanticLabel: 'Delete bookmark',
        ),
        onPressed: () => bloc.add(RemovePdfBookmark(
          bookmarkId: bookmark.id,
        )),
      ),
    );
  }

  void _showBookmarkOptions(
    BuildContext context,
    PdfBookmark bookmark,
  ) {
    final bloc = context.read<PdfAnnotationBloc>();
    final labelCtrl = TextEditingController(
      text: bookmark.label ?? '',
    );
    final noteCtrl = TextEditingController(
      text: bookmark.note ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final label =
                  labelCtrl.text.trim().isNotEmpty
                      ? labelCtrl.text.trim()
                      : null;
              final note =
                  noteCtrl.text.trim().isNotEmpty
                      ? noteCtrl.text.trim()
                      : null;
              bloc.add(UpdatePdfBookmark(
                bookmark: bookmark.copyWith(
                  label: label,
                  clearLabel: label == null,
                  note: note,
                  clearNote: note == null,
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
}
