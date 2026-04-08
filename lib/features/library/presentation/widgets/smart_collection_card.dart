import 'package:flutter/material.dart';
import 'package:biscuits/features/library/domain/entities/smart_collection.dart';

/// A compact card representing a single [SmartCollection].
class SmartCollectionCard extends StatelessWidget {
  const SmartCollectionCard({
    super.key,
    required this.collection,
    required this.itemCount,
    this.onTap,
  });

  final SmartCollection collection;
  final int itemCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (collection.emoji != null)
                    Text(collection.emoji!,
                        style: const TextStyle(fontSize: 24))
                  else
                    Icon(
                      _iconFor(collection.rule),
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      collection.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$itemCount item${itemCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(SmartCollectionRule rule) {
    switch (rule) {
      case SmartCollectionRule.recent:
        return Icons.access_time;
      case SmartCollectionRule.favorites:
        return Icons.star_outline;
      case SmartCollectionRule.shared:
        return Icons.people_outline;
      case SmartCollectionRule.largeNotebooks:
        return Icons.library_books_outlined;
      case SmartCollectionRule.custom:
        return Icons.auto_awesome_outlined;
    }
  }
}
