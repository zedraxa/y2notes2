import 'package:biscuitse/features/handwriting/domain/entities/recognition_result.dart';
import 'package:biscuitse/features/handwriting/engine/recognition_engine.dart';
import 'package:biscuitse/features/handwriting/engine/backends/heuristic_recognizer.dart';

/// Adapter for Google ML Kit Digital Ink Recognition.
///
/// Falls back to [HeuristicRecognizer] when ML Kit is not available.
/// To enable ML Kit, add `google_mlkit_digital_ink_recognition` to
/// pubspec.yaml and uncomment the relevant code.
class MlKitInkRecognizer implements RecognitionBackend {
  MlKitInkRecognizer() : _fallback = HeuristicRecognizer();

  final HeuristicRecognizer _fallback;

  @override
  String get id => 'mlkit_ink';

  @override
  String get name => 'ML Kit Digital Ink';

  @override
  bool get isAvailable => false; // Set to true when ML Kit is linked

  @override
  Future<bool> supportsLanguage(String languageCode) async => false;

  @override
  Future<void> downloadModel(String languageCode) async {
    // ML Kit model download would go here
  }

  @override
  Future<RecognitionResult> recognize(
    List<RecognitionStroke> strokes, {
    String? languageHint,
    RecognitionContext? context,
  }) async {
    // ML Kit not available — fall back to heuristic
    return _fallback.recognize(strokes, languageHint: languageHint, context: context);
  }

  @override
  Future<void> dispose() async {}
}
