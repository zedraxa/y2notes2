import 'package:flutter/material.dart';
import 'package:y2notes2/features/library/domain/entities/tag.dart';

/// A tag-cloud visualisation where each tag's size reflects its [Tag.usageCount].
class TagCloud extends StatelessWidget {
  const TagCloud({
    super.key,
    required this.tags,
    this.onTagTap,
  });

  final List<Tag> tags;

  /// Called when the user taps a tag (e.g. to filter by it).
  final void Function(Tag tag)? onTagTap;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const Center(child: Text('No tags yet'));
    }

    final maxUsage =
        tags.map((t) => t.usageCount).fold(1, (a, b) => a > b ? a : b);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: tags.map((tag) {
        // Scale font from 12 to 24 based on relative usage.
        final ratio = maxUsage > 0 ? tag.usageCount / maxUsage : 0.0;
        final fontSize = 12.0 + ratio * 12.0;

        return GestureDetector(
          onTap: () => onTagTap?.call(tag),
          child: Chip(
            backgroundColor: tag.color.withAlpha(40),
            side: BorderSide(color: tag.color),
            label: Text(
              tag.emoji != null ? '${tag.emoji} ${tag.name}' : tag.name,
              style: TextStyle(
                fontSize: fontSize,
                color: tag.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
