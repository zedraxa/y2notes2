import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/templates/data/builtin_templates.dart';
import 'package:y2notes2/features/templates/domain/entities/page_template.dart';

/// Applies [NoteTemplate]s to canvas pages.
class TemplateEngine {
  /// Returns a [CanvasConfig] configured for the given template.
  CanvasConfig configForTemplate(NoteTemplate template) =>
      template.defaultConfig.copyWith(template: template.background);

  /// Looks up a built-in or custom template by [id].
  NoteTemplate? findById(String id, {List<NoteTemplate> custom = const []}) {
    for (final t in BuiltinTemplates.all) {
      if (t.id == id) return t;
    }
    for (final t in custom) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Returns all templates for [category], or all if category is null/'All'.
  List<NoteTemplate> templatesByCategory(
    String? category, {
    List<NoteTemplate> custom = const [],
  }) {
    final all = [...BuiltinTemplates.all, ...custom];
    if (category == null || category == 'All') return all;
    if (category == 'Custom') return custom;
    return all.where((t) => t.category == category).toList();
  }

  /// Searches templates by [query] across name and description.
  List<NoteTemplate> search(
    String query, {
    List<NoteTemplate> custom = const [],
  }) {
    final q = query.toLowerCase();
    final all = [...BuiltinTemplates.all, ...custom];
    return all
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q))
        .toList();
  }
}
