import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/scanner/domain/entities/scanned_document.dart';
import 'package:y2notes2/features/scanner/engine/document_scanner_engine.dart';
import 'package:y2notes2/features/scanner/presentation/bloc/scanner_event.dart';
import 'package:y2notes2/features/scanner/presentation/bloc/scanner_state.dart';

/// BLoC that manages the document scanning workflow.
class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  ScannerBloc({
    DocumentScannerEngine? engine,
  })  : _engine =
            engine ?? const DocumentScannerEngine(),
        super(const ScannerState()) {
    on<ScannerSessionStarted>(_onSessionStarted);
    on<ImageCaptured>(_onImageCaptured);
    on<CornersAdjusted>(_onCornersAdjusted);
    on<FilterChanged>(_onFilterChanged);
    on<ReprocessCurrentPage>(_onReprocess);
    on<OcrRequested>(_onOcrRequested);
    on<PageConfirmed>(_onPageConfirmed);
    on<PageRemoved>(_onPageRemoved);
    on<ScannerSessionCompleted>(_onSessionCompleted);
    on<ScannerSessionCancelled>(_onSessionCancelled);
  }

  final DocumentScannerEngine _engine;

  void _onSessionStarted(
    ScannerSessionStarted event,
    Emitter<ScannerState> emit,
  ) {
    emit(ScannerState(
      phase: ScannerPhase.capturing,
      options: event.options,
    ));
  }

  Future<void> _onImageCaptured(
    ImageCaptured event,
    Emitter<ScannerState> emit,
  ) async {
    emit(state.copyWith(
      phase: ScannerPhase.processing,
      processingProgress: 0.0,
    ));

    try {
      final page = await _engine.processImage(
        event.imageBytes,
        options: state.options,
        onProgress: (p) => emit(
          state.copyWith(processingProgress: p),
        ),
      );

      emit(state.copyWith(
        phase: ScannerPhase.adjusting,
        currentPage: page,
        processingProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: ScannerPhase.error,
        errorMessage:
            'Failed to process image: $e',
      ));
    }
  }

  void _onCornersAdjusted(
    CornersAdjusted event,
    Emitter<ScannerState> emit,
  ) {
    final page = state.currentPage;
    if (page == null) return;

    emit(state.copyWith(
      currentPage: page.copyWith(corners: event.corners),
    ));
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<ScannerState> emit,
  ) async {
    final page = state.currentPage;
    if (page == null) return;

    emit(state.copyWith(
      phase: ScannerPhase.processing,
      processingProgress: 0.0,
    ));

    try {
      final updatedPage = await _engine.processImage(
        page.originalImage,
        options: state.options.copyWith(
          defaultFilter: event.filter,
        ),
        manualCorners: page.corners,
        onProgress: (p) => emit(
          state.copyWith(processingProgress: p),
        ),
      );

      emit(state.copyWith(
        phase: ScannerPhase.reviewing,
        currentPage: updatedPage,
        processingProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: ScannerPhase.error,
        errorMessage: 'Filter application failed: $e',
      ));
    }
  }

  Future<void> _onReprocess(
    ReprocessCurrentPage event,
    Emitter<ScannerState> emit,
  ) async {
    final page = state.currentPage;
    if (page == null) return;

    emit(state.copyWith(
      phase: ScannerPhase.processing,
      processingProgress: 0.0,
    ));

    try {
      final reprocessed = await _engine.processImage(
        page.originalImage,
        options: state.options,
        manualCorners: page.corners,
        onProgress: (p) => emit(
          state.copyWith(processingProgress: p),
        ),
      );

      emit(state.copyWith(
        phase: ScannerPhase.reviewing,
        currentPage: reprocessed,
        processingProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: ScannerPhase.error,
        errorMessage: 'Reprocessing failed: $e',
      ));
    }
  }

  Future<void> _onOcrRequested(
    OcrRequested event,
    Emitter<ScannerState> emit,
  ) async {
    final page = state.currentPage;
    if (page == null) return;

    emit(state.copyWith(
      phase: ScannerPhase.ocrInProgress,
    ));

    try {
      final ocrText =
          await _engine.performOcr(page.originalImage);

      emit(state.copyWith(
        phase: ScannerPhase.reviewing,
        currentPage: page.copyWith(ocrText: ocrText),
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: ScannerPhase.error,
        errorMessage: 'OCR failed: $e',
      ));
    }
  }

  void _onPageConfirmed(
    PageConfirmed event,
    Emitter<ScannerState> emit,
  ) {
    final page = state.currentPage;
    if (page == null) return;

    emit(state.copyWith(
      phase: ScannerPhase.capturing,
      confirmedPages: [...state.confirmedPages, page],
      clearCurrentPage: true,
    ));
  }

  void _onPageRemoved(
    PageRemoved event,
    Emitter<ScannerState> emit,
  ) {
    if (event.pageIndex < 0 ||
        event.pageIndex >= state.confirmedPages.length) {
      return;
    }
    final pages =
        List<ScannedPage>.of(state.confirmedPages)
          ..removeAt(event.pageIndex);
    emit(state.copyWith(confirmedPages: pages));
  }

  void _onSessionCompleted(
    ScannerSessionCompleted event,
    Emitter<ScannerState> emit,
  ) {
    // Include current page if it hasn't been confirmed yet.
    final allPages = [
      ...state.confirmedPages,
      if (state.currentPage != null) state.currentPage!,
    ];

    if (allPages.isEmpty) {
      emit(state.copyWith(
        phase: ScannerPhase.error,
        errorMessage: 'No pages scanned.',
      ));
      return;
    }

    final result = ScanResult(
      pages: allPages,
      scannedAt: DateTime.now(),
      title: event.title ?? 'Scanned Document',
    );

    emit(state.copyWith(
      phase: ScannerPhase.completed,
      scanResult: result,
      clearCurrentPage: true,
    ));
  }

  void _onSessionCancelled(
    ScannerSessionCancelled event,
    Emitter<ScannerState> emit,
  ) {
    emit(const ScannerState());
  }
}
