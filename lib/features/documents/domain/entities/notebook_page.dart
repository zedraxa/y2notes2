import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/features/audio_sync/domain/entities/audio_recording.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/documents/domain/entities/canvas_elements.dart';
import 'package:y2notes2/features/rich_text/domain/entities/rich_text_element.dart';

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
    this.richTexts = const [],
    this.config = const CanvasConfig(),
    this.backgroundImage,
    this.backgroundPdfPath,
    this.audioRecordings = const [],
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

  /// Rich text blocks placed on this page.
  final List<RichTextElement> richTexts;

  final CanvasConfig config;

  /// Rasterised background image (e.g. an imported PDF page).
  final ui.Image? backgroundImage;

  /// Path to the source PDF if this page was imported from a PDF file.
  final String? backgroundPdfPath;

  /// Audio recordings with stroke synchronisation data.
  final List<AudioRecording> audioRecordings;

  bool get hasBackground =>
      backgroundImage != null || backgroundPdfPath != null;

  /// Whether this page has any audio recordings.
  bool get hasAudioRecordings =>
      audioRecordings.isNotEmpty;

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
    List<RichTextElement>? richTexts,
    CanvasConfig? config,
    ui.Image? backgroundImage,
    String? backgroundPdfPath,
    bool clearBackground = false,
    List<AudioRecording>? audioRecordings,
  }) =>
      NotebookPage(
        id: id,
        pageNumber: pageNumber ?? this.pageNumber,
        title: clearTitle ? null : (title ?? this.title),
        isBookmarked: isBookmarked ?? this.isBookmarked,
        strokes: strokes ?? this.strokes,
        shapes: shapes ?? this.shapes,
        stickers: stickers ?? this.stickers,
        richTexts: richTexts ?? this.richTexts,
        config: config ?? this.config,
        backgroundImage:
            clearBackground ? null : (backgroundImage ?? this.backgroundImage),
        backgroundPdfPath: clearBackground
            ? null
            : (backgroundPdfPath ?? this.backgroundPdfPath),
        audioRecordings:
            audioRecordings ?? this.audioRecordings,
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
        richTexts,
        config,
        backgroundPdfPath,
        audioRecordings,
      ];
}
