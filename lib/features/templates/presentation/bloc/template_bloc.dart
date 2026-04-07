import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/templates/data/builtin_templates.dart';
import 'package:y2notes2/features/templates/data/template_repository.dart';
import 'package:y2notes2/features/templates/presentation/bloc/template_event.dart';
import 'package:y2notes2/features/templates/presentation/bloc/template_state.dart';

class TemplateBloc extends Bloc<TemplateEvent, TemplateState> {
  TemplateBloc({required TemplateRepository repository})
      : _repository = repository,
        super(const TemplateState()) {
    on<TemplatesLoaded>(_onLoaded);
    on<TemplateSelected>(_onSelected);
    on<TemplateApplied>(_onApplied);
    on<TemplateCategoryChanged>(_onCategoryChanged);
    on<TemplateSearchQueryChanged>(_onSearchQueryChanged);
    on<CustomTemplateSaved>(_onCustomSaved);
    on<CustomTemplateDeleted>(_onCustomDeleted);
  }

  final TemplateRepository _repository;

  Future<void> _onLoaded(
      TemplatesLoaded event, Emitter<TemplateState> emit) async {
    emit(state.copyWith(isLoading: true));
    final custom = await _repository.loadCustomTemplates();
    final recentIds = await _repository.loadRecentlyUsedIds();
    emit(state.copyWith(
      builtinTemplates: BuiltinTemplates.all,
      customTemplates: custom,
      recentlyUsedIds: recentIds,
      isLoading: false,
    ));
  }

  void _onSelected(TemplateSelected event, Emitter<TemplateState> emit) {
    emit(state.copyWith(selectedTemplateId: event.templateId));
  }

  Future<void> _onApplied(
      TemplateApplied event, Emitter<TemplateState> emit) async {
    await _repository.recordTemplateUsage(event.templateId);
    final recentIds = await _repository.loadRecentlyUsedIds();
    emit(state.copyWith(
      appliedTemplateId: event.templateId,
      recentlyUsedIds: recentIds,
    ));
  }

  void _onCategoryChanged(
      TemplateCategoryChanged event, Emitter<TemplateState> emit) {
    emit(state.copyWith(activeCategory: event.category));
  }

  void _onSearchQueryChanged(
      TemplateSearchQueryChanged event, Emitter<TemplateState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onCustomSaved(
      CustomTemplateSaved event, Emitter<TemplateState> emit) async {
    await _repository.saveCustomTemplate(event.template);
    final custom = await _repository.loadCustomTemplates();
    emit(state.copyWith(customTemplates: custom));
  }

  Future<void> _onCustomDeleted(
      CustomTemplateDeleted event, Emitter<TemplateState> emit) async {
    await _repository.deleteCustomTemplate(event.id);
    final custom = await _repository.loadCustomTemplates();
    emit(state.copyWith(customTemplates: custom));
  }
}
