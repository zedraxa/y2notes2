import 'package:equatable/equatable.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/handwriting/domain/entities/text_block.dart';
import 'package:y2notes2/features/handwriting/engine/recognition_engine.dart';

abstract class HandwritingEvent extends Equatable {
  const HandwritingEvent();
  @override
  List<Object?> get props => [];
}

/// User tapped "Recognize" button — recognize selected or all strokes.
class RecognitionRequested extends HandwritingEvent {
  const RecognitionRequested({
    this.strokeIds = const [],
    this.strokes = const [],
  });
  final List<String> strokeIds; // empty = recognize all
  final List<Stroke> strokes;   // strokes to recognize (passed by caller)
  @override
  List<Object?> get props => [strokeIds, strokes];
}

/// Toggle real-time recognition on/off.
class RealTimeRecognitionToggled extends HandwritingEvent {
  const RealTimeRecognitionToggled({required this.enabled});
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

/// User accepted a candidate from the overlay.
class CandidateAccepted extends HandwritingEvent {
  const CandidateAccepted({required this.candidateIndex});
  final int candidateIndex;
  @override
  List<Object?> get props => [candidateIndex];
}

/// User rejected / dismissed the recognition overlay.
class CandidateRejected extends HandwritingEvent {
  const CandidateRejected();
}

/// A new TextBlock was placed on the canvas.
class TextBlockCreated extends HandwritingEvent {
  const TextBlockCreated(this.textBlock);
  final TextBlock textBlock;
  @override
  List<Object?> get props => [textBlock];
}

/// User edited the text of a TextBlock.
class TextBlockEdited extends HandwritingEvent {
  const TextBlockEdited({required this.id, required this.newText});
  final String id;
  final String newText;
  @override
  List<Object?> get props => [id, newText];
}

/// User deleted a TextBlock.
class TextBlockDeleted extends HandwritingEvent {
  const TextBlockDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

/// User wants to revert a TextBlock back to handwriting strokes.
class RevertToHandwriting extends HandwritingEvent {
  const RevertToHandwriting(this.textBlockId);
  final String textBlockId;
  @override
  List<Object?> get props => [textBlockId];
}

/// Active recognition language changed.
class LanguageChanged extends HandwritingEvent {
  const LanguageChanged(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

/// Recognition mode changed.
class RecognitionModeChanged extends HandwritingEvent {
  const RecognitionModeChanged(this.mode);
  final RecognitionMode mode;
  @override
  List<Object?> get props => [mode];
}

/// Search query changed.
class SearchQueryChanged extends HandwritingEvent {
  const SearchQueryChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

/// Recognize all handwriting on all pages.
class RecognizeAllRequested extends HandwritingEvent {
  const RecognizeAllRequested();
}

/// Math expression detected in strokes.
class MathExpressionDetected extends HandwritingEvent {
  const MathExpressionDetected({required this.strokeIds});
  final List<String> strokeIds;
  @override
  List<Object?> get props => [strokeIds];
}

/// TextBlock position updated (drag).
class TextBlockMoved extends HandwritingEvent {
  const TextBlockMoved({required this.id, required this.newPosition});
  final String id;
  final dynamic newPosition; // Offset
  @override
  List<Object?> get props => [id, newPosition];
}
