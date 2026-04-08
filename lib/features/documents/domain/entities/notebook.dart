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

// ── Cover pattern ──────────────────────────────────────────────────────────

/// Decorative pattern overlaid on a notebook cover.
enum CoverPattern {
  /// No pattern — plain cover.
  none,

  /// Horizontal and/or vertical stripes.
  stripes,

  /// Evenly spaced polka dots.
  dots,

  /// Chevron / zig-zag pattern.
  chevron,

  /// Repeating diamond / argyle pattern.
  diamond,

  /// Crisscross plaid weave.
  plaid,

  /// Interlocking Moroccan tile motif.
  moroccan,

  /// Herringbone / parquet weave.
  herringbone,
}

// ── Cover emblem ───────────────────────────────────────────────────────────

/// Decorative emblem / icon displayed on a notebook cover.
enum CoverEmblem {
  /// No emblem.
  none,

  /// Five-pointed star.
  star,

  /// Heart shape.
  heart,

  /// Leaf / botanical element.
  leaf,

  /// Crown / regal crest.
  crown,

  /// Compass rose.
  compass,

  /// Feather quill.
  feather,

  /// Crescent moon.
  moon,
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
    this.pattern = CoverPattern.none,
    this.emblem = CoverEmblem.none,
  });

  /// Dominant cover color.
  final Color color;

  /// Surface material / finish.
  final CoverMaterial material;

  /// Decorative pattern overlaid on the cover surface.
  final CoverPattern pattern;

  /// Emblem / icon displayed on the cover.
  final CoverEmblem emblem;

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

  // ── Rich presets (with pattern + emblem) ─────────────────────────────────

  static const NotebookCoverConfig classicJournal = NotebookCoverConfig(
    color: Color(0xFF1E293B),
    material: CoverMaterial.leather,
    pattern: CoverPattern.herringbone,
    emblem: CoverEmblem.compass,
  );

  static const NotebookCoverConfig gardenNotes = NotebookCoverConfig(
    color: Color(0xFF16A34A),
    material: CoverMaterial.linen,
    pattern: CoverPattern.dots,
    emblem: CoverEmblem.leaf,
  );

  static const NotebookCoverConfig nightSky = NotebookCoverConfig(
    color: Color(0xFF4338CA),
    material: CoverMaterial.matte,
    pattern: CoverPattern.diamond,
    emblem: CoverEmblem.moon,
  );

  static const NotebookCoverConfig royalDiary = NotebookCoverConfig(
    color: Color(0xFF7C3AED),
    material: CoverMaterial.glossy,
    pattern: CoverPattern.plaid,
    emblem: CoverEmblem.crown,
  );

  NotebookCoverConfig copyWith({
    Color? color,
    CoverMaterial? material,
    CoverPattern? pattern,
    CoverEmblem? emblem,
  }) =>
      NotebookCoverConfig(
        color: color ?? this.color,
        material: material ?? this.material,
        pattern: pattern ?? this.pattern,
        emblem: emblem ?? this.emblem,
      );

  /// Serialise to a JSON map.
  Map<String, dynamic> toJson() => {
        'color': color.value,
        'material': material.name,
        if (pattern != CoverPattern.none) 'pattern': pattern.name,
        if (emblem != CoverEmblem.none) 'emblem': emblem.name,
      };

  /// Deserialise from a JSON map.
  factory NotebookCoverConfig.fromJson(Map<String, dynamic> json) {
    final patternName = json['pattern'] as String?;
    final emblemName = json['emblem'] as String?;
    return NotebookCoverConfig(
      color: Color(json['color'] as int),
      material: CoverMaterial.values.byName(json['material'] as String),
      pattern: patternName != null
          ? CoverPattern.values.byName(patternName)
          : CoverPattern.none,
      emblem: emblemName != null
          ? CoverEmblem.values.byName(emblemName)
          : CoverEmblem.none,
    );
  }

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
  List<Object?> get props => [color, material, pattern, emblem];
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
