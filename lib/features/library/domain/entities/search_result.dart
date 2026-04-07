import 'package:equatable/equatable.dart';
import 'package:y2notes2/features/library/domain/entities/library_item.dart';

/// A single location within [item] where the search query matched.
class SearchMatch extends Equatable {
  const SearchMatch({
    required this.field,
    required this.offset,
    required this.length,
  });

  /// The logical field name where the match was found (e.g. 'title', 'content').
  final String field;

  /// Character offset of the match start within the field text.
  final int offset;

  /// Length of the matched substring.
  final int length;

  @override
  List<Object?> get props => [field, offset, length];
}

/// One result returned by [SearchEngine.search].
class SearchResult extends Equatable {
  const SearchResult({
    required this.item,
    required this.relevanceScore,
    this.matches = const [],
    this.previewSnippet = '',
  });

  final LibraryItem item;

  /// Normalised relevance score in [0.0, 1.0]; higher = more relevant.
  final double relevanceScore;

  /// All positions where the query matched within the item's content.
  final List<SearchMatch> matches;

  /// A short text excerpt surrounding the first match (for display).
  final String previewSnippet;

  @override
  List<Object?> get props =>
      [item, relevanceScore, matches, previewSnippet];
}
