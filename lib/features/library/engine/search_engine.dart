import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/domain/entities/search_result.dart';
import 'package:biscuits/features/library/engine/content_indexer.dart';

/// Optional filters to narrow down search results.
class SearchFilters {
  const SearchFilters({
    this.tagIds,
    this.types,
    this.dateRange,
    this.folderId,
    this.isFavorite,
  });

  final Set<String>? tagIds;
  final Set<LibraryItemType>? types;
  final ({DateTime start, DateTime end})? dateRange;
  final String? folderId;
  final bool? isFavorite;

  bool matches(LibraryItem item) {
    if (tagIds != null && !item.tagIds.any(tagIds!.contains)) return false;
    if (types != null && !types!.contains(item.type)) return false;
    if (folderId != null && item.folderId != folderId) return false;
    if (isFavorite != null && item.isFavorite != isFavorite) return false;
    if (dateRange != null) {
      if (item.updatedAt.isBefore(dateRange!.start) ||
          item.updatedAt.isAfter(dateRange!.end)) {
        return false;
      }
    }
    return true;
  }
}

/// The central search engine for the library.
///
/// Wraps [ContentIndexer] and adds:
/// - In-memory item registry for scoring
/// - Recent-search history (last 10 queries)
/// - Snippet generation
class SearchEngine {
  SearchEngine() : _indexer = ContentIndexer();

  final ContentIndexer _indexer;

  /// All known items, kept in sync via [indexItem] / [removeFromIndex].
  final Map<String, LibraryItem> _items = {};

  /// Circular buffer of the last 10 search queries.
  final List<String> _recentSearches = [];
  static const int _maxRecentSearches = 10;

  // ── Index management ────────────────────────────────────────────────────

  /// Add or update [item] in the index.
  ///
  /// Provide optional [contentFields] (fieldName → text) for full-text search
  /// of the item's body content (notes, cards, handwriting OCR, etc.).
  void indexItem(LibraryItem item, {Map<String, String>? contentFields}) {
    _items[item.id] = item;
    _indexer.indexItem(item, contentFields: contentFields);
  }

  /// Remove an item from the index by [itemId].
  void removeFromIndex(String itemId) {
    _items.remove(itemId);
    _indexer.removeItem(itemId);
  }

  /// Rebuild the index from scratch using [items].
  ///
  /// [contentProvider] optionally maps an item id → additional content fields.
  void rebuildIndex(
    List<LibraryItem> items, {
    Map<String, Map<String, String>> contentProvider = const {},
  }) {
    _indexer.clear();
    _items.clear();
    for (final item in items) {
      indexItem(item, contentFields: contentProvider[item.id]);
    }
  }

  // ── Search ───────────────────────────────────────────────────────────────

  /// Search for [query] and return ranked [SearchResult]s.
  ///
  /// Trims whitespace; returns an empty list for blank queries.
  List<SearchResult> search(String query, {SearchFilters? filters}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    _recordSearch(trimmed);

    // Text + fuzzy index search.
    final indexHits = _indexer.query(trimmed);

    // Build and rank results.
    final results = <SearchResult>[];

    for (final entry in indexHits.entries) {
      final item = _items[entry.key];
      if (item == null || item.isInTrash) continue;
      if (filters != null && !filters.matches(item)) continue;

      final matches = entry.value;
      final snippet = _buildSnippet(entry.key, matches);
      final score = _score(item, trimmed, matches);

      results.add(SearchResult(
        item: item,
        relevanceScore: score,
        matches: matches,
        previewSnippet: snippet,
      ));
    }

    // Also include items whose name contains the query but weren't in index.
    for (final item in _items.values) {
      if (item.isInTrash) continue;
      if (indexHits.containsKey(item.id)) continue;
      if (filters != null && !filters.matches(item)) continue;
      if (!item.name.toLowerCase().contains(trimmed.toLowerCase())) continue;

      results.add(SearchResult(
        item: item,
        relevanceScore: 0.5,
        matches: [],
        previewSnippet: item.name,
      ));
    }

    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  // ── Recent searches ──────────────────────────────────────────────────────

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  void clearRecentSearches() => _recentSearches.clear();

  // ── Private helpers ──────────────────────────────────────────────────────

  void _recordSearch(String query) {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches.removeLast();
    }
  }

  String _buildSnippet(String itemId, List<SearchMatch> matches) {
    final fields = _indexer.fieldsFor(itemId);
    if (fields == null || matches.isEmpty) return '';
    // Prefer 'content' field for snippet; fall back to first available.
    final text = fields['content'] ?? fields.values.firstOrNull ?? '';
    return buildPreviewSnippet(text, matches);
  }

  /// Compute a relevance score in [0, 1].
  double _score(LibraryItem item, String query, List<SearchMatch> matches) {
    double score = 0.0;

    // Title match is worth the most.
    if (item.name.toLowerCase().contains(query.toLowerCase())) {
      score += 0.6;
    }

    // Each content match adds a small amount (capped).
    final contentBonus = (matches.length * 0.05).clamp(0.0, 0.3);
    score += contentBonus;

    // Recency bonus (items modified within 7 days get +0.1).
    if (DateTime.now().difference(item.updatedAt).inDays <= 7) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }
}
