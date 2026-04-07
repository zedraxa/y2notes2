import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/documents/domain/entities/notebook.dart';
import 'package:y2notes2/features/documents/domain/entities/notebook_page.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_event.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_state.dart';

/// A slide-out panel that shows a table-of-contents / outline view of the
/// current notebook.  Displays all pages grouped by bookmarked status, with
/// quick navigation, bookmark toggling, and inline title editing.
class OutlinePanel extends StatelessWidget {
  const OutlinePanel({super.key});

  static const double width = 280;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DocumentBloc, DocumentState>(
        buildWhen: (prev, curr) =>
            prev.notebook != curr.notebook ||
            prev.currentPageIndex != curr.currentPageIndex ||
            prev.isOutlineOpen != curr.isOutlineOpen,
        builder: (context, state) {
          if (!state.isOutlineOpen || !state.hasNotebook) {
            return const SizedBox.shrink();
          }
          return _OutlinePanelBody(
            notebook: state.notebook!,
            currentPageIndex: state.currentPageIndex,
          );
        },
      );
}

class _OutlinePanelBody extends StatelessWidget {
  const _OutlinePanelBody({
    required this.notebook,
    required this.currentPageIndex,
  });

  final Notebook notebook;
  final int currentPageIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<DocumentBloc>();
    final bookmarked = notebook.bookmarkedPages;

    return Container(
      width: OutlinePanel.width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _PanelHeader(title: notebook.title, bloc: bloc),
          const Divider(height: 1),

          // ── Bookmarks section ───────────────────────────────────────────
          if (bookmarked.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Bookmarks',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...bookmarked.map(
              (page) => _OutlinePageTile(
                page: page,
                isSelected:
                    notebook.pages.indexOf(page) == currentPageIndex,
                onTap: () => bloc.add(
                  NavigateToPage(
                    pageIndex: notebook.pages.indexOf(page),
                  ),
                ),
                onBookmarkToggle: () => bloc.add(
                  TogglePageBookmark(
                    pageIndex: notebook.pages.indexOf(page),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],

          // ── All pages section ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'All Pages',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: notebook.pages.length,
              itemBuilder: (context, i) {
                final page = notebook.pages[i];
                return _OutlinePageTile(
                  page: page,
                  isSelected: i == currentPageIndex,
                  onTap: () => bloc.add(NavigateToPage(pageIndex: i)),
                  onBookmarkToggle: () =>
                      bloc.add(TogglePageBookmark(pageIndex: i)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.bloc});

  final String title;
  final DocumentBloc bloc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Close outline',
            onPressed: () => bloc.add(const ToggleOutlinePanel()),
          ),
        ],
      ),
    );
  }
}

/// A single row in the outline panel representing one page.
class _OutlinePageTile extends StatelessWidget {
  const _OutlinePageTile({
    required this.page,
    required this.isSelected,
    required this.onTap,
    required this.onBookmarkToggle,
  });

  final NotebookPage page;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onBookmarkToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.45)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Page number badge.
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${page.pageNumber}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Title.
              Expanded(
                child: Text(
                  page.displayTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: page.title != null
                        ? null
                        : theme.colorScheme.onSurfaceVariant,
                    fontStyle:
                        page.title != null ? null : FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Bookmark toggle.
              Semantics(
                label: page.isBookmarked
                    ? 'Remove bookmark'
                    : 'Add bookmark',
                child: IconButton(
                  icon: Icon(
                    page.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                    color: page.isBookmarked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.5),
                  ),
                  tooltip: page.isBookmarked
                      ? 'Remove bookmark'
                      : 'Bookmark page',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: onBookmarkToggle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
