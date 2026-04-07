import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/templates/domain/entities/template_region.dart';

/// A pre-configured page layout with placeholder regions.
class NoteTemplate extends Equatable {
  NoteTemplate({
    String? id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconEmoji,
    required this.accentColor,
    required this.background,
    this.regions = const [],
    this.defaultConfig = const CanvasConfig(),
    this.isCustom = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String description;
  final String category; // Study, Planning, Creative, Productivity, Special
  final String iconEmoji;
  final Color accentColor;
  final PageTemplate background;
  final List<TemplateRegion> regions;
  final CanvasConfig defaultConfig;
  final bool isCustom;
  final DateTime createdAt;

  NoteTemplate copyWith({
    String? name,
    String? description,
    String? category,
    String? iconEmoji,
    Color? accentColor,
    PageTemplate? background,
    List<TemplateRegion>? regions,
    CanvasConfig? defaultConfig,
    bool? isCustom,
  }) =>
      NoteTemplate(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        iconEmoji: iconEmoji ?? this.iconEmoji,
        accentColor: accentColor ?? this.accentColor,
        background: background ?? this.background,
        regions: regions ?? this.regions,
        defaultConfig: defaultConfig ?? this.defaultConfig,
        isCustom: isCustom ?? this.isCustom,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        iconEmoji,
        accentColor,
        background,
        regions,
        defaultConfig,
        isCustom,
        createdAt,
      ];
}
