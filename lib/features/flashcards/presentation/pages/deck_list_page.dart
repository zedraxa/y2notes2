import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:biscuits/app/route_names.dart';

import '../../domain/entities/flash_card_deck.dart';
import '../bloc/flash_card_bloc.dart';
import '../bloc/flash_card_event.dart';
import '../bloc/flash_card_state.dart';

/// Shows all flash card decks with summary info and a FAB to create new decks.
class DeckListPage extends StatelessWidget {
  const DeckListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashCardBloc, FlashCardState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Flash Cards'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: state.status == FlashCardStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : state.decks.isEmpty
                  ? _EmptyState(onCreateDeck: () => _showCreateDialog(context))
                  : _DeckGrid(decks: state.decks),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Deck'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Deck Name',
                hintText: 'e.g. Biology Chapter 3',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<FlashCardBloc>().add(DeckCreated(
                      name: nameController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    ));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateDeck});
  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No flash card decks yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first deck to start studying!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateDeck,
            icon: const Icon(Icons.add),
            label: const Text('Create Deck'),
          ),
        ],
      ),
    );
  }
}

class _DeckGrid extends StatelessWidget {
  const _DeckGrid({required this.decks});
  final List<FlashCardDeck> decks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          childAspectRatio: 1.1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: decks.length,
        itemBuilder: (context, index) => _DeckCard(deck: decks[index]),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.deck});
  final FlashCardDeck deck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueCount = deck.dueCards.length;
    final masteryPct = (deck.masteryPercent * 100).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<FlashCardBloc>().add(DeckSelected(deck.id));
          context.push(AppRoutes.deck(deck.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(deck.emoji, style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  if (dueCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$dueCount due',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                deck.name,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (deck.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  deck.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Text(
                    '${deck.cardCount} cards',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '$masteryPct% mastered',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: masteryPct >= 80
                          ? Colors.green
                          : masteryPct >= 50
                              ? Colors.orange
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: deck.masteryPercent,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
