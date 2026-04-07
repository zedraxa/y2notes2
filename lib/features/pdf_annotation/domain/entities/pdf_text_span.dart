import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents a single span of selectable text extracted from a
/// PDF page's text layer.
///
/// A list of [PdfTextSpan]s for a page is used by the text-selection
/// overlay to allow the user to select, copy, highlight, underline
/// or strikethrough text.
class PdfTextSpan extends Equatable {
  const PdfTextSpan({
    required this.text,
    required this.rect,
    required this.pageIndex,
    this.lineIndex = 0,
    this.wordIndex = 0,
    this.fontSize = 12.0,
    this.fontName,
  });

  /// The text content of this span.
  final String text;

  /// Bounding rectangle in page coordinates (origin top-left).
  final Rect rect;

  /// Zero-based page index.
  final int pageIndex;

  /// Zero-based line index within the page.
  final int lineIndex;

  /// Zero-based word index within the line.
  final int wordIndex;

  /// Approximate font size used in the PDF.
  final double fontSize;

  /// Font family name if available from the PDF.
  final String? fontName;

  @override
  List<Object?> get props => [
        text,
        rect,
        pageIndex,
        lineIndex,
        wordIndex,
        fontSize,
        fontName,
      ];
}
