import 'package:flutter/material.dart';
import 'package:biscuitse/features/handwriting/domain/entities/recognition_result.dart';
import 'package:biscuitse/features/handwriting/domain/models/search_match.dart';

/// Represents a page's recognized text alongside its stroke metadata.
class RecognizedPage {
  const RecognizedPage({
    required this.pageId,
    required this.text,
    required this.strokes,
    required this.strokeBounds,
  });

  final String pageId;
  final String text;
  final List<RecognitionStroke> strokes;
  final List<Rect> strokeBounds; // parallel to strokes
}

/// Searches recognized handwriting text across all pages.
class HandwritingSearch {
  final _pages = <String, RecognizedPage>{};

  /// Register or update recognized text for a page.
  void indexPage(RecognizedPage page) {
    _pages[page.pageId] = page;
  }

  /// Remove a page from the search index.
  void removePage(String pageId) {
    _pages.remove(pageId);
  }

  /// Search for [query] across all indexed pages.
  /// Returns matches sorted by relevance.
  List<SearchMatch> search(String query) {
    if (query.trim().isEmpty) return const [];

    final lower = query.toLowerCase();
    final matches = <SearchMatch>[];

    for (final page in _pages.values) {
      final text = page.text.toLowerCase();
      var start = 0;
      while (true) {
        final idx = text.indexOf(lower, start);
        if (idx < 0) break;

        final matchText = page.text.substring(idx, idx + query.length);
        final snippet = _snippet(page.text, idx, query.length);

        // Approximate bounding box from stroke bounds
        final bounds = _approximateBounds(page, idx, query.length);

        matches.add(SearchMatch(
          query: query,
          matchedText: matchText,
          pageId: page.pageId,
          // Stroke-level highlighting requires aligning the character
          // segmentation output with stroke IDs during indexPage(). This
          // per-character stroke index is tracked in [RecognizedPage.strokeBounds]
          // and will be wired up once the RecognitionManager exposes it.
          strokeIds: _strokeIdsForRange(page, idx, idx + query.length),
          boundingBox: bounds,
          contextSnippet: snippet,
        ));

        start = idx + 1;
      }
    }

    return matches;
  }

  String _snippet(String text, int matchStart, int matchLen) {
    const radius = 30;
    final start = (matchStart - radius).clamp(0, text.length);
    final end = (matchStart + matchLen + radius).clamp(0, text.length);
    final snippet = text.substring(start, end);
    return (start > 0 ? '…' : '') + snippet + (end < text.length ? '…' : '');
  }

  Rect _approximateBounds(RecognizedPage page, int charIndex, int charLen) {
    // Simple approximation: divide text length evenly across all stroke bounds
    if (page.strokeBounds.isEmpty) return Rect.zero;
    final totalChars = page.text.length;
    if (totalChars == 0) return Rect.zero;

    final startFrac = charIndex / totalChars;
    final endFrac = (charIndex + charLen) / totalChars;
    final n = page.strokeBounds.length;

    final startIdx = (startFrac * n).floor().clamp(0, n - 1);
    final endIdx = (endFrac * n).ceil().clamp(0, n - 1);

    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (var i = startIdx; i <= endIdx; i++) {
      final b = page.strokeBounds[i];
      if (b.left < minX) minX = b.left;
      if (b.top < minY) minY = b.top;
      if (b.right > maxX) maxX = b.right;
      if (b.bottom > maxY) maxY = b.bottom;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Returns stroke IDs that correspond to the character range [start, end)
  /// in [page.text]. Uses the [RecognizedPage.strokes] alignment where
  /// strokes are assumed evenly distributed across the text.
  List<String> _strokeIdsForRange(
    RecognizedPage page,
    int start,
    int end,
  ) {
    if (page.strokes.isEmpty || page.text.isEmpty) return const [];
    final totalChars = page.text.length;
    final n = page.strokes.length;

    final startIdx = ((start / totalChars) * n).floor().clamp(0, n - 1);
    final endIdx = ((end / totalChars) * n).ceil().clamp(0, n - 1);

    return page.strokes
        .sublist(startIdx, endIdx + 1)
        .map((s) => s.strokeId.toString())
        .toList();
  }
}
