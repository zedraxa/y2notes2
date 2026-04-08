import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:biscuits/app/route_names.dart';

import '../../domain/entities/flash_card.dart';
import '../../domain/entities/flash_card_deck.dart';
import '../../domain/entities/quiz_session.dart';
import '../bloc/flash_card_bloc.dart';
import '../bloc/flash_card_event.dart';
import '../bloc/flash_card_state.dart';

/// Deck detail page showing cards, study options, and quiz launchers.
class DeckDetailPage extends StatelessWidget {
  const DeckDetailPage({super.key, required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashCardBloc, FlashCardState>(
      builder: (context, state) {
        final deck = state.decks
            .cast<FlashCardDeck?>()
            .firstWhere((d) => d!.id == deckId, orElse: () => null);
        if (deck == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Deck')),
            body: const Center(child: Text('Deck not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${deck.emoji} ${deck.name}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<FlashCardBloc>().add(const DeckDeselected());
                context.pop();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined),
                tooltip: 'Statistics',
                onPressed: () =>
                    context.push(AppRoutes.deckStats(deckId)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Deck',
                onPressed: () => _showEditDialog(context, deck),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete Deck',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Study & Quiz bar ──────────────────────────────
              _ActionBar(deckId: deckId, cardCount: deck.cardCount),
              const Divider(height: 1),
              // ── Card list ─────────────────────────────────────
              Expanded(
                child: deck.cards.isEmpty
                    ? _EmptyCardState(deckId: deckId)
                    : _CardListView(deckId: deckId, cards: deck.cards),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(AppRoutes.deckAdd(deckId)),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, FlashCardDeck deck) {
    final nameC = TextEditingController(text: deck.name);
    final descC = TextEditingController(text: deck.description ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Deck'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Deck Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descC,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<FlashCardBloc>().add(DeckUpdated(
                    deckId: deckId,
                    name: nameC.text.trim(),
                    description: descC.text.trim().isEmpty
                        ? null
                        : descC.text.trim(),
                  ));
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Deck?'),
        content: const Text(
            'This will permanently delete this deck and all its cards.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<FlashCardBloc>().add(DeckDeleted(deckId));
              Navigator.pop(dialogCtx);
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Row of action buttons for study and quiz modes.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.deckId, required this.cardCount});
  final String deckId;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final enabled = cardCount >= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: cardCount > 0
                ? () {
                    context
                        .read<FlashCardBloc>()
                        .add(StudySessionStarted(deckId));
                    context.push(AppRoutes.deckStudy(deckId));
                  }
                : null,
            icon: const Icon(Icons.school_outlined),
            label: const Text('Study'),
          ),
          OutlinedButton.icon(
            onPressed: enabled
                ? () {
                    context.read<FlashCardBloc>().add(QuizStarted(
                          deckId: deckId,
                          quizType: QuizType.multipleChoice,
                        ));
                    context.push(AppRoutes.deckQuiz(deckId));
                  }
                : null,
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Multiple Choice'),
          ),
          OutlinedButton.icon(
            onPressed: enabled
                ? () {
                    context.read<FlashCardBloc>().add(QuizStarted(
                          deckId: deckId,
                          quizType: QuizType.written,
                        ));
                    context.push(AppRoutes.deckQuiz(deckId));
                  }
                : null,
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Written'),
          ),
          OutlinedButton.icon(
            onPressed: enabled
                ? () {
                    context.read<FlashCardBloc>().add(QuizStarted(
                          deckId: deckId,
                          quizType: QuizType.matching,
                        ));
                    context.push(AppRoutes.deckQuiz(deckId));
                  }
                : null,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Matching'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCardState extends StatelessWidget {
  const _EmptyCardState({required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_add_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No cards yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.deckAdd(deckId)),
            icon: const Icon(Icons.add),
            label: const Text('Add Card'),
          ),
        ],
      ),
    );
  }
}

class _CardListView extends StatelessWidget {
  const _CardListView({required this.deckId, required this.cards});
  final String deckId;
  final List<FlashCard> cards;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _FlashCardTile(deckId: deckId, card: card);
      },
    );
  }
}

class _FlashCardTile extends StatelessWidget {
  const _FlashCardTile({required this.deckId, required this.card});
  final String deckId;
  final FlashCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        title: Text(
          card.front,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          card.back,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.isDue)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '${card.correctStreak}🔥',
              style: theme.textTheme.bodySmall,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () {
                context.read<FlashCardBloc>().add(
                      CardDeleted(deckId: deckId, cardId: card.id),
                    );
              },
            ),
          ],
        ),
        onTap: () =>
            context.push(AppRoutes.deckEdit(deckId, card.id)),
      ),
    );
  }
}
