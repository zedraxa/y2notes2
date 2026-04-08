import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:biscuits/features/audio_sync/domain/entities/audio_recording.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/canvas/domain/models/canvas_config.dart';
import 'package:biscuits/features/documents/domain/entities/notebook.dart';
import 'package:biscuits/features/documents/domain/entities/notebook_page.dart';
import 'package:biscuits/features/math_graph/domain/entities/graph_element.dart';
import 'package:biscuits/features/media/domain/entities/media_element.dart';
import 'package:biscuits/features/pdf_annotation/domain/entities/pdf_annotation.dart';
import 'package:biscuits/features/rich_text/domain/entities/rich_text_element.dart';
import 'package:biscuits/features/shapes/domain/entities/shape_element.dart';
import 'package:biscuits/features/stickers/domain/entities/sticker_element.dart';

/// Handles persistence of [Notebook] data using [SharedPreferences].
///
/// Each notebook is stored under its own key (`document_notebook_{id}`) so
/// multiple notebooks can be persisted simultaneously.
///
/// Images (PDF background images) are *not* serialised — they will be absent
/// after a cold start.  Callers should re-import the source file if the
/// background image is needed again.
///
/// **Storage limitation**: SharedPreferences is suitable for small notebooks.
/// Heavy use (many pages, dense strokes) can exceed platform-specific
/// SharedPreferences limits (~1–2 MB on some platforms).  For production use
/// with large notebooks, consider migrating to a local database (e.g.
/// sqflite or Hive).
class DocumentRepository {
  DocumentRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'document_notebook_';

  /// Returns the storage key for a given notebook [id].
  static String _keyFor(String id) => '$_keyPrefix$id';

  // ── Persistence ─────────────────────────────────────────────────────────────

  /// Saves the [notebook] to persistent storage, keyed by its ID.
  Future<void> saveNotebook(Notebook notebook) async {
    final json = jsonEncode(_notebookToJson(notebook));
    await _prefs.setString(_keyFor(notebook.id), json);
  }

