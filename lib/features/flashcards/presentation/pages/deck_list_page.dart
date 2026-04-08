import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:y2notes2/app/theme/colors.dart';

import '../../domain/entities/flash_card_deck.dart';
import '../bloc/flash_card_bloc.dart';
import '../bloc/flash_card_event.dart';
import '../bloc/flash_card_state.dart';

/// Apple-style flash card deck list with refined cards and clean empty state.
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.go('/'),
            ),
          ),
          body: state.status == FlashCardStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : state.decks.isEmpty
                  ? _EmptyState(onCreateDeck: () => _showCreateDialog(context))
                  : _DeckGrid(decks: state.decks),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateDialog(context),
            child: const Icon(Icons.add_rounded, size: 28),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.systemIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.style_rounded,
              size: 36,
              color: AppColors.systemIndigo.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Decks Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first deck to start studying',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateDeck,
            icon: const Icon(Icons.add_rounded, size: 18),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          childAspectRatio: 1.05,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
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
    final isDark = theme.brightness == Brightness.dark;
    final dueCount = deck.dueCards.length;
    final masteryPct = (deck.masteryPercent * 100).round();

    return GestureDetector(
      onTap: () {
        context.read<FlashCardBloc>().add(DeckSelected(deck.id));
        context.go('/flashcards/deck/${deck.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
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
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$dueCount due',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
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
                style: theme.textTheme.bodySmall,
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
                        ? AppColors.systemGreen
                        : masteryPct >= 50
                            ? AppColors.systemOrange
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: deck.masteryPercent,
                minHeight: 3,
                backgroundColor: isDark
                    ? AppColors.darkDivider
                    : AppColors.toolbarBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
