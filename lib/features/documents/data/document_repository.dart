import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/documents/domain/entities/notebook.dart';
import 'package:y2notes2/features/documents/domain/entities/notebook_page.dart';

/// Handles persistence of [Notebook] data using [SharedPreferences].
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

  static const _notebookKey = 'document_notebook';

  // ── Persistence ─────────────────────────────────────────────────────────────

  /// Saves the [notebook] to persistent storage.
  Future<void> saveNotebook(Notebook notebook) async {
    final json = jsonEncode(_notebookToJson(notebook));
    await _prefs.setString(_notebookKey, json);
  }

  /// Loads and returns the persisted notebook, or `null` if none exists.
  Future<Notebook?> loadNotebook() async {
    final raw = _prefs.getString(_notebookKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _notebookFromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Removes the persisted notebook.
  Future<void> deleteNotebook() async {
    await _prefs.remove(_notebookKey);
  }

  // ── Serialisation helpers ────────────────────────────────────────────────────

  Map<String, dynamic> _notebookToJson(Notebook nb) => {
        'id': nb.id,
        'title': nb.title,
        if (nb.description != null) 'description': nb.description,
        'createdAt': nb.createdAt.toIso8601String(),
        'updatedAt': nb.updatedAt.toIso8601String(),
        'cover': nb.cover.name,
        'pages': nb.pages.map(_pageToJson).toList(),
      };

  Notebook _notebookFromJson(Map<String, dynamic> json) => Notebook(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        cover: NotebookCover.values.byName(json['cover'] as String),
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
        'config': _configToJson(page.config),
        if (page.backgroundPdfPath != null)
          'backgroundPdfPath': page.backgroundPdfPath,
      };

  NotebookPage _pageFromJson(Map<String, dynamic> json) => NotebookPage(
        id: json['id'] as String,
        pageNumber: json['pageNumber'] as int,
        title: json['title'] as String?,
        isBookmarked: json['isBookmarked'] as bool? ?? false,
        strokes: (json['strokes'] as List<dynamic>)
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .toList(),
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
}
