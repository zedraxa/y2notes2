import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/documents/domain/entities/canvas_elements.dart';

/// A single page in a [Notebook].
class NotebookPage extends Equatable {
  NotebookPage({
    String? id,
    required this.pageNumber,
    this.strokes = const [],
    this.shapes = const [],
    this.stickers = const [],
    this.config = const CanvasConfig(),
    this.backgroundImage,
    this.backgroundPdfPath,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final int pageNumber;
  final List<Stroke> strokes;
  final List<ShapeElement> shapes;
  final List<StickerElement> stickers;
  final CanvasConfig config;

  /// Rasterised background image (e.g. an imported PDF page).
  final ui.Image? backgroundImage;

  /// Path to the source PDF if this page was imported from a PDF file.
  final String? backgroundPdfPath;

  bool get hasBackground =>
      backgroundImage != null || backgroundPdfPath != null;

  NotebookPage copyWith({
    int? pageNumber,
    List<Stroke>? strokes,
    List<ShapeElement>? shapes,
    List<StickerElement>? stickers,
    CanvasConfig? config,
    ui.Image? backgroundImage,
    String? backgroundPdfPath,
    bool clearBackground = false,
  }) =>
      NotebookPage(
        id: id,
        pageNumber: pageNumber ?? this.pageNumber,
        strokes: strokes ?? this.strokes,
        shapes: shapes ?? this.shapes,
        stickers: stickers ?? this.stickers,
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
        strokes,
        shapes,
        stickers,
        config,
        backgroundPdfPath,
      ];
}
