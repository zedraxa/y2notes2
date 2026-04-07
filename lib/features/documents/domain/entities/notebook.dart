import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/features/documents/domain/entities/notebook_page.dart';

/// Cover style for a notebook.
enum NotebookCover {
  blue,
  red,
  green,
  purple,
  yellow,
  black,
  white,
}

/// A multi-page notebook that groups [NotebookPage]s together.
class Notebook extends Equatable {
  Notebook({
    String? id,
    required this.title,
    this.pages = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.cover = NotebookCover.blue,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final List<NotebookPage> pages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NotebookCover cover;

  int get pageCount => pages.length;

  bool get isEmpty => pages.isEmpty;

  Notebook copyWith({
    String? title,
    List<NotebookPage>? pages,
    DateTime? updatedAt,
    NotebookCover? cover,
  }) =>
      Notebook(
        id: id,
        title: title ?? this.title,
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
  List<Object?> get props => [id, title, pages, createdAt, cover];
}
