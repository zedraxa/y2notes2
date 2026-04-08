import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/flash_card.dart';
import '../../domain/entities/flash_card_deck.dart';
import '../bloc/flash_card_bloc.dart';
import '../bloc/flash_card_event.dart';
import '../bloc/flash_card_state.dart';

/// Page for creating or editing a flash card.
class CardEditorPage extends StatefulWidget {
  const CardEditorPage({
    super.key,
    required this.deckId,
    this.cardId,
  });

  final String deckId;

  /// If null, a new card is being created.
  final String? cardId;

  @override
  State<CardEditorPage> createState() => _CardEditorPageState();
}

class _CardEditorPageState extends State<CardEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _frontController;
  late TextEditingController _backController;
  late TextEditingController _tagsController;
  bool _isInitialised = false;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController();
    _backController = TextEditingController();
    _tagsController = TextEditingController();
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _initFromCard(FlashCard? card) {
    if (_isInitialised) return;
    _isInitialised = true;
    if (card != null) {
      _frontController.text = card.front;
      _backController.text = card.back;
      _tagsController.text = card.tags.join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cardId != null;

    return BlocBuilder<FlashCardBloc, FlashCardState>(
      builder: (context, state) {
        final deck = state.decks
            .cast<FlashCardDeck?>()
            .firstWhere((d) => d!.id == widget.deckId, orElse: () => null);

        FlashCard? existingCard;
        if (isEditing && deck != null) {
          existingCard = deck.cards
              .cast<FlashCard?>()
              .firstWhere((c) => c!.id == widget.cardId, orElse: () => null);
          _initFromCard(existingCard);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Card' : 'New Card'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.go('/flashcards/deck/${widget.deckId}'),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Front (question)
                Text(
                  'Front (Question)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _frontController,
                  decoration: const InputDecoration(
                    hintText: 'Enter the question or prompt…',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                // Back (answer)
                Text(
                  'Back (Answer)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _backController,
                  decoration: const InputDecoration(
                    hintText: 'Enter the answer…',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                // Tags
                Text(
                  'Tags (comma separated)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. biology, chapter3',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _onSave,
                  child: Text(isEditing ? 'Save Changes' : 'Add Card'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final bloc = context.read<FlashCardBloc>();
    if (widget.cardId != null) {
      bloc.add(CardUpdated(
        deckId: widget.deckId,
        cardId: widget.cardId!,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        tags: tags,
      ));
    } else {
      bloc.add(CardAdded(
        deckId: widget.deckId,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        tags: tags,
      ));
    }
    context.go('/flashcards/deck/${widget.deckId}');
  }
}
