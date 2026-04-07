import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/documents/domain/entities/canvas_elements.dart';
import 'package:y2notes2/features/pdf_annotation/domain/entities/pdf_annotation.dart';

/// A single page in a [Notebook].
class NotebookPage extends Equatable {
  NotebookPage({
    String? id,
    required this.pageNumber,
    this.title,
    this.isBookmarked = false,
    this.strokes = const [],
    this.shapes = const [],
    this.stickers = const [],
    this.pdfAnnotations = const [],
    this.config = const CanvasConfig(),
    this.backgroundImage,
    this.backgroundPdfPath,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final int pageNumber;

  /// Optional user-assigned title for the page (e.g. "Chapter 1 Notes").
  final String? title;

  /// Whether this page has been bookmarked for quick navigation.
  final bool isBookmarked;

  final List<Stroke> strokes;
  final List<ShapeElement> shapes;
  final List<StickerElement> stickers;

  /// PDF annotations (highlights, underlines, sticky notes, etc.)
  /// for pages imported from a PDF.
  final List<PdfAnnotation> pdfAnnotations;

  final CanvasConfig config;

  /// Rasterised background image (e.g. an imported PDF page).
  final ui.Image? backgroundImage;

  /// Path to the source PDF if this page was imported from a PDF file.
  final String? backgroundPdfPath;

  bool get hasBackground =>
      backgroundImage != null || backgroundPdfPath != null;

  /// Whether this page originated from a PDF import and therefore
  /// supports PDF-specific annotations.
  bool get isPdfPage => backgroundPdfPath != null;

  /// Display label: the user-assigned [title] if set, otherwise "Page N".
  String get displayTitle => title ?? 'Page $pageNumber';

  NotebookPage copyWith({
    int? pageNumber,
    String? title,
    bool clearTitle = false,
    bool? isBookmarked,
    List<Stroke>? strokes,
    List<ShapeElement>? shapes,
    List<StickerElement>? stickers,
    List<PdfAnnotation>? pdfAnnotations,
    CanvasConfig? config,
    ui.Image? backgroundImage,
    String? backgroundPdfPath,
    bool clearBackground = false,
  }) =>
      NotebookPage(
        id: id,
        pageNumber: pageNumber ?? this.pageNumber,
        title: clearTitle ? null : (title ?? this.title),
        isBookmarked: isBookmarked ?? this.isBookmarked,
        strokes: strokes ?? this.strokes,
        shapes: shapes ?? this.shapes,
        stickers: stickers ?? this.stickers,
        pdfAnnotations: pdfAnnotations ?? this.pdfAnnotations,
        config: config ?? this.config,
        backgroundImage:
            clearBackground ? null : (backgroundImage ?? this.backgroundImage),
        backgroundPdfPath: clearBackground
            ? null
            : (backgroundPdfPath ?? this.backgroundPdfPath),
      );

  @override
  List<Object?> get props => [
        id,
        pageNumber,
        title,
        isBookmarked,
        strokes,
        shapes,
        stickers,
        pdfAnnotations,
        config,
        backgroundPdfPath,
      ];
}
