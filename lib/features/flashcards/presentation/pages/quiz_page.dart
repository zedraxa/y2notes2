import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:biscuits/app/route_names.dart';

import '../../domain/entities/quiz_session.dart';
import '../bloc/flash_card_bloc.dart';
import '../bloc/flash_card_event.dart';
import '../bloc/flash_card_state.dart';

/// Quiz mode page supporting multiple-choice, written, and matching quizzes.
class QuizPage extends StatelessWidget {
  const QuizPage({super.key, required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashCardBloc, FlashCardState>(
      builder: (context, state) {
        final session = state.quizSession;
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz')),
            body: const Center(child: Text('No quiz in progress.')),
          );
        }

        // Quiz complete — show results.
        if (session.isComplete ||
            session.currentIndex >= session.totalQuestions) {
          return _QuizResults(deckId: deckId, session: session);
        }

        final question = session.currentQuestion!;
        final progress = session.totalQuestions > 0
            ? session.currentIndex / session.totalQuestions
            : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(
                'Question ${session.currentIndex + 1} / ${session.totalQuestions}'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                context.read<FlashCardBloc>().add(const QuizEnded());
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            question.card.front,
                            style:
                                Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Answer area
                      Expanded(
                        child: question.userAnswer != null
                            ? _AnswerFeedback(question: question)
                            : _AnswerInput(question: question),
                      ),
                    ],
                  ),
                ),
              ),
              // Next button (only after answering)
              if (question.userAnswer != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        context
                            .read<FlashCardBloc>()
                            .add(const QuizNextQuestion());
                      },
                      child: const Text('Next'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Renders the correct answer input based on quiz type.
class _AnswerInput extends StatelessWidget {
  const _AnswerInput({required this.question});
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuizType.multipleChoice:
        return _MultipleChoiceInput(question: question);
      case QuizType.written:
        return _WrittenInput();
      case QuizType.matching:
        return _WrittenInput(hint: 'Type the matching answer…');
    }
  }
}

class _MultipleChoiceInput extends StatelessWidget {
  const _MultipleChoiceInput({required this.question});
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: question.options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () {
              context.read<FlashCardBloc>().add(QuizAnswered(option));
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
            ),
            child: Text(option),
          ),
        );
      }).toList(),
    );
  }
}

class _WrittenInput extends StatefulWidget {
  const _WrittenInput({this.hint});
  final String? hint;

  @override
  State<_WrittenInput> createState() => _WrittenInputState();
}

class _WrittenInputState extends State<_WrittenInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint ?? 'Type your answer…',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              context
                  .read<FlashCardBloc>()
                  .add(QuizAnswered(_controller.text.trim()));
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({required this.question});
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final isCorrect = question.isCorrect ?? false;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withOpacity(0.10)
                : Colors.red.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          child: Column(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        if (!isCorrect) ...[
          const SizedBox(height: 16),
          Text('Your answer:', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            question.userAnswer ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 12),
          Text('Correct answer:', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            question.card.back,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}

class _QuizResults extends StatelessWidget {
  const _QuizResults({required this.deckId, required this.session});
  final String deckId;
  final QuizSession session;

  @override
  Widget build(BuildContext context) {
    final score = (session.scorePercent * 100).round();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              score >= 80
                  ? Icons.emoji_events
                  : score >= 50
                      ? Icons.thumb_up
                      : Icons.sentiment_dissatisfied,
              size: 72,
              color: score >= 80
                  ? Colors.amber
                  : score >= 50
                      ? Colors.orange
                      : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text('$score%', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              score >= 80
                  ? 'Excellent!'
                  : score >= 50
                      ? 'Good effort!'
                      : 'Keep practicing!',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            _ResultRow(
                label: 'Total Questions', value: '${session.totalQuestions}'),
            _ResultRow(label: 'Correct', value: '${session.correctCount}'),
            _ResultRow(
                label: 'Incorrect', value: '${session.incorrectCount}'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                context.read<FlashCardBloc>().add(const QuizEnded());
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
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
