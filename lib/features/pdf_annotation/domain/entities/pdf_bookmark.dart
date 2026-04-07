import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A user-created bookmark for a specific page in the PDF document.
///
/// This is separate from the notebook-level page bookmarks so that
/// PDF-specific bookmarks remain tied to the original PDF page index
/// and can carry a label and optional note.
class PdfBookmark extends Equatable {
  PdfBookmark({
    String? id,
    required this.pageIndex,
    this.label,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Unique identifier.
  final String id;

  /// Zero-based page index in the PDF.
  final int pageIndex;

  /// User-visible label (e.g. "Chapter 3").
  final String? label;

  /// Optional longer note associated with the bookmark.
  final String? note;

  /// When the bookmark was created.
  final DateTime createdAt;

  /// Display text: the user label, or a fallback "Page N".
  String get displayLabel => label ?? 'Page ${pageIndex + 1}';

  PdfBookmark copyWith({
    int? pageIndex,
    String? label,
    bool clearLabel = false,
    String? note,
    bool clearNote = false,
  }) =>
      PdfBookmark(
        id: id,
        pageIndex: pageIndex ?? this.pageIndex,
        label: clearLabel ? null : (label ?? this.label),
        note: clearNote ? null : (note ?? this.note),
        createdAt: createdAt,
      );

  /// Serialise to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'pageIndex': pageIndex,
        if (label != null) 'label': label,
        if (note != null) 'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserialise from a JSON-compatible map.
  factory PdfBookmark.fromJson(Map<String, dynamic> json) =>
      PdfBookmark(
        id: json['id'] as String,
        pageIndex: json['pageIndex'] as int,
        label: json['label'] as String?,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [id, pageIndex, label, note, createdAt];
}
