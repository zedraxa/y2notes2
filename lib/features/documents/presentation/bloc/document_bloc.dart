import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/documents/data/document_repository.dart';
import 'package:y2notes2/features/documents/domain/entities/notebook.dart';
import 'package:y2notes2/features/documents/domain/entities/notebook_page.dart';
import 'package:y2notes2/features/documents/domain/models/export_options.dart';
import 'package:y2notes2/features/documents/engine/image_export_engine.dart';
import 'package:y2notes2/features/documents/engine/image_import_engine.dart';
import 'package:y2notes2/features/documents/engine/pdf_export_engine.dart';
import 'package:y2notes2/features/documents/engine/pdf_import_engine.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_event.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_state.dart';

/// BLoC that manages notebook lifecycle, page navigation, and
/// export/import operations.
class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  DocumentBloc({
    DocumentRepository? repository,
    PdfExportEngine? pdfExportEngine,
    PdfImportEngine? pdfImportEngine,
    ImageExportEngine? imageExportEngine,
    ImageImportEngine? imageImportEngine,
  })  : _repository = repository,
        _pdfExport = pdfExportEngine ?? const PdfExportEngine(),
        _pdfImport = pdfImportEngine ?? const PdfImportEngine(),
        _imageExport = imageExportEngine ?? const ImageExportEngine(),
        _imageImport = imageImportEngine ?? const ImageImportEngine(),
        super(const DocumentState()) {
    on<CreateNotebook>(_onCreateNotebook);
    on<OpenNotebook>(_onOpenNotebook);
    on<CloseNotebook>(_onCloseNotebook);
    on<NavigateToPage>(_onNavigateToPage);
    on<AddPage>(_onAddPage);
    on<DeletePage>(_onDeletePage);
    on<DuplicatePage>(_onDuplicatePage);
    on<MovePage>(_onMovePage);
    on<UpdatePageStrokes>(_onUpdatePageStrokes);
    on<UpdatePageConfig>(_onUpdatePageConfig);
    on<ExportCurrentPageAsPdf>(_onExportCurrentPageAsPdf);
    on<ExportNotebookAsPdf>(_onExportNotebookAsPdf);
    on<ShareCurrentPageAsPdf>(_onShareCurrentPageAsPdf);
    on<ExportCurrentPageAsImage>(_onExportCurrentPageAsImage);
    on<ImportPdf>(_onImportPdf);
    on<ImportImage>(_onImportImage);
    on<ClearDocumentStatus>(_onClearStatus);
  }

  /// Optional repository for persisting/loading notebooks.
  final DocumentRepository? _repository;
  final PdfExportEngine _pdfExport;
  final PdfImportEngine _pdfImport;
  final ImageExportEngine _imageExport;
  final ImageImportEngine _imageImport;
  final _uuid = const Uuid();

  // ── Notebook lifecycle ─────────────────────────────────────────────────────

  void _onCreateNotebook(
    CreateNotebook event,
    Emitter<DocumentState> emit,
  ) {
    final firstPage = NotebookPage(
      pageNumber: 1,
      config: const CanvasConfig(),
    );
    final notebook = Notebook(
      title: event.title,
      pages: [firstPage],
    );
    emit(state.copyWith(notebook: notebook, currentPageIndex: 0));
  }

  Future<void> _onOpenNotebook(
    OpenNotebook event,
    Emitter<DocumentState> emit,
  ) async {
    // If the requested notebook is already loaded, no-op.
    if (state.notebook?.id == event.notebookId) return;

    emit(state.copyWith(
      status: DocumentOperationStatus.inProgress,
    ));

    try {
      Notebook? loaded;
      final repo = _repository;
      if (repo != null) {
        loaded = await repo.loadNotebook();
        // Verify the loaded notebook matches the requested ID.
        if (loaded?.id != event.notebookId) {
          loaded = null;
        }
      }

      if (loaded != null) {
        emit(state.copyWith(
          notebook: loaded,
          currentPageIndex: 0,
          status: DocumentOperationStatus.idle,
        ));
      } else {
        // Notebook not found in storage — emit an error state.
        emit(state.copyWith(
          status: DocumentOperationStatus.error,
          errorMessage: 'Notebook "${event.notebookId}" not found.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DocumentOperationStatus.error,
        errorMessage: 'Failed to open notebook: $e',
      ));
    }
  }

  void _onCloseNotebook(
    CloseNotebook event,
    Emitter<DocumentState> emit,
  ) =>
      emit(state.copyWith(clearNotebook: true, currentPageIndex: 0));

  // ── Page management ────────────────────────────────────────────────────────

  void _onNavigateToPage(
    NavigateToPage event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final clamped = event.pageIndex.clamp(0, nb.pageCount - 1);
    emit(state.copyWith(currentPageIndex: clamped));
  }

  void _onAddPage(
    AddPage event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;

    final insertAt = (event.insertAfterIndex ?? nb.pageCount - 1) + 1;
    final newPage = NotebookPage(
      id: _uuid.v4(),
      pageNumber: insertAt + 1,
      config: const CanvasConfig(),
    );

    final pages = List<NotebookPage>.of(nb.pages)
      ..insert(insertAt, newPage);
    final renumbered = _renumber(pages);
    final updated = nb.copyWith(pages: renumbered);
    emit(state.copyWith(
      notebook: updated,
      currentPageIndex: insertAt,
    ));
  }

  void _onDeletePage(
    DeletePage event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null || nb.pageCount <= 1) return;

    final updated = nb.removePage(event.pageIndex);
    final newIndex =
        event.pageIndex >= updated.pageCount ? updated.pageCount - 1 : event.pageIndex;
    emit(state.copyWith(notebook: updated, currentPageIndex: newIndex));
  }

  void _onDuplicatePage(
    DuplicatePage event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;

    final source = nb.pages[event.pageIndex];
    final duplicate = NotebookPage(
      id: _uuid.v4(),
      pageNumber: source.pageNumber + 1,
      strokes: List.of(source.strokes),
      shapes: List.of(source.shapes),
      stickers: List.of(source.stickers),
      config: source.config,
    );

    final pages = List<NotebookPage>.of(nb.pages)
      ..insert(event.pageIndex + 1, duplicate);
    final renumbered = _renumber(pages);
    emit(state.copyWith(
      notebook: nb.copyWith(pages: renumbered),
      currentPageIndex: event.pageIndex + 1,
    ));
  }

  void _onMovePage(
    MovePage event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;

    final pages = List<NotebookPage>.of(nb.pages);
    final page = pages.removeAt(event.fromIndex);
    pages.insert(event.toIndex, page);
    final renumbered = _renumber(pages);
    emit(state.copyWith(
      notebook: nb.copyWith(pages: renumbered),
      currentPageIndex: event.toIndex,
    ));
  }

  void _onUpdatePageStrokes(
    UpdatePageStrokes event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final page = nb.pages[event.pageIndex].copyWith(strokes: event.strokes);
    emit(state.copyWith(notebook: nb.updatePage(event.pageIndex, page)));
  }

  void _onUpdatePageConfig(
    UpdatePageConfig event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final page = nb.pages[event.pageIndex].copyWith(config: event.config);
    emit(state.copyWith(notebook: nb.updatePage(event.pageIndex, page)));
  }

  // ── PDF export ─────────────────────────────────────────────────────────────

  Future<void> _onExportCurrentPageAsPdf(
    ExportCurrentPageAsPdf event,
    Emitter<DocumentState> emit,
  ) async {
    final nb = state.notebook;
    if (nb == null || nb.pages.isEmpty) return;

    emit(state.copyWith(
      isExporting: true,
      status: DocumentOperationStatus.inProgress,
      exportProgress: 0.0,
    ));

    try {
      final page = nb.pages[state.currentPageIndex];
      final bytes = await _pdfExport.exportToPdf(
        strokes: page.strokes,
        shapes: page.shapes,
        stickers: page.stickers,
        config: page.config,
        options: event.options,
        onProgress: (p) =>
            emit(state.copyWith(exportProgress: p)),
      );

      final path = await _pdfExport.saveToFile(
        pdfBytes: bytes,
        fileName: '${nb.title}_page_${state.currentPageIndex + 1}.pdf',
      );

      emit(state.copyWith(
        isExporting: false,
        status: DocumentOperationStatus.success,
        lastExportPath: path,
        exportProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isExporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'PDF export failed: $e',
      ));
    }
  }

  Future<void> _onExportNotebookAsPdf(
    ExportNotebookAsPdf event,
    Emitter<DocumentState> emit,
  ) async {
    final nb = state.notebook;
    if (nb == null || nb.pages.isEmpty) return;

    emit(state.copyWith(
      isExporting: true,
      status: DocumentOperationStatus.inProgress,
      exportProgress: 0.0,
    ));

    try {
      final pageData = nb.pages
          .map((p) => (
                strokes: p.strokes,
                shapes: p.shapes,
                stickers: p.stickers,
                config: p.config,
              ))
          .toList();

      final bytes = await _pdfExport.exportMultiPageToPdf(
        pages: pageData,
        options: event.options,
        onProgress: (p) =>
            emit(state.copyWith(exportProgress: p)),
      );

      final path = await _pdfExport.saveToFile(
        pdfBytes: bytes,
        fileName: '${nb.title}.pdf',
      );

      emit(state.copyWith(
        isExporting: false,
        status: DocumentOperationStatus.success,
        lastExportPath: path,
        exportProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isExporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'Notebook PDF export failed: $e',
      ));
    }
  }

  Future<void> _onShareCurrentPageAsPdf(
    ShareCurrentPageAsPdf event,
    Emitter<DocumentState> emit,
  ) async {
    final nb = state.notebook;
    if (nb == null || nb.pages.isEmpty) return;

    emit(state.copyWith(
      isExporting: true,
      status: DocumentOperationStatus.inProgress,
    ));

    try {
      final page = nb.pages[state.currentPageIndex];
      final bytes = await _pdfExport.exportToPdf(
        strokes: page.strokes,
        shapes: page.shapes,
        stickers: page.stickers,
        config: page.config,
        options: event.options,
      );

      await _pdfExport.shareAsPdf(pdfBytes: bytes, name: nb.title);

      emit(state.copyWith(
        isExporting: false,
        status: DocumentOperationStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        isExporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'Share failed: $e',
      ));
    }
  }

  // ── Image export ───────────────────────────────────────────────────────────

  Future<void> _onExportCurrentPageAsImage(
    ExportCurrentPageAsImage event,
    Emitter<DocumentState> emit,
  ) async {
    final nb = state.notebook;
    if (nb == null || nb.pages.isEmpty) return;

    emit(state.copyWith(
      isExporting: true,
      status: DocumentOperationStatus.inProgress,
      exportProgress: 0.0,
    ));

    try {
      final page = nb.pages[state.currentPageIndex];
      final bytes = await _imageExport.exportToImage(
        strokes: page.strokes,
        shapes: page.shapes,
        stickers: page.stickers,
        config: page.config,
        options: event.options,
        onProgress: (p) => emit(state.copyWith(exportProgress: p)),
      );

      final path = await _imageExport.saveToFile(
        bytes: bytes,
        fileName: '${nb.title}_page_${state.currentPageIndex + 1}',
        format: event.options.format,
      );

      emit(state.copyWith(
        isExporting: false,
        status: DocumentOperationStatus.success,
        lastExportPath: path,
        exportProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isExporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'Image export failed: $e',
      ));
    }
  }

  // ── PDF import ─────────────────────────────────────────────────────────────

  Future<void> _onImportPdf(
    ImportPdf event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(
      isImporting: true,
      status: DocumentOperationStatus.inProgress,
      importProgress: 0.0,
    ));

    try {
      final result = await _pdfImport.pickAndImport(
        scale: event.scale,
        onProgress: (p) => emit(state.copyWith(importProgress: p)),
      );

      if (result == null) {
        // User cancelled — no-op.
        emit(state.copyWith(
          isImporting: false,
          status: DocumentOperationStatus.idle,
        ));
        return;
      }

      // Build notebook pages from imported PDF pages.
      final pages = result.pages
          .map(
            (imported) => NotebookPage(
              pageNumber: imported.pageNumber,
              backgroundImage: imported.renderedImage,
              backgroundPdfPath: imported.sourcePath,
              config: CanvasConfig(
                width: imported.width,
                height: imported.height,
                template: PageTemplate.blank,
              ),
            ),
          )
          .toList();

      final notebook = Notebook(
        title: result.title ?? 'Imported PDF',
        pages: pages,
      );

      emit(state.copyWith(
        notebook: notebook,
        currentPageIndex: 0,
        isImporting: false,
        status: DocumentOperationStatus.success,
        importProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isImporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'PDF import failed: $e',
      ));
    }
  }

  Future<void> _onImportImage(
    ImportImage event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(
      isImporting: true,
      status: DocumentOperationStatus.inProgress,
      importProgress: 0.0,
    ));

    try {
      final result = await _imageImport.pickAndImport(
        maxWidth: event.maxWidth,
        maxHeight: event.maxHeight,
      );

      if (result == null) {
        emit(state.copyWith(
          isImporting: false,
          status: DocumentOperationStatus.idle,
        ));
        return;
      }

      if (result.pages.isEmpty) {
        emit(state.copyWith(
          isImporting: false,
          status: DocumentOperationStatus.error,
          errorMessage: 'No pages found in the imported image.',
        ));
        return;
      }

      final imported = result.pages.first;
      final newPage = NotebookPage(
        pageNumber: (state.notebook?.pageCount ?? 0) + 1,
        backgroundImage: imported.renderedImage,
        config: CanvasConfig(
          width: imported.width,
          height: imported.height,
          template: PageTemplate.blank,
        ),
      );

      final nb = state.notebook;
      final updated = nb != null
          ? nb.addPage(newPage)
          : Notebook(title: result.title ?? 'Imported Image', pages: [newPage]);

      emit(state.copyWith(
        notebook: updated,
        currentPageIndex: updated.pageCount - 1,
        isImporting: false,
        status: DocumentOperationStatus.success,
        importProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isImporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'Image import failed: $e',
      ));
    }
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  void _onClearStatus(
    ClearDocumentStatus event,
    Emitter<DocumentState> emit,
  ) =>
      emit(state.copyWith(
        status: DocumentOperationStatus.idle,
        clearError: true,
        exportProgress: 0.0,
        importProgress: 0.0,
      ));

  List<NotebookPage> _renumber(List<NotebookPage> pages) => pages
      .asMap()
      .map((i, p) => MapEntry(i, p.copyWith(pageNumber: i + 1)))
      .values
      .toList();
}
