import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_annotation.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_bookmark.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_text_span.dart';

/// Base class for PDF annotation events.
abstract class PdfAnnotationEvent extends Equatable {
  const PdfAnnotationEvent();

  @override
  List<Object?> get props => [];
}

// ── Document lifecycle ─────────────────────────────────────────

/// Open a PDF for annotation.
class OpenPdfForAnnotation extends PdfAnnotationEvent {
  const OpenPdfForAnnotation({
    required this.filePath,
    required this.pageCount,
    this.title,
  });

  final String filePath;
  final int pageCount;
  final String? title;

  @override
  List<Object?> get props => [filePath, pageCount, title];
}

/// Close the current PDF annotation session.
class ClosePdfAnnotation extends PdfAnnotationEvent {
  const ClosePdfAnnotation();
}

// ── Page navigation ────────────────────────────────────────────

/// Navigate to a specific PDF page.
class NavigateToPdfPage extends PdfAnnotationEvent {
  const NavigateToPdfPage({required this.pageIndex});
  final int pageIndex;
  @override
  List<Object?> get props => [pageIndex];
}

// ── Text layer ─────────────────────────────────────────────────

/// Loaded text spans for a page (from OCR or PDF text extraction).
class PdfTextLayerLoaded extends PdfAnnotationEvent {
  const PdfTextLayerLoaded({
    required this.pageIndex,
    required this.spans,
  });
  final int pageIndex;
  final List<PdfTextSpan> spans;
  @override
  List<Object?> get props => [pageIndex, spans];
}

// ── Text selection ─────────────────────────────────────────────

/// Begin / update / end text selection on a PDF page.
class SelectPdfText extends PdfAnnotationEvent {
  const SelectPdfText({
    required this.startSpanIndex,
    required this.endSpanIndex,
  });
  final int startSpanIndex;
  final int endSpanIndex;
  @override
  List<Object?> get props => [startSpanIndex, endSpanIndex];
}

/// Clear the current text selection.
class ClearPdfTextSelection extends PdfAnnotationEvent {
  const ClearPdfTextSelection();
}

// ── Annotation tool ────────────────────────────────────────────

/// Select the active annotation tool.
class SetAnnotationTool extends PdfAnnotationEvent {
  const SetAnnotationTool({required this.tool});
  final PdfAnnotationTool tool;
  @override
  List<Object?> get props => [tool];
}

/// Available PDF annotation tools.
enum PdfAnnotationTool {
  /// No tool — touch for pan/zoom only.
  none,

  /// Text selection mode.
  textSelect,

  /// Highlight selected text.
  highlight,

  /// Underline selected text.
  underline,

  /// Strikethrough selected text.
  strikethrough,

  /// Place a sticky note at a tap location.
  stickyNote,

  /// Fill in a form field.
  formFill,
}

// ── Annotation colour ──────────────────────────────────────────

/// Change the active annotation colour.
class SetAnnotationColor extends PdfAnnotationEvent {
  const SetAnnotationColor({required this.color});
  final Color color;
  @override
  List<Object?> get props => [color];
}

// ── CRUD on annotations ────────────────────────────────────────

/// Add a new annotation (from a completed text selection or tap).
class AddPdfAnnotation extends PdfAnnotationEvent {
  const AddPdfAnnotation({required this.annotation});
  final PdfAnnotation annotation;
  @override
  List<Object?> get props => [annotation];
}

/// Update an existing annotation (e.g. edit sticky-note content).
class UpdatePdfAnnotation extends PdfAnnotationEvent {
  const UpdatePdfAnnotation({required this.annotation});
  final PdfAnnotation annotation;
  @override
  List<Object?> get props => [annotation];
}

/// Delete an annotation by its ID.
class DeletePdfAnnotation extends PdfAnnotationEvent {
  const DeletePdfAnnotation({required this.annotationId});
  final String annotationId;
  @override
  List<Object?> get props => [annotationId];
}

// ── Bookmarks ──────────────────────────────────────────────────

/// Add a PDF bookmark for the given page.
class AddPdfBookmark extends PdfAnnotationEvent {
  const AddPdfBookmark({required this.bookmark});
  final PdfBookmark bookmark;
  @override
  List<Object?> get props => [bookmark];
}

/// Remove a PDF bookmark by its ID.
class RemovePdfBookmark extends PdfAnnotationEvent {
  const RemovePdfBookmark({required this.bookmarkId});
  final String bookmarkId;
  @override
  List<Object?> get props => [bookmarkId];
}

/// Update a bookmark (rename / add note).
class UpdatePdfBookmark extends PdfAnnotationEvent {
  const UpdatePdfBookmark({required this.bookmark});
  final PdfBookmark bookmark;
  @override
  List<Object?> get props => [bookmark];
}

/// Toggle the bookmark panel visibility.
class TogglePdfBookmarkPanel extends PdfAnnotationEvent {
  const TogglePdfBookmarkPanel();
}
