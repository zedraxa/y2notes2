import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// The type of annotation placed on a PDF page.
enum PdfAnnotationType {
  /// Text highlight with a translucent colour overlay.
  highlight,

  /// Underline beneath selected text.
  underline,

  /// Strikethrough line across selected text.
  strikethrough,

  /// Floating sticky-note comment anchored to a position.
  stickyNote,

  /// A freeform text note placed at a position.
  textNote,

  /// A user-entered value in a PDF form field.
  formField,
}

/// Represents a single annotation on a specific PDF page.
class PdfAnnotation extends Equatable {
  PdfAnnotation({
    String? id,
    required this.pageIndex,
    required this.type,
    required this.rect,
    this.color = const Color(0x80FFEB3B),
    this.content,
    this.selectedText,
    this.formFieldName,
    this.formFieldValue,
    this.opacity = 1.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier.
  final String id;

  /// Zero-based page index within the PDF document.
  final int pageIndex;

  /// Kind of annotation.
  final PdfAnnotationType type;

  /// Bounding rectangle in page coordinates (origin top-left).
  /// For text-markup annotations this spans the selected text.
  /// For sticky notes this is the anchor position and icon size.
  final Rect rect;

  /// Annotation colour (fill / underline / strikethrough).
  final Color color;

  /// Free-text content (sticky-note body, text-note body).
  final String? content;

  /// The original text that was selected for highlight / underline /
  /// strikethrough annotations.
  final String? selectedText;

  /// The PDF form field name (for [PdfAnnotationType.formField]).
  final String? formFieldName;

  /// The value entered in the PDF form field.
  final String? formFieldValue;

  /// Annotation opacity (0.0–1.0).
  final double opacity;

  /// When the annotation was first created.
  final DateTime createdAt;

  /// When the annotation was last modified.
  final DateTime updatedAt;

  PdfAnnotation copyWith({
    int? pageIndex,
    PdfAnnotationType? type,
    Rect? rect,
    Color? color,
    String? content,
    bool clearContent = false,
    String? selectedText,
    String? formFieldName,
    String? formFieldValue,
    double? opacity,
    DateTime? updatedAt,
  }) =>
      PdfAnnotation(
        id: id,
        pageIndex: pageIndex ?? this.pageIndex,
        type: type ?? this.type,
        rect: rect ?? this.rect,
        color: color ?? this.color,
        content: clearContent ? null : (content ?? this.content),
        selectedText: selectedText ?? this.selectedText,
        formFieldName: formFieldName ?? this.formFieldName,
        formFieldValue: formFieldValue ?? this.formFieldValue,
        opacity: opacity ?? this.opacity,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  /// Serialise to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'pageIndex': pageIndex,
        'type': type.name,
        'rect': {
          'left': rect.left,
          'top': rect.top,
          'right': rect.right,
          'bottom': rect.bottom,
        },
        'color': color.value,
        if (content != null) 'content': content,
        if (selectedText != null) 'selectedText': selectedText,
        if (formFieldName != null) 'formFieldName': formFieldName,
        if (formFieldValue != null)
          'formFieldValue': formFieldValue,
        'opacity': opacity,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserialise from a JSON-compatible map.
  factory PdfAnnotation.fromJson(Map<String, dynamic> json) {
    final r = json['rect'] as Map<String, dynamic>;
    return PdfAnnotation(
      id: json['id'] as String,
      pageIndex: json['pageIndex'] as int,
      type: PdfAnnotationType.values.byName(
        json['type'] as String,
      ),
      rect: Rect.fromLTRB(
        (r['left'] as num).toDouble(),
        (r['top'] as num).toDouble(),
        (r['right'] as num).toDouble(),
        (r['bottom'] as num).toDouble(),
      ),
      color: Color(json['color'] as int),
      content: json['content'] as String?,
      selectedText: json['selectedText'] as String?,
      formFieldName: json['formFieldName'] as String?,
      formFieldValue: json['formFieldValue'] as String?,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        pageIndex,
        type,
        rect,
        color,
        content,
        selectedText,
        formFieldName,
        formFieldValue,
        opacity,
        createdAt,
        updatedAt,
      ];
}
