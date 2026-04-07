import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_annotation.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_bookmark.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_text_span.dart';
import 'package:y2notes2/features/pdf_annotation/presentation/bloc/pdf_annotation_event.dart';

/// Immutable state for the PDF annotation feature.
class PdfAnnotationState extends Equatable {
  const PdfAnnotationState({
    this.filePath,
    this.title,
    this.pageCount = 0,
    this.currentPageIndex = 0,
    this.activeTool = PdfAnnotationTool.none,
    this.activeColor = const Color(0x80FFEB3B),
    this.annotations = const [],
    this.bookmarks = const [],
    this.textSpansByPage = const {},
    this.selectedStartSpanIndex,
    this.selectedEndSpanIndex,
    this.isBookmarkPanelOpen = false,
  });

  /// Path to the currently opened PDF file.
  final String? filePath;

  /// Title derived from the file name.
  final String? title;

  /// Total page count.
  final int pageCount;

  /// Zero-based index of the current visible page.
  final int currentPageIndex;

  /// The currently selected annotation tool.
  final PdfAnnotationTool activeTool;

  /// The colour used for new annotations.
  final Color activeColor;

  /// All annotations across all pages.
  final List<PdfAnnotation> annotations;

  /// PDF-specific bookmarks.
  final List<PdfBookmark> bookmarks;

  /// Text spans keyed by page index.
  final Map<int, List<PdfTextSpan>> textSpansByPage;

  /// Text selection state — indices into the current page's span
  /// list.
  final int? selectedStartSpanIndex;
  final int? selectedEndSpanIndex;

  /// Whether the bookmark side-panel is visible.
  final bool isBookmarkPanelOpen;

  // ── Derived getters ──────────────────────────────────────────

  bool get isOpen => filePath != null;

  bool get hasSelection =>
      selectedStartSpanIndex != null &&
      selectedEndSpanIndex != null;

  /// All annotations for the current page.
  List<PdfAnnotation> get currentPageAnnotations =>
      annotations
          .where((a) => a.pageIndex == currentPageIndex)
          .toList();

  /// Sorted bookmarks list.
  List<PdfBookmark> get sortedBookmarks {
    final sorted = List<PdfBookmark>.of(bookmarks);
    sorted.sort((a, b) => a.pageIndex.compareTo(b.pageIndex));
    return sorted;
  }

  /// Whether the current page has a bookmark.
  bool get isCurrentPageBookmarked =>
      bookmarks.any((b) => b.pageIndex == currentPageIndex);

  /// Text spans for the current page.
  List<PdfTextSpan> get currentPageTextSpans =>
      textSpansByPage[currentPageIndex] ?? const [];

  /// The combined selected text (if any).
  String? get selectedText {
    if (!hasSelection) return null;
    final spans = currentPageTextSpans;
    if (spans.isEmpty) return null;
    final start = selectedStartSpanIndex!;
    final end = selectedEndSpanIndex!;
    final lo = start < end ? start : end;
    final hi = start < end ? end : start;
    if (lo < 0 || hi >= spans.length) return null;
    return spans
        .sublist(lo, hi + 1)
        .map((s) => s.text)
        .join(' ');
  }

  /// The bounding rectangle of the current text selection.
  Rect? get selectionRect {
    if (!hasSelection) return null;
    final spans = currentPageTextSpans;
    if (spans.isEmpty) return null;
    final start = selectedStartSpanIndex!;
    final end = selectedEndSpanIndex!;
    final lo = start < end ? start : end;
    final hi = start < end ? end : start;
    if (lo < 0 || hi >= spans.length) return null;
    Rect r = spans[lo].rect;
    for (int i = lo + 1; i <= hi; i++) {
      r = r.expandToInclude(spans[i].rect);
    }
    return r;
  }

  bool get canGoBack => currentPageIndex > 0;

  bool get canGoForward =>
      currentPageIndex < pageCount - 1;

  PdfAnnotationState copyWith({
    String? filePath,
    bool clearFilePath = false,
    String? title,
    bool clearTitle = false,
    int? pageCount,
    int? currentPageIndex,
    PdfAnnotationTool? activeTool,
    Color? activeColor,
    List<PdfAnnotation>? annotations,
    List<PdfBookmark>? bookmarks,
    Map<int, List<PdfTextSpan>>? textSpansByPage,
    int? selectedStartSpanIndex,
    int? selectedEndSpanIndex,
    bool clearSelection = false,
    bool? isBookmarkPanelOpen,
  }) =>
      PdfAnnotationState(
        filePath: clearFilePath
            ? null
            : (filePath ?? this.filePath),
        title: clearTitle ? null : (title ?? this.title),
        pageCount: pageCount ?? this.pageCount,
        currentPageIndex:
            currentPageIndex ?? this.currentPageIndex,
        activeTool: activeTool ?? this.activeTool,
        activeColor: activeColor ?? this.activeColor,
        annotations: annotations ?? this.annotations,
        bookmarks: bookmarks ?? this.bookmarks,
        textSpansByPage:
            textSpansByPage ?? this.textSpansByPage,
        selectedStartSpanIndex: clearSelection
            ? null
            : (selectedStartSpanIndex ??
                this.selectedStartSpanIndex),
        selectedEndSpanIndex: clearSelection
            ? null
            : (selectedEndSpanIndex ??
                this.selectedEndSpanIndex),
        isBookmarkPanelOpen:
            isBookmarkPanelOpen ?? this.isBookmarkPanelOpen,
      );

  @override
  List<Object?> get props => [
        filePath,
        title,
        pageCount,
        currentPageIndex,
        activeTool,
        activeColor,
        annotations,
        bookmarks,
        textSpansByPage,
        selectedStartSpanIndex,
        selectedEndSpanIndex,
        isBookmarkPanelOpen,
      ];
}
