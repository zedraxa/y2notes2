import 'package:equatable/equatable.dart';
import 'package:biscuitse/features/templates/domain/entities/page_template.dart';

abstract class TemplateEvent extends Equatable {
  const TemplateEvent();
}

class TemplatesLoaded extends TemplateEvent {
  const TemplatesLoaded();
  @override
  List<Object?> get props => [];
}

class TemplateSelected extends TemplateEvent {
  const TemplateSelected(this.templateId);
  final String templateId;
  @override
  List<Object?> get props => [templateId];
}

class TemplateApplied extends TemplateEvent {
  const TemplateApplied(this.templateId);
  final String templateId;
  @override
  List<Object?> get props => [templateId];
}

class TemplateCategoryChanged extends TemplateEvent {
  const TemplateCategoryChanged(this.category);
  final String category;
  @override
  List<Object?> get props => [category];
}

class TemplateSearchQueryChanged extends TemplateEvent {
  const TemplateSearchQueryChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class CustomTemplateSaved extends TemplateEvent {
  const CustomTemplateSaved(this.template);
  final NoteTemplate template;
  @override
  List<Object?> get props => [template];
}

class CustomTemplateDeleted extends TemplateEvent {
  const CustomTemplateDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
