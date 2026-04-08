import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:biscuits/app/route_names.dart';

import '../../domain/entities/flash_card.dart';
import '../bloc/flash_card_bloc.dart';
import '../bloc/flash_card_event.dart';
import '../bloc/flash_card_state.dart';
import '../widgets/flip_card_widget.dart';

/// Spaced repetition study session page.
///
/// Shows cards one at a time; user taps to flip, then rates difficulty.
/// The SM-2 algorithm schedules the next review based on the rating.
class StudySessionPage extends StatelessWidget {
  const StudySessionPage({super.key, required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashCardBloc, FlashCardState>(
      builder: (context, state) {
        // Study complete.
        if (state.isStudyComplete && state.status == FlashCardStatus.studying) {
          return _StudyCompleteView(
            deckId: deckId,
            correct: state.sessionCorrect,
            incorrect: state.sessionIncorrect,
          );
        }

        final card = state.currentStudyCard;
        if (card == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Study')),
            body: const Center(child: Text('No cards to study.')),
          );
        }

        final progress = state.studyQueue.isEmpty
            ? 0.0
            : state.studyIndex / state.studyQueue.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(
                'Card ${state.studyIndex + 1} / ${state.studyQueue.length}'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                context
                    .read<FlashCardBloc>()
                    .add(const StudySessionEnded());
                context.pop();
              },
            ),
          ),
          body: Column(
            children: [
              LinearProgressIndicator(value: progress),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FlipCardWidget(
                    front: card.front,
                    back: card.back,
                  ),
                ),
              ),
              // Difficulty buttons.
              _DifficultyBar(card: card),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// Rating buttons: Again, Hard, Good, Easy.
class _DifficultyBar extends StatelessWidget {
  const _DifficultyBar({required this.card});
  final FlashCard card;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ratingButton(context, CardDifficulty.again, 'Again', Colors.red),
          const SizedBox(width: 8),
          _ratingButton(context, CardDifficulty.hard, 'Hard', Colors.orange),
          const SizedBox(width: 8),
          _ratingButton(context, CardDifficulty.good, 'Good', Colors.green),
          const SizedBox(width: 8),
          _ratingButton(context, CardDifficulty.easy, 'Easy', Colors.blue),
        ],
      ),
    );
  }

  Widget _ratingButton(
    BuildContext context,
    CardDifficulty difficulty,
    String label,
    Color color,
  ) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.39)),
        ),
        onPressed: () {
          context.read<FlashCardBloc>().add(
                CardReviewed(cardId: card.id, difficulty: difficulty),
              );
        },
        child: Text(label),
      ),
    );
  }
}

class _StudyCompleteView extends StatelessWidget {
  const _StudyCompleteView({
    required this.deckId,
    required this.correct,
    required this.incorrect,
  });
  final String deckId;
  final int correct;
  final int incorrect;

  @override
  Widget build(BuildContext context) {
    final total = correct + incorrect;
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Session Complete')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 72, color: Colors.amber),
            const SizedBox(height: 16),
            Text('Great job!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            _StatRow(label: 'Cards studied', value: '$total'),
            _StatRow(label: 'Correct', value: '$correct'),
            _StatRow(label: 'Incorrect', value: '$incorrect'),
            _StatRow(label: 'Accuracy', value: '$accuracy%'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                context
                    .read<FlashCardBloc>()
                    .add(const StudySessionEnded());
                context.pop();
              },
              child: const Text('Back to Deck'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
