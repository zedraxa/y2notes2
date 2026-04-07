import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuitse/features/handwriting/domain/entities/recognition_result.dart';
import 'package:biscuitse/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:biscuitse/features/handwriting/presentation/bloc/handwriting_event.dart';

/// Shows all recognition candidates with confidence bars.
/// Tapping a candidate accepts it.
class RecognitionCandidatesPanel extends StatelessWidget {
  const RecognitionCandidatesPanel({super.key, required this.result});

  final RecognitionResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              'Alternatives',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          ...result.candidates.asMap().entries.map((e) {
            final index = e.key;
            final candidate = e.value;
            return _CandidateRow(
              candidate: candidate,
              index: index,
              isFirst: index == 0,
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.index,
    required this.isFirst,
  });

  final RecognitionCandidate candidate;
  final int index;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        context.read<HandwritingBloc>().add(
              CandidateAccepted(candidateIndex: index),
            );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Text
            Expanded(
              child: Text(
                candidate.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isFirst ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            // Confidence bar
            SizedBox(
              width: 80,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: candidate.confidence.clamp(0.0, 1.0),
                  backgroundColor:
                      colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    candidate.confidence >= 0.7
                        ? Colors.green
                        : candidate.confidence >= 0.4
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${(candidate.confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
