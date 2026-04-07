import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_annotation.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_bookmark.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_event.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_state.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/widgets/pdf_annotation_list_panel.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/widgets/pdf_annotation_renderer.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/widgets/pdf_annotation_toolbar.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/widgets/pdf_bookmark_panel.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/widgets/pdf_text_selection_overlay.dart';

/// Full-screen page for viewing and annotating a PDF document.
///
/// Combines a rasterised PDF page viewer with annotation overlays,
/// a toolbar, a bookmark panel and page navigation controls.
class PdfAnnotationPage extends StatelessWidget {
  const PdfAnnotationPage({
    super.key,
    required this.filePath,
    this.title,
    this.initialPageCount = 1,
  });

  /// Path to the PDF file.
  final String filePath;

  /// Optional document title.
  final String? title;

  /// Number of pages in the PDF (set when opening the
  /// document via the import engine).
  final int initialPageCount;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(
        create: (_) => PdfAnnotationBloc()
          ..add(OpenPdfForAnnotation(
            filePath: filePath,
            pageCount: initialPageCount,
            title: title,
          )),
        child: const _PdfAnnotationView(),
      );
}

class _PdfAnnotationView extends StatelessWidget {
  const _PdfAnnotationView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PdfAnnotationBloc, PdfAnnotationState>(
        builder: (context, state) {
          final bloc = context.read<PdfAnnotationBloc>();
          final theme = Theme.of(context);

          return CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.arrowLeft):
                  () {
                if (state.canGoBack) {
                  bloc.add(NavigateToPdfPage(
                    pageIndex: state.currentPageIndex - 1,
                  ));
                }
              },
              const SingleActivator(LogicalKeyboardKey.arrowRight):
                  () {
                if (state.canGoForward) {
                  bloc.add(NavigateToPdfPage(
                    pageIndex: state.currentPageIndex + 1,
                  ));
                }
              },
              const SingleActivator(
                LogicalKeyboardKey.keyZ,
                control: true,
              ): () =>
                  bloc.add(const UndoPdfAnnotation()),
              const SingleActivator(
                LogicalKeyboardKey.keyZ,
                control: true,
                shift: true,
              ): () =>
                  bloc.add(const RedoPdfAnnotation()),
              const SingleActivator(
                LogicalKeyboardKey.keyY,
                control: true,
              ): () =>
                  bloc.add(const RedoPdfAnnotation()),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(state.title ?? 'PDF Viewer'),
                  actions: [
                    // Annotation list toggle.
                    IconButton(
                      icon: Icon(
                        state.isAnnotationListOpen
                            ? Icons
                                .format_list_bulleted_rounded
                            : Icons.format_list_bulleted,
                        semanticLabel:
                            state.isAnnotationListOpen
                                ? 'Close annotation list'
                                : 'Open annotation list',
                      ),
                      tooltip: 'Annotations',
                      onPressed: () => bloc.add(
                        const ToggleAnnotationListPanel(),
                      ),
                    ),
                    // Bookmark toggle.
                    IconButton(
                      icon: Icon(
                        state.isBookmarkPanelOpen
                            ? Icons.bookmarks_rounded
                            : Icons.bookmarks_outlined,
                        semanticLabel:
                            state.isBookmarkPanelOpen
                                ? 'Close bookmarks'
                                : 'Open bookmarks',
                      ),
                      tooltip: 'Bookmarks',
                      onPressed: () => bloc.add(
                        const TogglePdfBookmarkPanel(),
                      ),
                    ),
                    // Quick bookmark current page.
                    IconButton(
                      icon: Icon(
                        state.isCurrentPageBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        semanticLabel:
                            state.isCurrentPageBookmarked
                                ? 'Page bookmarked'
                                : 'Bookmark page',
                      ),
                      tooltip: state.isCurrentPageBookmarked
                          ? 'Page bookmarked'
                          : 'Bookmark this page',
                      onPressed: () {
                        if (state.isCurrentPageBookmarked) {
                          final bm =
                              state.bookmarks.firstWhere(
                            (b) =>
                                b.pageIndex ==
                                state.currentPageIndex,
                          );
                          bloc.add(RemovePdfBookmark(
                            bookmarkId: bm.id,
                          ));
                        } else {
                          bloc.add(AddPdfBookmark(
                            bookmark: PdfBookmark(
                              pageIndex:
                                  state.currentPageIndex,
                            ),
                          ));
                        }
                      },
                    ),
                    // Annotation count badge.
                    if (state
                        .currentPageAnnotations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 12,
                        ),
                        child: Center(
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme
                                  .primaryContainer,
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${state.currentPageAnnotations.length}',
                              style: theme
                                  .textTheme.labelSmall
                                  ?.copyWith(
                                color: theme.colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                body: Row(
                  children: [
                    // Annotation list side-panel (left).
                    const PdfAnnotationListPanel(),
                    // Main content area.
                    Expanded(
                      child: Column(
                        children: [
                          // Annotation toolbar.
                          const PdfAnnotationToolbar(),
                          // PDF page view.
                          Expanded(
                            child: _PdfPageView(
                              state: state,
                            ),
                          ),
                          // Page navigation bar.
                          _PageNavigationBar(state: state),
                        ],
                      ),
                    ),
                    // Bookmark side-panel (right).
                    const PdfBookmarkPanel(),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

/// Renders the current PDF page with annotation and selection
/// overlays.
class _PdfPageView extends StatelessWidget {
  const _PdfPageView({required this.state});

  final PdfAnnotationState state;

  @override
  Widget build(BuildContext context) {
    // Use a fixed A4-like page size for placeholder rendering.
    // In production this would come from the PDF renderer.
    const pageSize = Size(595, 842);

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: SizedBox(
          width: pageSize.width,
          height: pageSize.height,
          child: Stack(
            children: [
              // Rasterised PDF page (placeholder).
              Container(
                width: pageSize.width,
                height: pageSize.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                        semanticLabel: 'PDF page',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Page '
                        '${state.currentPageIndex + 1}'
                        ' of ${state.pageCount}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.filePath ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: Colors.grey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Annotations layer.
              const PdfAnnotationRenderer(
                pageSize: pageSize,
              ),
              // Text selection overlay.
              PdfTextSelectionOverlay(
                pageSize: pageSize,
              ),
              // Sticky note tap target (when tool active).
              if (state.activeTool ==
                  PdfAnnotationTool.stickyNote)
                _StickyNoteTapTarget(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

/// Invisible full-page tap target used when the sticky-note tool
/// is active — tapping places a new sticky note at the tap
/// position.
class _StickyNoteTapTarget extends StatelessWidget {
  const _StickyNoteTapTarget({required this.state});
  final PdfAnnotationState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PdfAnnotationBloc>();
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          final pos = details.localPosition;
          bloc.add(AddPdfAnnotation(
            annotation: PdfAnnotation(
              pageIndex: state.currentPageIndex,
              type: PdfAnnotationType.stickyNote,
              rect: Rect.fromLTWH(
                pos.dx,
                pos.dy,
                28,
                28,
              ),
              color: state.activeColor,
            ),
          ));
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Bottom navigation bar with prev / next page buttons, a tappable
/// page indicator (opens jump-to-page dialog), and keyboard hints.
class _PageNavigationBar extends StatelessWidget {
  const _PageNavigationBar({required this.state});
  final PdfAnnotationState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PdfAnnotationBloc>();
    final theme = Theme.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous page (←)',
            onPressed: state.canGoBack
                ? () => bloc.add(NavigateToPdfPage(
                      pageIndex:
                          state.currentPageIndex - 1,
                    ))
                : null,
          ),
          const SizedBox(width: 8),
          // Tappable page indicator — opens jump dialog.
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                _showPageJumpDialog(context, state),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Text(
                'Page ${state.currentPageIndex + 1}'
                ' of ${state.pageCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.underline,
                  decorationStyle:
                      TextDecorationStyle.dotted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
            tooltip: 'Next page (→)',
            onPressed: state.canGoForward
                ? () => bloc.add(NavigateToPdfPage(
                      pageIndex:
                          state.currentPageIndex + 1,
                    ))
                : null,
          ),
        ],
      ),
    );
  }

  void _showPageJumpDialog(
    BuildContext context,
    PdfAnnotationState state,
  ) {
    final bloc = context.read<PdfAnnotationBloc>();
    final controller = TextEditingController(
      text: '${state.currentPageIndex + 1}',
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: 'Page number',
            hintText: '1–${state.pageCount}',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null) {
              bloc.add(JumpToPdfPage(pageNumber: page));
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final page =
                  int.tryParse(controller.text);
              if (page != null) {
                bloc.add(
                  JumpToPdfPage(pageNumber: page),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
