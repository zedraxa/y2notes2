import 'package:equatable/equatable.dart';
import 'package:biscuits/features/templates/domain/entities/page_template.dart';

class TemplateState extends Equatable {
  const TemplateState({
    this.builtinTemplates = const [],
    this.customTemplates = const [],
    this.recentlyUsedIds = const [],
    this.selectedTemplateId,
    this.appliedTemplateId,
    this.activeCategory = 'All',
    this.searchQuery = '',
    this.isLoading = false,
  });

  final List<NoteTemplate> builtinTemplates;
  final List<NoteTemplate> customTemplates;
  final List<String> recentlyUsedIds;
  final String? selectedTemplateId;
  final String? appliedTemplateId;
  final String activeCategory;
  final String searchQuery;
  final bool isLoading;

  List<NoteTemplate> get allTemplates =>
      [...builtinTemplates, ...customTemplates];

  List<NoteTemplate> get filteredTemplates {
    var list = allTemplates;
    if (activeCategory != 'All') {
      if (activeCategory == 'Custom') {
        list = customTemplates;
      } else {
        list = list.where((t) => t.category == activeCategory).toList();
      }
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<NoteTemplate> get recentlyUsedTemplates {
    final all = allTemplates;
    return recentlyUsedIds
        .map((id) {
          try {
            return all.firstWhere((t) => t.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<NoteTemplate>()
        .toList();
  }

  NoteTemplate? get selectedTemplate {
    if (selectedTemplateId == null) return null;
    try {
      return allTemplates.firstWhere((t) => t.id == selectedTemplateId);
    } catch (_) {
      return null;
    }
  }

  TemplateState copyWith({
    List<NoteTemplate>? builtinTemplates,
    List<NoteTemplate>? customTemplates,
    List<String>? recentlyUsedIds,
    Object? selectedTemplateId = _sentinel,
    Object? appliedTemplateId = _sentinel,
    String? activeCategory,
    String? searchQuery,
    bool? isLoading,
  }) =>
      TemplateState(
        builtinTemplates: builtinTemplates ?? this.builtinTemplates,
        customTemplates: customTemplates ?? this.customTemplates,
        recentlyUsedIds: recentlyUsedIds ?? this.recentlyUsedIds,
        selectedTemplateId: selectedTemplateId == _sentinel
            ? this.selectedTemplateId
            : selectedTemplateId as String?,
        appliedTemplateId: appliedTemplateId == _sentinel
            ? this.appliedTemplateId
            : appliedTemplateId as String?,
        activeCategory: activeCategory ?? this.activeCategory,
        searchQuery: searchQuery ?? this.searchQuery,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [
        builtinTemplates,
        customTemplates,
        recentlyUsedIds,
        selectedTemplateId,
        appliedTemplateId,
        activeCategory,
        searchQuery,
        isLoading,
      ];
}

const _sentinel = Object();
