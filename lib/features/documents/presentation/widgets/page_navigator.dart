import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/documents/domain/entities/notebook_page.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_event.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_state.dart';

/// Thumbnail strip shown at the bottom of the canvas. Displays all notebook
/// pages and lets the user navigate between them.
class PageNavigator extends StatelessWidget {
  const PageNavigator({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          if (!state.hasNotebook || state.pageCount == 0) {
            return const SizedBox.shrink();
          }
          final bloc = context.read<DocumentBloc>();
          return _PageNavigatorContent(
            pages: state.notebook!.pages,
            currentIndex: state.currentPageIndex,
            onPageTap: (i) => bloc.add(NavigateToPage(pageIndex: i)),
            onAddPage: () => bloc.add(AddPage(
              insertAfterIndex: state.currentPageIndex,
            )),
            onPageLongPress: (i) =>
                _showPageOptions(context, bloc, i, state.notebook!.pageCount,
                    state.notebook!.pages[i]),
          );
        },
      );

  void _showPageOptions(
    BuildContext context,
    DocumentBloc bloc,
    int pageIndex,
    int totalPages,
    NotebookPage page,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _PageOptionsSheet(
        pageIndex: pageIndex,
        totalPages: totalPages,
        bloc: bloc,
        page: page,
      ),
    );
  }
}

class _PageNavigatorContent extends StatelessWidget {
  const _PageNavigatorContent({
    required this.pages,
    required this.currentIndex,
    required this.onPageTap,
    required this.onAddPage,
    required this.onPageLongPress,
  });

  final List<NotebookPage> pages;
  final int currentIndex;
  final ValueChanged<int> onPageTap;
  final VoidCallback onAddPage;
  final ValueChanged<int> onPageLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Page thumbnails.
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: pages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) => _PageThumbnail(
                pageNumber: pages[i].pageNumber,
                isSelected: i == currentIndex,
                isBookmarked: pages[i].isBookmarked,
                title: pages[i].title,
                onTap: () => onPageTap(i),
                onLongPress: () => onPageLongPress(i),
              ),
            ),
          ),
          // Page counter.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${currentIndex + 1} / ${pages.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Add page button.
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add page',
            onPressed: onAddPage,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _PageThumbnail extends StatelessWidget {
  const _PageThumbnail({
    required this.pageNumber,
    required this.isSelected,
    required this.isBookmarked,
    this.title,
    required this.onTap,
    required this.onLongPress,
  });

  final int pageNumber;
  final bool isSelected;
  final bool isBookmarked;
  final String? title;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final borderWidth = isSelected ? 2.0 : 1.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 62,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 6,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pageNumber',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        title!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 7,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (isBookmarked)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.bookmark_rounded,
                  size: 10,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet action menu for a single page.
class _PageOptionsSheet extends StatelessWidget {
  const _PageOptionsSheet({
    required this.pageIndex,
    required this.totalPages,
    required this.bloc,
    required this.page,
  });

  final int pageIndex;
  final int totalPages;
  final DocumentBloc bloc;
  final NotebookPage page;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _sheetHandle(context),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(
              page.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
            title: Text(
              page.isBookmarked ? 'Remove bookmark' : 'Bookmark page',
            ),
            onTap: () {
              Navigator.pop(context);
              bloc.add(TogglePageBookmark(pageIndex: pageIndex));
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Set page title'),
            subtitle: page.title != null ? Text(page.title!) : null,
            onTap: () {
              Navigator.pop(context);
              _showRenamePage(context);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.add_to_photos_outlined),
            title: const Text('Insert page before'),
            onTap: () {
              Navigator.pop(context);
              bloc.add(AddPage(insertAfterIndex: pageIndex - 1));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_to_photos),
            title: const Text('Insert page after'),
            onTap: () {
              Navigator.pop(context);
              bloc.add(AddPage(insertAfterIndex: pageIndex));
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('Duplicate page'),
            onTap: () {
              Navigator.pop(context);
              bloc.add(DuplicatePage(pageIndex: pageIndex));
            },
          ),
          if (totalPages > 1)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete page',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                bloc.add(DeletePage(pageIndex: pageIndex));
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showRenamePage(BuildContext context) {
    final controller = TextEditingController(text: page.title ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Page ${page.pageNumber} title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter page title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            final value = controller.text.trim();
            bloc.add(UpdatePageTitle(
              pageIndex: pageIndex,
              title: value.isEmpty ? null : value,
            ));
            Navigator.pop(dialogContext);
          },
        ),
        actions: [
          if (page.title != null)
            TextButton(
              onPressed: () {
                bloc.add(UpdatePageTitle(pageIndex: pageIndex));
                Navigator.pop(dialogContext);
              },
              child: const Text('Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              bloc.add(UpdatePageTitle(
                pageIndex: pageIndex,
                title: value.isEmpty ? null : value,
              ));
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _sheetHandle(BuildContext context) => Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
