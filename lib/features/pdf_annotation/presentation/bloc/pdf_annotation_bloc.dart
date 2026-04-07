import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_annotation.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_bookmark.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_event.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_state.dart';

/// BLoC that manages PDF annotation state: tool selection, text
/// selection, CRUD operations on annotations and bookmarks.
class PdfAnnotationBloc
    extends Bloc<PdfAnnotationEvent, PdfAnnotationState> {
  PdfAnnotationBloc() : super(const PdfAnnotationState()) {
    on<OpenPdfForAnnotation>(_onOpen);
    on<ClosePdfAnnotation>(_onClose);
    on<NavigateToPdfPage>(_onNavigate);
    on<PdfTextLayerLoaded>(_onTextLayerLoaded);
    on<SelectPdfText>(_onSelectText);
    on<ClearPdfTextSelection>(_onClearSelection);
    on<SetAnnotationTool>(_onSetTool);
    on<SetAnnotationColor>(_onSetColor);
    on<AddPdfAnnotation>(_onAddAnnotation);
    on<UpdatePdfAnnotation>(_onUpdateAnnotation);
    on<DeletePdfAnnotation>(_onDeleteAnnotation);
    on<AddPdfBookmark>(_onAddBookmark);
    on<RemovePdfBookmark>(_onRemoveBookmark);
    on<UpdatePdfBookmark>(_onUpdateBookmark);
    on<TogglePdfBookmarkPanel>(_onToggleBookmarkPanel);
  }

  // ── Lifecycle ────────────────────────────────────────────────

  void _onOpen(
    OpenPdfForAnnotation event,
    Emitter<PdfAnnotationState> emit,
  ) {
    emit(PdfAnnotationState(
      filePath: event.filePath,
      title: event.title,
      pageCount: event.pageCount,
      currentPageIndex: 0,
    ));
  }

  void _onClose(
    ClosePdfAnnotation event,
    Emitter<PdfAnnotationState> emit,
  ) =>
      emit(const PdfAnnotationState());

  // ── Navigation ───────────────────────────────────────────────

  void _onNavigate(
    NavigateToPdfPage event,
    Emitter<PdfAnnotationState> emit,
  ) {
    final clamped =
        event.pageIndex.clamp(0, state.pageCount - 1);
    emit(state.copyWith(
      currentPageIndex: clamped,
      clearSelection: true,
    ));
  }

  // ── Text layer ───────────────────────────────────────────────

  void _onTextLayerLoaded(
    PdfTextLayerLoaded event,
    Emitter<PdfAnnotationState> emit,
  ) {
    final updated = Map<int, List<dynamic>>.of(
      state.textSpansByPage,
    );
    updated[event.pageIndex] = event.spans;
    emit(state.copyWith(textSpansByPage: Map.castFrom(updated)));
  }

  // ── Text selection ───────────────────────────────────────────

  void _onSelectText(
    SelectPdfText event,
    Emitter<PdfAnnotationState> emit,
  ) =>
      emit(state.copyWith(
        selectedStartSpanIndex: event.startSpanIndex,
        selectedEndSpanIndex: event.endSpanIndex,
      ));

  void _onClearSelection(
    ClearPdfTextSelection event,
    Emitter<PdfAnnotationState> emit,
  ) =>
      emit(state.copyWith(clearSelection: true));

  // ── Tool / colour ────────────────────────────────────────────

  void _onSetTool(
    SetAnnotationTool event,
    Emitter<PdfAnnotationState> emit,
  ) =>
      emit(state.copyWith(activeTool: event.tool));

  void _onSetColor(
    SetAnnotationColor event,
    Emitter<PdfAnnotationState> emit,
  ) =>
      emit(state.copyWith(activeColor: event.color));

  // ── Annotation CRUD ──────────────────────────────────────────

  void _onAddAnnotation(
    AddPdfAnnotation event,
    Emitter<PdfAnnotationState> emit,
  ) {
    final updated = [
      ...state.annotations,
      event.annotation,
    ];
    emit(state.copyWith(
      annotations: updated,
      clearSelection: true,
    ));
  }

  void _onUpdateAnnotation(
    UpdatePdfAnnotation event,
    Emitter<PdfAnnotationState> emit,
  ) {
    final updated = state.annotations.map((a) {
      if (a.id == event.annotation.id) return event.annotation;
      return a;
    }).toList();
    emit(state.copyWith(annotations: updated));
  }

  void _onDeleteAnnotation(
    DeletePdfAnnotation event,
    Emitter<PdfAnnotationState> emit,
  ) {
    final updated = state.annotations
        .where((a) => a.id != event.annotationId)
        .toList();
    emit(state.copyWith(annotations: updated));
  }

  // ── Bookmarks ────────────────────────────────────────────────

  void _onAddBookmark(
    AddPdfBookmark event,
    Emitter<PdfAnnotationState> emit,
  ) {
    // Prevent duplicate bookmarks for the same page.
    if (state.bookmarks
        .any((b) => b.pageIndex == event.bookmark.pageIndex)) {
      return;
    }
    emit(state.copyWith(
      bookmarks: [...state.bookmarks, event.bookmark],
    ));
  }

  void _onRemoveBookmark(
    RemovePdfBookmark event,
    Emitter<PdfAnnotationState> emit,
  ) {
    final updated = state.bookmarks
        .where((b) => b.id != event.bookmarkId)
        .toList();
    emit(state.copyWith(bookmarks: updated));
  }

  void _onUpdateBookmark(
    UpdatePdfBookmark event,
    Emitter<PdfAnnotationState> emit,
  ) {
    final updated = state.bookmarks.map((b) {
      if (b.id == event.bookmark.id) return event.bookmark;
      return b;
    }).toList();
    emit(state.copyWith(bookmarks: updated));
  }

  void _onToggleBookmarkPanel(
    TogglePdfBookmarkPanel event,
    Emitter<PdfAnnotationState> emit,
  ) =>
      emit(state.copyWith(
        isBookmarkPanelOpen: !state.isBookmarkPanelOpen,
      ));
}