  /// Loads a notebook by [id], or returns `null` if not found.
  Future<Notebook?> loadNotebook([String? id]) async {
    // If no id provided, try to load any notebook (legacy behaviour).
    if (id == null) {
      // Check legacy single-notebook key first.
      final legacy = _prefs.getString('document_notebook');
      if (legacy != null) {
        try {
          return _notebookFromJson(
              jsonDecode(legacy) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    final raw = _prefs.getString(_keyFor(id));
    if (raw == null) {
      // Fall back to legacy key if it matches.
      final legacy = _prefs.getString('document_notebook');
      if (legacy != null) {
        try {
          final nb = _notebookFromJson(
              jsonDecode(legacy) as Map<String, dynamic>);
          if (nb.id == id) return nb;
        } catch (_) {
          // Ignore corrupt legacy data.
        }
      }
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _notebookFromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Removes the persisted notebook with the given [id].
  Future<void> deleteNotebook([String? id]) async {
    if (id != null) {
      await _prefs.remove(_keyFor(id));
    } else {
      await _prefs.remove('document_notebook');
    }
  }

  // ── Serialisation helpers ────────────────────────────────────────────────────

  Map<String, dynamic> _notebookToJson(Notebook nb) => {
        'id': nb.id,
        'title': nb.title,
        if (nb.description != null) 'description': nb.description,
        'createdAt': nb.createdAt.toIso8601String(),
        'updatedAt': nb.updatedAt.toIso8601String(),
        'cover': nb.cover.toJson(),
        'pages': nb.pages.map(_pageToJson).toList(),
      };

  Notebook _notebookFromJson(Map<String, dynamic> json) => Notebook(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        cover: _coverFromJson(json['cover']),
        pages: (json['pages'] as List<dynamic>)
            .map((p) => _pageFromJson(p as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> _pageToJson(NotebookPage page) => {
        'id': page.id,
        'pageNumber': page.pageNumber,
        if (page.title != null) 'title': page.title,
        'isBookmarked': page.isBookmarked,
        'strokes': page.strokes.map((s) => s.toJson()).toList(),
        'shapes': page.shapes.map((s) => s.toJson()).toList(),
        'stickers': page.stickers.map((s) => s.toJson()).toList(),
        'graphs': page.graphs.map((g) => g.toJson()).toList(),
        'pdfAnnotations':
            page.pdfAnnotations.map((a) => a.toJson()).toList(),
        'mediaElements':
            page.mediaElements.map((m) => m.toJson()).toList(),
        'richTexts': page.richTexts.map((r) => r.toJson()).toList(),
        'audioRecordings':
            page.audioRecordings.map((a) => a.toJson()).toList(),
        'config': _configToJson(page.config),
        if (page.backgroundPdfPath != null)
          'backgroundPdfPath': page.backgroundPdfPath,
      };

  NotebookPage _pageFromJson(Map<String, dynamic> json) => NotebookPage(
        id: json['id'] as String,
        pageNumber: json['pageNumber'] as int,
        title: json['title'] as String?,
        isBookmarked: json['isBookmarked'] as bool? ?? false,
        strokes: (json['strokes'] as List<dynamic>?)
                ?.map((s) => Stroke.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        shapes: (json['shapes'] as List<dynamic>?)
                ?.map(
                    (s) => ShapeElement.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        stickers: (json['stickers'] as List<dynamic>?)
                ?.map((s) =>
                    StickerElement.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        graphs: (json['graphs'] as List<dynamic>?)
                ?.map(
                    (g) => GraphElement.fromJson(g as Map<String, dynamic>))
                .toList() ??
            const [],
        pdfAnnotations: (json['pdfAnnotations'] as List<dynamic>?)
                ?.map(
                    (a) => PdfAnnotation.fromJson(a as Map<String, dynamic>))
                .toList() ??
            const [],
        mediaElements: (json['mediaElements'] as List<dynamic>?)
                ?.map(
                    (m) => MediaElement.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const [],
        richTexts: (json['richTexts'] as List<dynamic>?)
                ?.map((r) =>
                    RichTextElement.fromJson(r as Map<String, dynamic>))
                .toList() ??
            const [],
        audioRecordings: (json['audioRecordings'] as List<dynamic>?)
                ?.map((a) =>
                    AudioRecording.fromJson(a as Map<String, dynamic>))
                .toList() ??
            const [],
        config: _configFromJson(json['config'] as Map<String, dynamic>),
        backgroundPdfPath: json['backgroundPdfPath'] as String?,
      );

  Map<String, dynamic> _configToJson(CanvasConfig c) => {
        'width': c.width,
        'height': c.height,
        'template': c.template.name,
        'lineSpacing': c.lineSpacing,
        'gridSpacing': c.gridSpacing,
        'dotSpacing': c.dotSpacing,
        'showMargin': c.showMargin,
      };

  CanvasConfig _configFromJson(Map<String, dynamic> json) => CanvasConfig(
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        template: PageTemplate.values.byName(json['template'] as String),
        lineSpacing: (json['lineSpacing'] as num).toDouble(),
        gridSpacing: (json['gridSpacing'] as num).toDouble(),
        dotSpacing: (json['dotSpacing'] as num).toDouble(),
        showMargin: json['showMargin'] as bool,
      );

  /// Deserialises a cover from [raw].
  ///
  /// Supports both the legacy String format (e.g. `"blue"`) and the new
  /// [NotebookCoverConfig] JSON map `{"color": 0xFF2563EB, "material": "matte"}`.
  NotebookCoverConfig _coverFromJson(dynamic raw) {
    if (raw is String) {
      return NotebookCoverConfig.fromLegacyName(raw);
    }
    if (raw is Map<String, dynamic>) {
      return NotebookCoverConfig.fromJson(raw);
    }
    return NotebookCoverConfig.azure;
  }
}
