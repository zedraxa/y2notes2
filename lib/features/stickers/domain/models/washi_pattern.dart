import 'package:flutter/material.dart';

enum WashiPatternType { solid, striped, dotted }

class WashiPattern {
  const WashiPattern({
    required this.id,
    required this.name,
    required this.patternType,
    required this.color,
    this.secondaryColor,
    this.opacity = 0.6,
  });

  final String id;
  final String name;
  final WashiPatternType patternType;
  final Color color;
  final Color? secondaryColor;
  final double opacity;
}
