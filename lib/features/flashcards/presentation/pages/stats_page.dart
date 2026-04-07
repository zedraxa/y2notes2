import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/flash_card_deck.dart';
import '../../domain/entities/study_stats.dart';
import '../bloc/flash_card_bloc.dart';
import '../bloc/flash_card_state.dart';

/// Statistics and progress tracking page for a flash card deck.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashCardBloc, FlashCardState>(
      builder: (context, state) {
        final deck = state.decks
            .cast<FlashCardDeck?>()
            .firstWhere((d) => d!.id == deckId, orElse: () => null);

        final stats = state.statsForDeck(deckId);

        return Scaffold(
          appBar: AppBar(
            title: Text(deck != null ? '${deck.emoji} Stats' : 'Statistics'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/flashcards/deck/$deckId'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (deck != null) _DeckOverview(deck: deck),
              const SizedBox(height: 16),
              _SectionTitle('Card Distribution'),
              if (deck != null) _CardDistribution(deck: deck),
              const SizedBox(height: 16),
              _SectionTitle('Recent Sessions'),
              if (stats.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No study sessions yet.'),
                  ),
                )
              else
                ...stats.reversed.take(10).map((s) => _SessionTile(stat: s)),
              const SizedBox(height: 16),
              if (stats.isNotEmpty) ...[
                _SectionTitle('Cumulative Stats'),
                _CumulativeStats(stats: stats),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _DeckOverview extends StatelessWidget {
  const _DeckOverview({required this.deck});
  final FlashCardDeck deck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mastery = (deck.masteryPercent * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${deck.emoji} ${deck.name}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(
                    value: '${deck.cardCount}', label: 'Total', icon: Icons.style),
                _MiniStat(
                    value: '${deck.dueCards.length}',
                    label: 'Due',
                    icon: Icons.schedule),
                _MiniStat(
                    value: '${deck.newCards.length}',
                    label: 'New',
                    icon: Icons.fiber_new),
                _MiniStat(
                    value: '$mastery%',
                    label: 'Mastered',
                    icon: Icons.emoji_events),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: deck.masteryPercent,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CardDistribution extends StatelessWidget {
  const _CardDistribution({required this.deck});
  final FlashCardDeck deck;

  @override
  Widget build(BuildContext context) {
    if (deck.cards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No cards yet.'),
      );
    }

    final newCount = deck.newCards.length;
    final dueCount = deck.dueCards.length;
    final learnedCount = deck.learnedCards.length;
    final total = deck.cardCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _DistributionBar(
              segments: [
                _Segment('New', newCount, Colors.blue),
                _Segment('Due', dueCount, Colors.orange),
                _Segment('Learned', learnedCount, Colors.green),
              ],
              total: total,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Legend(color: Colors.blue, label: 'New ($newCount)'),
                _Legend(color: Colors.orange, label: 'Due ($dueCount)'),
                _Legend(color: Colors.green, label: 'Learned ($learnedCount)'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment {
  const _Segment(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.segments, required this.total});
  final List<_Segment> segments;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox(height: 12);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: segments.map((seg) {
            final flex = (seg.count / total * 100).round().clamp(0, 100);
            if (flex == 0) return const SizedBox.shrink();
            return Expanded(
              flex: flex,
              child: Container(color: seg.color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.stat});
  final StudyStats stat;

  @override
  Widget build(BuildContext context) {
    final accuracy = (stat.accuracyPercent * 100).round();
    final duration = Duration(seconds: stat.studyDurationSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accuracy >= 80
              ? Colors.green.withAlpha(50)
              : accuracy >= 50
                  ? Colors.orange.withAlpha(50)
                  : Colors.red.withAlpha(50),
          child: Text('$accuracy%',
              style: TextStyle(
                fontSize: 12,
                color: accuracy >= 80
                    ? Colors.green
                    : accuracy >= 50
                        ? Colors.orange
                        : Colors.red,
              )),
        ),
        title: Text('${stat.cardsStudied} cards studied'),
        subtitle: Text(
          '${stat.correctCount} correct · ${stat.incorrectCount} incorrect · ${minutes}m ${seconds}s',
        ),
        trailing: Text(
          _formatDate(stat.date),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.month}/${d.day}';
  }
}

class _CumulativeStats extends StatelessWidget {
  const _CumulativeStats({required this.stats});
  final List<StudyStats> stats;

  @override
  Widget build(BuildContext context) {
    final totalCards =
        stats.fold<int>(0, (sum, s) => sum + s.cardsStudied);
    final totalCorrect =
        stats.fold<int>(0, (sum, s) => sum + s.correctCount);
    final totalSeconds =
        stats.fold<int>(0, (sum, s) => sum + s.studyDurationSeconds);
    final overallAccuracy =
        totalCards > 0 ? (totalCorrect / totalCards * 100).round() : 0;
    final totalMinutes = totalSeconds ~/ 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _CumulativeRow(
                label: 'Total Sessions', value: '${stats.length}'),
            _CumulativeRow(label: 'Total Cards Reviewed', value: '$totalCards'),
            _CumulativeRow(
                label: 'Overall Accuracy', value: '$overallAccuracy%'),
            _CumulativeRow(
                label: 'Total Study Time', value: '${totalMinutes}min'),
          ],
        ),
      ),
    );
  }
}

class _CumulativeRow extends StatelessWidget {
  const _CumulativeRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
