import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';

/// Result of a single page import (PDF page or standalone image).
class ImportedPage extends Equatable {
  const ImportedPage({
    required this.pageNumber,
    required this.width,
    required this.height,
    required this.renderedImage,
    this.sourcePath,
  });

  final int pageNumber;
  final double width;
  final double height;

  /// Rasterised version of the page ready to use as a canvas background.
  final ui.Image renderedImage;

  /// Path to the source file this page was imported from.
  final String? sourcePath;

  double get aspectRatio => width / height;

  @override
  List<Object?> get props => [pageNumber, width, height, sourcePath];
}

/// Overall result of an import operation.
class ImportResult extends Equatable {
  const ImportResult({
    required this.pages,
    required this.sourcePath,
    required this.importedAt,
    this.title,
  });

  final List<ImportedPage> pages;
  final String sourcePath;
  final DateTime importedAt;

  /// Suggested notebook title derived from the file name.
  final String? title;

  int get pageCount => pages.length;

  bool get hasPages => pages.isNotEmpty;

  @override
  List<Object?> get props => [pages, sourcePath, importedAt, title];
}
