import 'package:biscuitse/features/handwriting/domain/entities/recognition_result.dart';
import 'package:biscuitse/features/handwriting/engine/recognition_engine.dart';

/// Adapter for Google ML Kit Text Recognition (image-based OCR).
///
/// Falls back gracefully when ML Kit is not available.
/// To enable ML Kit, add `google_mlkit_text_recognition` to pubspec.yaml
/// and uncomment the relevant code.
class MlKitTextRecognizer implements RecognitionBackend {
  @override
  String get id => 'mlkit_ocr';

  @override
  String get name => 'ML Kit OCR';

  @override
  bool get isAvailable => false;

  @override
  Future<bool> supportsLanguage(String languageCode) async => false;

  @override
  Future<void> downloadModel(String languageCode) async {}

  @override
  Future<RecognitionResult> recognize(
    List<RecognitionStroke> strokes, {
    String? languageHint,
    RecognitionContext? context,
  }) async =>
      RecognitionResult.empty;

  @override
  Future<void> dispose() async {}
}
