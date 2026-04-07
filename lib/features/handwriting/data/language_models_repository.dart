import 'package:y2notes2/features/handwriting/domain/models/language_model.dart';

/// Manages available language models.
class LanguageModelsRepository {
  LanguageModelsRepository._();
  static final instance = LanguageModelsRepository._();

  /// All language models known to the app.
  /// The heuristic backend only supports English; ML Kit adds many more.
  static const List<LanguageModel> builtInModels = [
    LanguageModel(
      code: 'en-US',
      name: 'English (US)',
      nativeName: 'English',
      status: LanguageModelStatus.available,
    ),
    LanguageModel(
      code: 'en-GB',
      name: 'English (UK)',
      nativeName: 'English',
      status: LanguageModelStatus.available,
    ),
    LanguageModel(
      code: 'es-ES',
      name: 'Spanish',
      nativeName: 'Español',
      status: LanguageModelStatus.notDownloaded,
      sizeBytes: 5 * 1024 * 1024,
    ),
    LanguageModel(
      code: 'fr-FR',
      name: 'French',
      nativeName: 'Français',
      status: LanguageModelStatus.notDownloaded,
      sizeBytes: 5 * 1024 * 1024,
    ),
    LanguageModel(
      code: 'de-DE',
      name: 'German',
      nativeName: 'Deutsch',
      status: LanguageModelStatus.notDownloaded,
      sizeBytes: 5 * 1024 * 1024,
    ),
    LanguageModel(
      code: 'zh-CN',
      name: 'Chinese (Simplified)',
      nativeName: '中文',
      status: LanguageModelStatus.notDownloaded,
      sizeBytes: 15 * 1024 * 1024,
    ),
    LanguageModel(
      code: 'ja-JP',
      name: 'Japanese',
      nativeName: '日本語',
      status: LanguageModelStatus.notDownloaded,
      sizeBytes: 12 * 1024 * 1024,
    ),
    LanguageModel(
      code: 'ar-SA',
      name: 'Arabic',
      nativeName: 'العربية',
      status: LanguageModelStatus.notDownloaded,
      sizeBytes: 8 * 1024 * 1024,
    ),
    LanguageModel(
      code: 'pt-BR',
      name: 'Portuguese (Brazil)',
      nativeName: 'Português',
      status: LanguageModelStatus.notDownloaded,
      sizeBytes: 5 * 1024 * 1024,
    ),
    LanguageModel(
      code: 'ko-KR',
      name: 'Korean',
      nativeName: '한국어',
      status: LanguageModelStatus.notDownloaded,
      sizeBytes: 10 * 1024 * 1024,
    ),
  ];

  final _models = <String, LanguageModel>{
    for (final m in builtInModels) m.code: m,
  };

  List<LanguageModel> get all => _models.values.toList();

  LanguageModel? get(String code) => _models[code];

  void updateModel(LanguageModel model) {
    _models[model.code] = model;
  }
}
