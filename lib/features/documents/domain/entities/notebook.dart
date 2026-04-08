import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:biscuits/features/documents/domain/entities/notebook_page.dart';

// ── Cover material ─────────────────────────────────────────────────────────

/// Visual material / finish of a notebook cover.
enum CoverMaterial {
  /// Smooth matte finish — the default.
  matte,

  /// Textured leather look with subtle grain.
  leather,

  /// Woven canvas texture.
  canvas,

  /// Soft linen fabric texture.
  linen,

  /// Rough kraft-paper feel.
  kraft,

  /// Shiny glossy finish.
  glossy,
}

// ── Cover configuration ────────────────────────────────────────────────────

/// Rich configuration for a notebook cover.
///
/// Replaces the old [NotebookCover] color-only enum with a pair of color +
/// material for richer visual customisation.
class NotebookCoverConfig extends Equatable {
  const NotebookCoverConfig({
    this.color = const Color(0xFF2563EB),
    this.material = CoverMaterial.matte,
  });

  /// Dominant cover color.
  final Color color;

  /// Surface material / finish.
  final CoverMaterial material;

  // ── Built-in presets ──────────────────────────────────────────────────────

  static const NotebookCoverConfig azure =
      NotebookCoverConfig(color: Color(0xFF2563EB), material: CoverMaterial.matte);
  static const NotebookCoverConfig scarlet =
      NotebookCoverConfig(color: Color(0xFFDC2626), material: CoverMaterial.matte);
  static const NotebookCoverConfig emerald =
      NotebookCoverConfig(color: Color(0xFF16A34A), material: CoverMaterial.matte);
  static const NotebookCoverConfig violet =
      NotebookCoverConfig(color: Color(0xFF7C3AED), material: CoverMaterial.matte);
  static const NotebookCoverConfig amber =
      NotebookCoverConfig(color: Color(0xFFD97706), material: CoverMaterial.matte);
  static const NotebookCoverConfig slate =
      NotebookCoverConfig(color: Color(0xFF1E293B), material: CoverMaterial.matte);
  static const NotebookCoverConfig ivory =
      NotebookCoverConfig(color: Color(0xFFFFFBEB), material: CoverMaterial.matte);
  static const NotebookCoverConfig coral =
      NotebookCoverConfig(color: Color(0xFFF97316), material: CoverMaterial.leather);
  static const NotebookCoverConfig forest =
      NotebookCoverConfig(color: Color(0xFF166534), material: CoverMaterial.canvas);
  static const NotebookCoverConfig indigo =
      NotebookCoverConfig(color: Color(0xFF4338CA), material: CoverMaterial.linen);
  static const NotebookCoverConfig rose =
      NotebookCoverConfig(color: Color(0xFFE11D48), material: CoverMaterial.glossy);
  static const NotebookCoverConfig teal =
      NotebookCoverConfig(color: Color(0xFF0F766E), material: CoverMaterial.kraft);

  NotebookCoverConfig copyWith({
    Color? color,
    CoverMaterial? material,
  }) =>
      NotebookCoverConfig(
        color: color ?? this.color,
        material: material ?? this.material,
      );

  /// Serialise to a JSON map.
  Map<String, dynamic> toJson() => {
        'color': color.value,
        'material': material.name,
      };

  /// Deserialise from a JSON map.
  factory NotebookCoverConfig.fromJson(Map<String, dynamic> json) =>
      NotebookCoverConfig(
        color: Color(json['color'] as int),
        material: CoverMaterial.values.byName(json['material'] as String),
      );

  /// Convert a legacy [NotebookCover] name to a [NotebookCoverConfig].
  factory NotebookCoverConfig.fromLegacyName(String name) {
    switch (name) {
      case 'blue':
        return azure;
      case 'red':
        return scarlet;
      case 'green':
        return emerald;
      case 'purple':
        return violet;
      case 'yellow':
        return amber;
      case 'black':
        return slate;
      case 'white':
        return ivory;
      default:
        return azure;
    }
  }

  @override
  List<Object?> get props => [color, material];
}

// ── Notebook ──────────────────────────────────────────────────────────────

/// A multi-page notebook that groups [NotebookPage]s together.
class Notebook extends Equatable {
  Notebook({
    String? id,
    required this.title,
    this.description,
    this.pages = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.cover = NotebookCoverConfig.azure,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;

  /// Optional description or subtitle for the notebook.
  final String? description;

  final List<NotebookPage> pages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NotebookCoverConfig cover;

  int get pageCount => pages.length;

  bool get isEmpty => pages.isEmpty;

  /// Returns all pages that have been bookmarked.
  List<NotebookPage> get bookmarkedPages =>
      pages.where((p) => p.isBookmarked).toList();

  /// Returns all pages that have a user-assigned title.
  List<NotebookPage> get titledPages =>
      pages.where((p) => p.title != null).toList();

  Notebook copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    List<NotebookPage>? pages,
    DateTime? updatedAt,
    NotebookCoverConfig? cover,
  }) =>
      Notebook(
        id: id,
        title: title ?? this.title,
        description:
            clearDescription ? null : (description ?? this.description),
        pages: pages ?? this.pages,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        cover: cover ?? this.cover,
      );

  /// Returns a new [Notebook] with the page at [pageIndex] replaced.
  Notebook updatePage(int pageIndex, NotebookPage page) {
    final updated = List<NotebookPage>.of(pages);
    updated[pageIndex] = page;
    return copyWith(pages: updated);
  }

  /// Returns a new [Notebook] with [page] appended.
  Notebook addPage(NotebookPage page) =>
      copyWith(pages: [...pages, page]);

  /// Returns a new [Notebook] with the page at [pageIndex] removed.
  Notebook removePage(int pageIndex) {
    final updated = List<NotebookPage>.of(pages)..removeAt(pageIndex);
    // Re-number remaining pages.
    final renumbered = updated
        .asMap()
        .map((i, p) => MapEntry(i, p.copyWith(pageNumber: i + 1)))
        .values
        .toList();
    return copyWith(pages: renumbered);
  }

  @override
  List<Object?> get props => [id, title, description, pages, createdAt, cover];
}
