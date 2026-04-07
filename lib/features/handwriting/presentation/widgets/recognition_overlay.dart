import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/handwriting/domain/entities/recognition_result.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_event.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_state.dart';
import 'package:y2notes2/features/handwriting/presentation/widgets/recognition_candidates_panel.dart';

/// Semi-transparent overlay that appears above handwriting after recognition.
/// Shows recognized text, confidence indicator, and accept/reject buttons.
class RecognitionOverlay extends StatefulWidget {
  const RecognitionOverlay({super.key});

  @override
  State<RecognitionOverlay> createState() => _RecognitionOverlayState();
}

class _RecognitionOverlayState extends State<RecognitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  bool _showAlternatives = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HandwritingBloc, HandwritingState>(
      buildWhen: (prev, curr) =>
          prev.latestResult != curr.latestResult ||
          prev.isProcessing != curr.isProcessing,
      builder: (context, state) {
        if (state.isProcessing) {
          return const _LoadingOverlay();
        }

        if (!state.hasResult) return const SizedBox.shrink();

        final result = state.latestResult!;
        final best = result.best!;

        return FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RecognitionCard(
                text: best.text,
                confidence: best.confidence,
                onAccept: () {
                  context.read<HandwritingBloc>().add(
                        const CandidateAccepted(candidateIndex: 0),
                      );
                },
                onReject: () {
                  context.read<HandwritingBloc>().add(const CandidateRejected());
                },
                onShowAlternatives: () {
                  setState(() => _showAlternatives = !_showAlternatives);
                },
                showAlternatives: _showAlternatives,
              ),
              if (_showAlternatives && result.candidates.length > 1)
                RecognitionCandidatesPanel(result: result),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Recognizing…'),
        ],
      ),
    );
  }
}

class _RecognitionCard extends StatelessWidget {
  const _RecognitionCard({
    required this.text,
    required this.confidence,
    required this.onAccept,
    required this.onReject,
    required this.onShowAlternatives,
    required this.showAlternatives,
  });

  final String text;
  final double confidence;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onShowAlternatives;
  final bool showAlternatives;

  Color _confidenceColor(BuildContext context) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _confidenceColor(context).withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confidence dot
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _confidenceColor(context),
            ),
          ),
          // Recognized text
          Flexible(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Alternatives button
          IconButton(
            icon: Icon(
              showAlternatives
                  ? Icons.expand_less
                  : Icons.expand_more,
              size: 18,
            ),
            onPressed: onShowAlternatives,
            tooltip: 'Show alternatives',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          // Accept (✓)
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: onAccept,
            tooltip: 'Accept',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          // Reject (✗)
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            onPressed: onReject,
            tooltip: 'Reject',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
