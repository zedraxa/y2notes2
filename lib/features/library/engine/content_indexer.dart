import 'package:y2notes2/features/library/domain/entities/library_item.dart';
import 'package:y2notes2/features/library/domain/entities/search_result.dart';
import 'package:y2notes2/features/library/engine/search_engine.dart';

/// Maintains an inverted index of library items for fast full-text search.
///
/// The index maps normalised tokens → set of item ids that contain the token.
class ContentIndexer {
  ContentIndexer();

  /// token → set of item ids that contain it.
  final Map<String, Set<String>> _invertedIndex = {};

  /// item id → map of field → full field text (for snippet extraction).
  final Map<String, Map<String, String>> _fieldStore = {};

  // ── Public API ──────────────────────────────────────────────────────────

  /// Index (or re-index) a single [item].
  ///
  /// Pass [contentFields] as a map of fieldName → text (e.g. `{'content':
  /// 'hello world'}`). The item name is always indexed automatically.
  void indexItem(LibraryItem item, {Map<String, String>? contentFields}) {
    // Remove stale index entries for this item first.
    removeItem(item.id);

    final fields = <String, String>{
      'title': item.name,
      ...?contentFields,
    };

    _fieldStore[item.id] = fields;

    for (final entry in fields.entries) {
      final tokens = _tokenize(entry.value);
      for (final token in tokens) {
        _invertedIndex.putIfAbsent(token, () => {}).add(item.id);
      }
    }
  }

  /// Remove [itemId] from the index entirely.
  void removeItem(String itemId) {
    final fields = _fieldStore.remove(itemId);
    if (fields == null) return;
    for (final text in fields.values) {
      for (final token in _tokenize(text)) {
        _invertedIndex[token]?.remove(itemId);
        if (_invertedIndex[token]?.isEmpty ?? false) {
          _invertedIndex.remove(token);
        }
      }
    }
  }

  /// Clear the entire index.
  void clear() {
    _invertedIndex.clear();
    _fieldStore.clear();
  }

  /// Search for [query] in the index.
  ///
  /// Returns a map of itemId → list of [SearchMatch] found for that item.
  Map<String, List<SearchMatch>> query(String query) {
    if (query.trim().isEmpty) return {};

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return {};

    // Candidate item ids that match ALL tokens (AND logic for multi-word).
    Set<String>? candidates;
    for (final token in queryTokens) {
      final direct = _invertedIndex[token] ?? {};
      final fuzzy = _fuzzyExpand(token);
      final matches = {...direct, ...fuzzy};
      candidates =
          candidates == null ? matches.toSet() : candidates.intersection(matches);
    }

    if (candidates == null || candidates.isEmpty) return {};

    final results = <String, List<SearchMatch>>{};
    for (final itemId in candidates) {
      final fields = _fieldStore[itemId];
      if (fields == null) continue;
      final matchList = <SearchMatch>[];
      for (final entry in fields.entries) {
        matchList.addAll(_findMatches(entry.key, entry.value, query));
      }
      if (matchList.isNotEmpty) {
        results[itemId] = matchList;
      }
    }
    return results;
  }

  /// Return stored field text for [itemId], useful for snippet generation.
  Map<String, String>? fieldsFor(String itemId) => _fieldStore[itemId];

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Split [text] into lowercase alpha-numeric tokens.
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toList();
  }

  /// Expand a token to nearby tokens using simple Levenshtein-1 variants
  /// (only the direct edit-distance-1 neighbours already present in the index).
  Iterable<String> _fuzzyExpand(String token) sync* {
    if (token.length <= 2) return;
    for (final key in _invertedIndex.keys) {
      if ((key.length - token.length).abs() <= 1 &&
          _levenshtein(token, key) <= 1) {
        yield* _invertedIndex[key] ?? [];
      }
    }
  }

  /// Locate all occurrences of [query] (case-insensitive) within [text] and
  /// return the corresponding [SearchMatch] objects for [field].
  List<SearchMatch> _findMatches(String field, String text, String query) {
    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    final matches = <SearchMatch>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(lowerQ, start);
      if (idx < 0) break;
      matches.add(SearchMatch(field: field, offset: idx, length: query.length));
      start = idx + 1;
    }
    return matches;
  }

  /// Standard Levenshtein distance between [a] and [b].
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final dp = List<List<int>>.generate(
      a.length + 1,
      (i) => List<int>.generate(b.length + 1, (j) => 0),
    );
    for (var i = 0; i <= a.length; i++) dp[i][0] = i;
    for (var j = 0; j <= b.length; j++) dp[0][j] = j;

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[a.length][b.length];
  }
}

/// Builds a short preview snippet of [text] centred on the first [SearchMatch].
String buildPreviewSnippet(String text, List<SearchMatch> matches,
    {int windowChars = 80}) {
  if (matches.isEmpty) return text.length > windowChars ? '${text.substring(0, windowChars)}…' : text;

  final match = matches.first;
  final start = (match.offset - windowChars ~/ 2).clamp(0, text.length);
  final end = (match.offset + match.length + windowChars ~/ 2).clamp(0, text.length);
  final snippet = text.substring(start, end);
  return (start > 0 ? '…' : '') + snippet + (end < text.length ? '…' : '');
}
