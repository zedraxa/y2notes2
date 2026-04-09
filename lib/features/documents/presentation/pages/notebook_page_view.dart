import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_bloc.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_event.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_state.dart';
import 'package:biscuits/features/documents/presentation/widgets/export_dialog.dart';
import 'package:biscuits/features/documents/presentation/widgets/import_button.dart';
import 'package:biscuits/features/documents/presentation/widgets/outline_panel.dart';
import 'package:biscuits/features/documents/presentation/widgets/page_gesture_handler.dart';
import 'package:biscuits/features/documents/presentation/widgets/page_navigator.dart';

/// Full notebook view: the canvas (passed as [child]) surrounded by the
/// page navigator strip, outline panel, and export/import affordances.
///
/// Also provides bidirectional synchronisation between [DocumentBloc] and
/// [CanvasBloc]:
/// - **Document → Canvas**: when the open notebook or current page changes,
///   the page's persisted strokes, shapes, and config are loaded into
///   [CanvasBloc] so the user sees their saved content immediately.
/// - **Canvas → Document**: after every stroke is committed (or when the page
///   changes), the current strokes and shapes are written back to
///   [DocumentBloc] so they are persisted to storage.
class NotebookPageView extends StatefulWidget {
  const NotebookPageView({
    super.key,
    required this.child,
  });

  /// The canvas widget to render inside this view.
  final Widget child;

  @override
  State<NotebookPageView> createState() => _NotebookPageViewState();
}

class _NotebookPageViewState extends State<NotebookPageView> {
  /// The notebook ID we last loaded into the canvas.
  String? _loadedNotebookId;

  /// The page index we last loaded into the canvas.
  int? _loadedPageIndex;

  // ── Document → Canvas sync ─────────────────────────────────────────────────

  /// Loads the current page's data from [docState] into [CanvasBloc].
  ///
  /// Only fires when the notebook ID or page index changes to avoid loops
  /// caused by the DocumentBloc state update that happens when we write
  /// strokes back.
  void _syncDocumentToCanvas(
    BuildContext context,
    DocumentState docState,
  ) {
    if (!docState.hasNotebook) return;
    final nb = docState.notebook!;
    final pageIndex = docState.currentPageIndex;

    // Avoid reloading the same page we already loaded.
    if (_loadedNotebookId == nb.id && _loadedPageIndex == pageIndex) return;

    _loadedNotebookId = nb.id;
    _loadedPageIndex = pageIndex;

    if (pageIndex >= nb.pages.length) return;
    final page = nb.pages[pageIndex];
    context.read<CanvasBloc>().add(CanvasPageLoaded(
          strokes: page.strokes,
          shapes: page.shapes,
          config: page.config,
        ));
  }

  // ── Canvas → Document sync ─────────────────────────────────────────────────

  /// Persists the current [CanvasBloc] strokes, shapes and config to [DocumentBloc].
  ///
  /// Called after a stroke is committed ([StrokeEnded] fires), when the page
  /// template changes, and before switching pages so nothing is lost.
  void _saveCanvasToDocument(BuildContext context, CanvasState canvasState) {
    final docBloc = context.read<DocumentBloc>();
    final docState = docBloc.state;
    if (!docState.hasNotebook) return;

    final pageIndex = docState.currentPageIndex;
    docBloc.add(UpdatePageStrokes(
      pageIndex: pageIndex,
      strokes: canvasState.strokes,
    ));
    docBloc.add(UpdatePageShapes(
      pageIndex: pageIndex,
      shapes: canvasState.shapes,
    ));
    docBloc.add(UpdatePageConfig(
      pageIndex: pageIndex,
      config: canvasState.config,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ── Document → Canvas: load page when notebook/page changes ─────────
        BlocListener<DocumentBloc, DocumentState>(
          listenWhen: (prev, curr) =>
              prev.notebook?.id != curr.notebook?.id ||
              prev.currentPageIndex != curr.currentPageIndex ||
              (prev.notebook == null && curr.notebook != null),
          listener: (context, state) {
            // Before loading the new page, save whatever was on the canvas
            // for the page we're navigating away from.  Skip on first load
            // since there's nothing to save yet.
            if (_loadedPageIndex != null) {
              _saveCanvasToDocument(context, context.read<CanvasBloc>().state);
            }
            _syncDocumentToCanvas(context, state);
          },
        ),
        // ── Canvas → Document: auto-save after each committed stroke ────────
        BlocListener<CanvasBloc, CanvasState>(
          listenWhen: (prev, curr) =>
              prev.strokes.length != curr.strokes.length ||
              prev.shapes.length != curr.shapes.length ||
              prev.config != curr.config,
          listener: _saveCanvasToDocument,
        ),
        // ── Error toast ─────────────────────────────────────────────────────
        BlocListener<DocumentBloc, DocumentState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status &&
              curr.status == DocumentOperationStatus.error,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              context.read<DocumentBloc>().add(const ClearDocumentStatus());
            }
          },
        ),
      ],
      child: Stack(
        children: [
          // Main content: outline panel + canvas + page navigator.
          Row(
            children: [
              const OutlinePanel(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: PageGestureHandler(child: widget.child),
                    ),
                    const PageNavigator(),
                  ],
                ),
              ),
            ],
          ),
          // Progress overlay (shown during export/import).
          const ExportProgressOverlay(),
        ],
      ),
    );
  }
}

/// Toolbar buttons for export, import, and outline toggle.
class DocumentToolbarActions extends StatelessWidget {
  const DocumentToolbarActions({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Outline toggle button.
          BlocBuilder<DocumentBloc, DocumentState>(
            buildWhen: (prev, curr) =>
                prev.isOutlineOpen != curr.isOutlineOpen,
            builder: (context, state) => IconButton(
              icon: Icon(
                state.isOutlineOpen
                    ? Icons.menu_book_rounded
                    : Icons.menu_book_outlined,
              ),
              tooltip: state.isOutlineOpen ? 'Close outline' : 'Outline',
              iconSize: 20,
              onPressed: () => context
                  .read<DocumentBloc>()
                  .add(const ToggleOutlinePanel()),
            ),
          ),
          // Export button.
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export',
            iconSize: 20,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<DocumentBloc>(),
                child: const ExportDialog(),
              ),
            ),
          ),
          // Import button.
          BlocProvider.value(
            value: context.read<DocumentBloc>(),
            child: const ImportButton(),
          ),
        ],
      );
}
