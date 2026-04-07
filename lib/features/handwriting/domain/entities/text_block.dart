import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class TextBlock extends Equatable {
  TextBlock({
    String? id,
    required this.text,
    required this.position,
    this.width = 200.0,
    this.style = const TextStyle(fontSize: 16, color: Colors.black),
    this.align = TextAlign.left,
    this.backgroundColor = Colors.transparent,
    this.opacity = 1.0,
    this.rotation = 0.0,
    this.isEditable = false,
    this.sourceRecognitionId,
    this.originalStrokeIds = const [],
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String text;
  final Offset position;
  final double width;
  final TextStyle style;
  final TextAlign align;
  final Color backgroundColor;
  final double opacity;
  final double rotation;
  final bool isEditable;
  final String? sourceRecognitionId;
  final List<String> originalStrokeIds;

  TextBlock copyWith({
    String? text,
    Offset? position,
    double? width,
    TextStyle? style,
    TextAlign? align,
    Color? backgroundColor,
    double? opacity,
    double? rotation,
    bool? isEditable,
    String? sourceRecognitionId,
    List<String>? originalStrokeIds,
  }) =>
      TextBlock(
        id: id,
        text: text ?? this.text,
        position: position ?? this.position,
        width: width ?? this.width,
        style: style ?? this.style,
        align: align ?? this.align,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        opacity: opacity ?? this.opacity,
        rotation: rotation ?? this.rotation,
        isEditable: isEditable ?? this.isEditable,
        sourceRecognitionId: sourceRecognitionId ?? this.sourceRecognitionId,
        originalStrokeIds: originalStrokeIds ?? this.originalStrokeIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': position.dx,
        'y': position.dy,
        'width': width,
        'fontSize': style.fontSize ?? 16.0,
        'color': (style.color ?? Colors.black).value,
        'align': align.index,
        'opacity': opacity,
        'rotation': rotation,
        'originalStrokeIds': originalStrokeIds,
        if (sourceRecognitionId != null) 'sourceRecognitionId': sourceRecognitionId,
      };

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
        id: json['id'] as String,
        text: json['text'] as String,
        position: Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble()),
        width: (json['width'] as num).toDouble(),
        style: TextStyle(
          fontSize: (json['fontSize'] as num).toDouble(),
          color: Color(json['color'] as int),
        ),
        align: TextAlign.values[json['align'] as int],
        opacity: (json['opacity'] as num).toDouble(),
        rotation: (json['rotation'] as num).toDouble(),
        originalStrokeIds: (json['originalStrokeIds'] as List<dynamic>).cast<String>(),
        sourceRecognitionId: json['sourceRecognitionId'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        text,
        position,
        width,
        style,
        align,
        backgroundColor,
        opacity,
        rotation,
        isEditable,
        sourceRecognitionId,
        originalStrokeIds,
      ];
}
