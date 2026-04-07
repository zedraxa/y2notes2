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

  /// Serialise to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'text': text,
        'rect': {
          'left': rect.left,
          'top': rect.top,
          'right': rect.right,
          'bottom': rect.bottom,
        },
        'pageIndex': pageIndex,
        'lineIndex': lineIndex,
        'wordIndex': wordIndex,
        'fontSize': fontSize,
        if (fontName != null) 'fontName': fontName,
      };

  /// Deserialise from a JSON-compatible map.
  factory PdfTextSpan.fromJson(Map<String, dynamic> json) {
    final r = json['rect'] as Map<String, dynamic>;
    return PdfTextSpan(
      text: json['text'] as String,
      rect: Rect.fromLTRB(
        (r['left'] as num).toDouble(),
        (r['top'] as num).toDouble(),
        (r['right'] as num).toDouble(),
        (r['bottom'] as num).toDouble(),
      ),
      pageIndex: json['pageIndex'] as int,
      lineIndex: json['lineIndex'] as int? ?? 0,
      wordIndex: json['wordIndex'] as int? ?? 0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 12.0,
      fontName: json['fontName'] as String?,
    );
  }

  /// Merge the bounding rectangles of multiple spans into one.
  static Rect mergeRects(List<PdfTextSpan> spans) {
    if (spans.isEmpty) return Rect.zero;
    Rect r = spans.first.rect;
    for (int i = 1; i < spans.length; i++) {
      r = r.expandToInclude(spans[i].rect);
    }
    return r;
  }

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
