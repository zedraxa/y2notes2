import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuitse/features/handwriting/domain/entities/writing_analytics.dart';
import 'package:biscuitse/features/handwriting/presentation/bloc/handwriting_state.dart';
import 'package:biscuitse/features/handwriting/presentation/bloc/handwriting_bloc.dart';

/// Bottom sheet showing writing analytics statistics.
class WritingAnalysisPanel extends StatelessWidget {
  const WritingAnalysisPanel({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<HandwritingBloc>(),
        child: const WritingAnalysisPanel(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HandwritingBloc, HandwritingState>(
      buildWhen: (prev, curr) => prev.analytics != curr.analytics,
      builder: (context, state) {
        final analytics = state.analytics;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Writing Analysis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Statistics about your handwriting',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 20),
                    if (analytics == null)
                      _EmptyAnalyticsView()
                    else
                      _AnalyticsContent(analytics: analytics),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyAnalyticsView extends StatelessWidget {
  const _EmptyAnalyticsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No data yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Recognize some handwriting to see statistics',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.analytics});

  final WritingAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatRow(
          icon: Icons.text_fields,
          label: 'Avg Character Size',
          value: '${analytics.averageCharacterSize.toStringAsFixed(1)} px',
        ),
        _StatRow(
          icon: Icons.speed,
          label: 'Writing Speed',
          value: '${analytics.writingSpeedCpm.toStringAsFixed(0)} cpm',
        ),
        _StatRow(
          icon: Icons.check_circle_outline,
          label: 'Consistency Score',
          value: '${(analytics.consistencyScore * 100).toStringAsFixed(0)}%',
          trailing: _ScoreBar(value: analytics.consistencyScore),
        ),
        _StatRow(
          icon: Icons.rotate_right,
          label: 'Avg Slant Angle',
          value: '${analytics.averageSlantAngle.toStringAsFixed(1)}°',
        ),
        _StatRow(
          icon: Icons.touch_app_outlined,
          label: 'Avg Pressure',
          value: '${(analytics.averagePressure * 100).toStringAsFixed(0)}%',
          trailing: _ScoreBar(value: analytics.averagePressure),
        ),
        _StatRow(
          icon: Icons.format_list_numbered,
          label: 'Characters Recognized',
          value: analytics.totalCharactersRecognized.toString(),
        ),
        if (analytics.commonErrors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Common Corrections',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: analytics.commonErrors
                .take(10)
                .map(
                  (e) => Chip(
                    label: Text(e, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
