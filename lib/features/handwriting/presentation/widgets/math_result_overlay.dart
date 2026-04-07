import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/handwriting/engine/math_recognizer.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_event.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_state.dart';

/// Overlay that displays a computed math result next to a detected expression.
class MathResultOverlay extends StatelessWidget {
  const MathResultOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HandwritingBloc, HandwritingState>(
      buildWhen: (prev, curr) => prev.mathResult != curr.mathResult,
      builder: (context, state) {
        final math = state.mathResult;
        if (math == null || !math.isValid) return const SizedBox.shrink();

        return _MathResultCard(
          math: math,
          onDismiss: () {
            context.read<HandwritingBloc>().add(const CandidateRejected());
          },
        );
      },
    );
  }
}

class _MathResultCard extends StatelessWidget {
  const _MathResultCard({required this.math, required this.onDismiss});

  final MathRecognitionResult math;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(text: math.expression),
                  if (math.result != null) ...[
                    const TextSpan(
                      text: ' = ',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: math.result!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}
