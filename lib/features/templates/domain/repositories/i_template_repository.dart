import 'package:biscuits/core/utils/result.dart';
import 'package:biscuits/features/templates/domain/entities/page_template.dart';

/// Contract for page-template persistence.
abstract class ITemplateRepository {
  /// Loads all saved custom templates.
  Future<Result<List<NoteTemplate>>> loadCustomTemplates();

  /// Persists a single custom template.
  Future<Result<void>> saveCustomTemplate(NoteTemplate template);

  /// Deletes a custom template by [id].
  Future<Result<void>> deleteCustomTemplate(String id);

  /// Loads the list of recently used template IDs.
  Future<Result<List<String>>> loadRecentlyUsedIds();

  /// Records that a template was used.
  Future<Result<void>> recordTemplateUsage(String templateId);
}
