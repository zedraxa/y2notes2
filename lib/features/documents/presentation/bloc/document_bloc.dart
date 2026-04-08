import 'dart:io' if (dart.library.html) 'package:biscuits/core/io/io_stub.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:biscuits/features/audio_sync/domain/entities/audio_recording.dart';
import 'package:biscuits/features/canvas/domain/models/canvas_config.dart';
import 'package:biscuits/features/documents/data/document_repository.dart';
import 'package:biscuits/features/documents/domain/entities/import_history_entry.dart';
import 'package:biscuits/features/documents/domain/entities/import_result.dart';
import 'package:biscuits/features/documents/domain/entities/notebook.dart';
import 'package:biscuits/features/documents/domain/entities/notebook_page.dart';
import 'package:biscuits/features/documents/domain/models/export_options.dart';
import 'package:biscuits/features/documents/domain/models/import_options.dart';
import 'package:biscuits/features/documents/engine/image_export_engine.dart';
import 'package:biscuits/features/documents/engine/image_import_engine.dart';
import 'package:biscuits/features/documents/engine/pdf_export_engine.dart';
import 'package:biscuits/features/documents/engine/pdf_import_engine.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_event.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_state.dart';

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
    on<ImportPdfFromPath>(_onImportPdfFromPath);
    on<ImportImage>(_onImportImage);
    on<ImportMultipleImages>(_onImportMultipleImages);
    on<ImportImageFromPath>(_onImportImageFromPath);
    on<ClearImportHistory>(_onClearImportHistory);
    on<ImportScannedDocument>(_onImportScannedDocument);
    on<ClearDocumentStatus>(_onClearStatus);
    on<RenameNotebook>(_onRenameNotebook);
    on<UpdateNotebookDescription>(_onUpdateNotebookDescription);
    on<ChangeNotebookCover>(_onChangeNotebookCover);
    on<UpdatePageTitle>(_onUpdatePageTitle);
    on<TogglePageBookmark>(_onTogglePageBookmark);
    on<ToggleOutlinePanel>(_onToggleOutlinePanel);
    on<UpdatePagePdfAnnotations>(_onUpdatePagePdfAnnotations);
    on<GoToNextPage>(_onGoToNextPage);
    on<GoToPreviousPage>(_onGoToPreviousPage);
    on<UpdatePageMedia>(_onUpdatePageMedia);
    on<UpdatePageAudioRecordings>(
      _onUpdatePageAudioRecordings,
    );
    on<UpdatePageShapes>(_onUpdatePageShapes);
    on<UpdatePageStickers>(_onUpdatePageStickers);
    on<UpdatePageGraphs>(_onUpdatePageGraphs);
    on<UpdatePageRichTexts>(_onUpdatePageRichTexts);
  }

  /// Optional repository for persisting/loading notebooks.
  final DocumentRepository? _repository;
  final PdfExportEngine _pdfExport;
  final PdfImportEngine _pdfImport;
  final ImageExportEngine _imageExport;
  final ImageImportEngine _imageImport;
  final _uuid = const Uuid();

  /// Persists the current notebook (if any) to the repository.
  /// This is fire-and-forget — errors are silently ignored to avoid
  /// blocking the UI for non-critical persistence failures.
  void _persistNotebook() {
    final nb = state.notebook;
    if (nb == null || _repository == null) return;
    _repository!.saveNotebook(nb);
  }

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
      id: event.id,
      title: event.title,
      pages: [firstPage],
    );
    emit(state.copyWith(notebook: notebook, currentPageIndex: 0));
    _persistNotebook();
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
        loaded = await repo.loadNotebook(event.notebookId);
      }

      if (loaded != null) {
        emit(state.copyWith(
          notebook: loaded,
          currentPageIndex: 0,
          status: DocumentOperationStatus.idle,
        ));
      } else {
        // Notebook not found in storage — create a new blank notebook so the
        // user lands on an empty page rather than an error screen.
        final firstPage = NotebookPage(
          pageNumber: 1,
          config: const CanvasConfig(),
        );
        final notebook = Notebook(
          id: event.notebookId,
          title: 'Untitled',
          pages: [firstPage],
        );
        emit(state.copyWith(
          notebook: notebook,
          currentPageIndex: 0,
          status: DocumentOperationStatus.idle,
        ));
        _persistNotebook();
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
  ) {
    // Persist before clearing in-memory state.
    _persistNotebook();
    emit(state.copyWith(clearNotebook: true, currentPageIndex: 0));
  }

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
    _persistNotebook();
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
    _persistNotebook();
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
      title: source.title,
      strokes: List.of(source.strokes),
      shapes: List.of(source.shapes),
      stickers: List.of(source.stickers),
      mediaElements: List.of(source.mediaElements),
      graphs: List.of(source.graphs),
      pdfAnnotations: List.of(source.pdfAnnotations),
      richTexts: List.of(source.richTexts),
      config: source.config,
      audioRecordings: List.of(source.audioRecordings),
    );

    final pages = List<NotebookPage>.of(nb.pages)
      ..insert(event.pageIndex + 1, duplicate);
    final renumbered = _renumber(pages);
    emit(state.copyWith(
      notebook: nb.copyWith(pages: renumbered),
      currentPageIndex: event.pageIndex + 1,
    ));
    _persistNotebook();
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
    _persistNotebook();
  }

  void _onUpdatePageStrokes(
    UpdatePageStrokes event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final page = nb.pages[event.pageIndex].copyWith(strokes: event.strokes);
    emit(state.copyWith(notebook: nb.updatePage(event.pageIndex, page)));
    _persistNotebook();
  }

  void _onUpdatePageConfig(
    UpdatePageConfig event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final page = nb.pages[event.pageIndex].copyWith(config: event.config);
    emit(state.copyWith(notebook: nb.updatePage(event.pageIndex, page)));
    _persistNotebook();
  }

  // ── Export / Import ──────────────────────────────────────────────────────

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
        scale: event.options.scale,
        pageRange: event.options.pageRange,
        maxFileSizeBytes: event.options.maxFileSizeBytes,
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

      _applyImportResult(result, event.options.mode, ImportFileType.pdf, emit);
    } catch (e) {
      emit(state.copyWith(
        isImporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'PDF import failed: $e',
      ));
    }
  }

  Future<void> _onImportPdfFromPath(
    ImportPdfFromPath event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(
      isImporting: true,
      status: DocumentOperationStatus.inProgress,
      importProgress: 0.0,
    ));

    try {
      final result = await _pdfImport.importPdf(
        event.filePath,
        scale: event.options.scale,
        pageRange: event.options.pageRange,
        maxFileSizeBytes: event.options.maxFileSizeBytes,
        onProgress: (p) => emit(state.copyWith(importProgress: p)),
      );

      _applyImportResult(result, event.options.mode, ImportFileType.pdf, emit);
    } catch (e) {
      emit(state.copyWith(
        isImporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'PDF import failed: $e',
      ));
    }
  }

  // ── Image import ──────────────────────────────────────────────────────────

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
        maxWidth: event.options.maxWidth,
        maxHeight: event.options.maxHeight,
        maxFileSizeBytes: event.options.maxFileSizeBytes,
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

      _applyImportResult(result, event.options.mode, ImportFileType.image, emit);
    } catch (e) {
      emit(state.copyWith(
        isImporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'Image import failed: $e',
      ));
    }
  }

  Future<void> _onImportMultipleImages(
    ImportMultipleImages event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(
      isImporting: true,
      status: DocumentOperationStatus.inProgress,
      importProgress: 0.0,
    ));

    try {
      final result = await _imageImport.pickAndImportMultiple(
        maxWidth: event.options.maxWidth,
        maxHeight: event.options.maxHeight,
        maxFileSizeBytes: event.options.maxFileSizeBytes,
        onProgress: (p) => emit(state.copyWith(importProgress: p)),
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
          errorMessage: 'No images were imported.',
        ));
        return;
      }

      _applyImportResult(result, event.options.mode, ImportFileType.image, emit);
    } catch (e) {
      emit(state.copyWith(
        isImporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'Image import failed: $e',
      ));
    }
  }

  Future<void> _onImportImageFromPath(
    ImportImageFromPath event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(
      isImporting: true,
      status: DocumentOperationStatus.inProgress,
      importProgress: 0.0,
    ));

    try {
      final page = await _imageImport.importImage(
        event.filePath,
        maxWidth: event.options.maxWidth,
        maxHeight: event.options.maxHeight,
        maxFileSizeBytes: event.options.maxFileSizeBytes,
      );

      final fileName =
          event.filePath.split(Platform.pathSeparator).last;
      final result = ImportResult(
        pages: [page],
        sourcePath: event.filePath,
        importedAt: DateTime.now(),
        title: fileName,
      );

      _applyImportResult(result, event.options.mode, ImportFileType.image, emit);
    } catch (e) {
      emit(state.copyWith(
        isImporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'Image import failed: $e',
      ));
    }
  }

  // ── Import history ────────────────────────────────────────────────────────

  void _onClearImportHistory(
    ClearImportHistory event,
    Emitter<DocumentState> emit,
  ) =>
      emit(state.copyWith(importHistory: []));

  // ── Scanner import ────────────────────────────────────────────────────────

  Future<void> _onImportScannedDocument(
    ImportScannedDocument event,
    Emitter<DocumentState> emit,
  ) async {
    final scanResult = event.scanResult;
    if (!scanResult.hasPages) {
      emit(state.copyWith(
        status: DocumentOperationStatus.error,
        errorMessage: 'No pages in scanned document.',
      ));
      return;
    }

    emit(state.copyWith(
      isImporting: true,
      status: DocumentOperationStatus.inProgress,
      importProgress: 0.0,
    ));

    try {
      final pages = <NotebookPage>[];
      for (var i = 0; i < scanResult.pages.length; i++) {
        final scanned = scanResult.pages[i];
        pages.add(NotebookPage(
          pageNumber: (state.notebook?.pageCount ?? 0) +
              i +
              1,
          backgroundImage: scanned.processedImage,
          config: CanvasConfig(
            width: scanned.width,
            height: scanned.height,
            template: PageTemplate.blank,
          ),
        ));

        emit(state.copyWith(
          importProgress:
              (i + 1) / scanResult.pages.length,
        ));
      }

      final nb = state.notebook;
      Notebook updated;
      if (nb != null) {
        var result = nb;
        for (final page in pages) {
          result = result.addPage(page);
        }
        updated = result;
      } else {
        updated = Notebook(
          title: scanResult.title ?? 'Scanned Document',
          pages: pages,
        );
      }

      emit(state.copyWith(
        notebook: updated,
        currentPageIndex: updated.pageCount - 1,
        isImporting: false,
        status: DocumentOperationStatus.success,
        importProgress: 1.0,
      ));
      _persistNotebook();
    } catch (e) {
      emit(state.copyWith(
        isImporting: false,
        status: DocumentOperationStatus.error,
        errorMessage: 'Scan import failed: $e',
      ));
    }
  }

  // ── Shared import helper ──────────────────────────────────────────────────

  /// Converts an [ImportResult] into notebook pages and applies them
  /// according to the chosen [ImportMode], then records the import in
  /// the history.
  void _applyImportResult(
    ImportResult result,
    ImportMode mode,
    ImportFileType fileType,
    Emitter<DocumentState> emit,
  ) {
    // Build notebook pages from imported pages.
    final newPages = result.pages
        .map(
          (imported) => NotebookPage(
            pageNumber: imported.pageNumber,
            backgroundImage: imported.renderedImage,
            backgroundPdfPath:
                fileType == ImportFileType.pdf ? imported.sourcePath : null,
            config: CanvasConfig(
              width: imported.width,
              height: imported.height,
              template: PageTemplate.blank,
            ),
          ),
        )
        .toList();

    // Record in import history.
    final fileName = result.sourcePath.split(Platform.pathSeparator).last;
    int? fileSizeBytes;
    try {
      fileSizeBytes = File(result.sourcePath).lengthSync();
    } catch (_) {
      // Ignore — file size is best-effort.
    }
    final historyEntry = ImportHistoryEntry(
      fileName: fileName,
      filePath: result.sourcePath,
      fileType: fileType,
      importedAt: result.importedAt,
      pageCount: newPages.length,
      fileSizeBytes: fileSizeBytes,
    );
    final updatedHistory = [
      historyEntry,
      ...state.importHistory,
    ].take(DocumentState.maxHistoryEntries).toList();

    final nb = state.notebook;
    if (mode == ImportMode.appendToCurrentNotebook && nb != null) {
      // Append pages to current notebook.
      final renumbered = _renumber([...nb.pages, ...newPages]);
      final updated = nb.copyWith(pages: renumbered);
      emit(state.copyWith(
        notebook: updated,
        currentPageIndex: updated.pageCount - newPages.length,
        isImporting: false,
        status: DocumentOperationStatus.success,
        importProgress: 1.0,
        importHistory: updatedHistory,
        lastImportPageCount: newPages.length,
      ));
    } else {
      // Create new notebook.
      final notebook = Notebook(
        title: result.title ?? 'Imported ${fileType.name}',
        pages: newPages,
      );
      emit(state.copyWith(
        notebook: notebook,
        currentPageIndex: 0,
        isImporting: false,
        status: DocumentOperationStatus.success,
        importProgress: 1.0,
        importHistory: updatedHistory,
        lastImportPageCount: newPages.length,
      ));
    }
    _persistNotebook();
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

  // ── Notebook metadata ─────────────────────────────────────────────────────

  void _onRenameNotebook(
    RenameNotebook event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    emit(state.copyWith(notebook: nb.copyWith(title: event.title)));
    _persistNotebook();
  }

  void _onUpdateNotebookDescription(
    UpdateNotebookDescription event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    if (event.description == null) {
      emit(state.copyWith(
        notebook: nb.copyWith(clearDescription: true),
      ));
    } else {
      emit(state.copyWith(
        notebook: nb.copyWith(description: event.description),
      ));
    }
    _persistNotebook();
  }

  void _onChangeNotebookCover(
    ChangeNotebookCover event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    emit(state.copyWith(notebook: nb.copyWith(cover: event.cover)));
    _persistNotebook();
  }

  // ── Page metadata ─────────────────────────────────────────────────────────

  void _onUpdatePageTitle(
    UpdatePageTitle event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;

    final page = nb.pages[event.pageIndex];
    final updated = event.title == null
        ? page.copyWith(clearTitle: true)
        : page.copyWith(title: event.title);
    emit(state.copyWith(notebook: nb.updatePage(event.pageIndex, updated)));
    _persistNotebook();
  }

  void _onTogglePageBookmark(
    TogglePageBookmark event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;

    final page = nb.pages[event.pageIndex];
    final updated = page.copyWith(isBookmarked: !page.isBookmarked);
    emit(state.copyWith(notebook: nb.updatePage(event.pageIndex, updated)));
    _persistNotebook();
  }

  // ── Outline panel ─────────────────────────────────────────────────────────

  void _onToggleOutlinePanel(
    ToggleOutlinePanel event,
    Emitter<DocumentState> emit,
  ) =>
      emit(state.copyWith(isOutlineOpen: !state.isOutlineOpen));

  // ── PDF annotations ──────────────────────────────────────────────────────

  void _onUpdatePagePdfAnnotations(
    UpdatePagePdfAnnotations event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    if (event.pageIndex < 0 || event.pageIndex >= nb.pages.length) return;
    final page = nb.pages[event.pageIndex].copyWith(
      pdfAnnotations: event.annotations,
    );
    emit(state.copyWith(notebook: nb.updatePage(event.pageIndex, page)));
    _persistNotebook();
  }

  // ── Convenience navigation ─────────────────────────────────────────────

  void _onGoToNextPage(
    GoToNextPage event,
    Emitter<DocumentState> emit,
  ) {
    if (!state.canGoForward) return;
    emit(state.copyWith(currentPageIndex: state.currentPageIndex + 1));
  }

  void _onGoToPreviousPage(
    GoToPreviousPage event,
    Emitter<DocumentState> emit,
  ) {
    if (!state.canGoBack) return;
    emit(state.copyWith(currentPageIndex: state.currentPageIndex - 1));
  }

  // ── Media elements ────────────────────────────────────────────────────────

  void _onUpdatePageMedia(
    UpdatePageMedia event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final page = nb.pages[event.pageIndex].copyWith(
      mediaElements: event.mediaElements,
    );
    emit(state.copyWith(
      notebook: nb.updatePage(event.pageIndex, page),
    ));
    _persistNotebook();
  }

  // ── Audio recordings ──────────────────────────────────────────────────────

  void _onUpdatePageAudioRecordings(
    UpdatePageAudioRecordings event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final recordings = event.recordings
        .whereType<AudioRecording>()
        .toList();
    final page = nb.pages[event.pageIndex].copyWith(
      audioRecordings: recordings,
    );
    emit(state.copyWith(
      notebook: nb.updatePage(event.pageIndex, page),
    ));
    _persistNotebook();
  }

  // ── Shape elements ────────────────────────────────────────────────────────

  void _onUpdatePageShapes(
    UpdatePageShapes event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final page = nb.pages[event.pageIndex].copyWith(
      shapes: event.shapes,
    );
    emit(state.copyWith(
      notebook: nb.updatePage(event.pageIndex, page),
    ));
    _persistNotebook();
  }

  // ── Sticker elements ──────────────────────────────────────────────────────

  void _onUpdatePageStickers(
    UpdatePageStickers event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final page = nb.pages[event.pageIndex].copyWith(
      stickers: event.stickers,
    );
    emit(state.copyWith(
      notebook: nb.updatePage(event.pageIndex, page),
    ));
    _persistNotebook();
  }

  // ── Graph elements ────────────────────────────────────────────────────────

  void _onUpdatePageGraphs(
    UpdatePageGraphs event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final page = nb.pages[event.pageIndex].copyWith(
      graphs: event.graphs,
    );
    emit(state.copyWith(
      notebook: nb.updatePage(event.pageIndex, page),
    ));
    _persistNotebook();
  }

  // ── Rich text elements ────────────────────────────────────────────────────

  void _onUpdatePageRichTexts(
    UpdatePageRichTexts event,
    Emitter<DocumentState> emit,
  ) {
    final nb = state.notebook;
    if (nb == null) return;
    final page = nb.pages[event.pageIndex].copyWith(
      richTexts: event.richTexts,
    );
    emit(state.copyWith(
      notebook: nb.updatePage(event.pageIndex, page),
    ));
    _persistNotebook();
  }

  List<NotebookPage> _renumber(List<NotebookPage> pages) => pages
      .asMap()
      .map((i, p) => MapEntry(i, p.copyWith(pageNumber: i + 1)))
      .values
      .toList();
}
