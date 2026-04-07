import 'package:equatable/equatable.dart';

class RecognitionOptions extends Equatable {
  const RecognitionOptions({
    this.languageCode = 'en-US',
    this.minimumConfidence = 0.3,
    this.maxCandidates = 5,
    this.useDictionary = true,
    this.contextualPrediction = true,
    this.mathDetection = true,
    this.autoSegmentation = true,
  });

  final String languageCode;
  final double minimumConfidence;
  final int maxCandidates;
  final bool useDictionary;
  final bool contextualPrediction;
  final bool mathDetection;
  final bool autoSegmentation;

  RecognitionOptions copyWith({
    String? languageCode,
    double? minimumConfidence,
    int? maxCandidates,
    bool? useDictionary,
    bool? contextualPrediction,
    bool? mathDetection,
    bool? autoSegmentation,
  }) =>
      RecognitionOptions(
        languageCode: languageCode ?? this.languageCode,
        minimumConfidence: minimumConfidence ?? this.minimumConfidence,
        maxCandidates: maxCandidates ?? this.maxCandidates,
        useDictionary: useDictionary ?? this.useDictionary,
        contextualPrediction: contextualPrediction ?? this.contextualPrediction,
        mathDetection: mathDetection ?? this.mathDetection,
        autoSegmentation: autoSegmentation ?? this.autoSegmentation,
      );

  @override
  List<Object?> get props => [
        languageCode,
        minimumConfidence,
        maxCandidates,
        useDictionary,
        contextualPrediction,
        mathDetection,
        autoSegmentation,
      ];
}
