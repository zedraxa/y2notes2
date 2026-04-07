import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Type of content expected in a template region.
enum RegionType { text, drawing, image, widget }

/// A labelled rectangular area within a [PageTemplate].
class TemplateRegion extends Equatable {
  const TemplateRegion({
    required this.label,
    required this.bounds,
    required this.type,
    this.backgroundColor,
    this.defaultTextStyle,
  });

  final String label;
  final Rect bounds;
  final RegionType type;
  final Color? backgroundColor;
  final TextStyle? defaultTextStyle;

  @override
  List<Object?> get props =>
      [label, bounds, type, backgroundColor, defaultTextStyle];
}
