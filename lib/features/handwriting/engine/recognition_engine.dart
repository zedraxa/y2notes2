import 'package:biscuitse/features/handwriting/domain/entities/recognition_result.dart';

/// Abstract recognition backend — allows swapping implementations.
abstract class RecognitionBackend {
  String get id;
  String get name;
  bool get isAvailable;

  Future<RecognitionResult> recognize(
    List<RecognitionStroke> strokes, {
    String? languageHint,
    RecognitionContext? context,
  });

  Future<bool> supportsLanguage(String languageCode);
  Future<void> downloadModel(String languageCode);
  Future<void> dispose();
}

enum RecognitionMode { off, manual, realTime, autoConvert }
