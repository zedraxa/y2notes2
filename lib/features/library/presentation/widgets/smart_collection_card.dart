import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/features/library/domain/entities/smart_collection.dart';

/// Apple-style compact card for a [SmartCollection] with tinted icon
/// background and clean typography.
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
    final isDark = theme.brightness == Brightness.dark;
    final tint = _tintFor(collection.rule);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withOpacity(isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: collection.emoji != null
                    ? Text(collection.emoji!,
                        style: const TextStyle(fontSize: 18))
                    : Icon(_iconFor(collection.rule),
                        size: 20, color: tint),
              ),
            ),
            const Spacer(),
            Text(
              collection.name,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$itemCount item${itemCount == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _tintFor(SmartCollectionRule rule) {
    switch (rule) {
      case SmartCollectionRule.recent:
        return AppColors.accent;
      case SmartCollectionRule.favorites:
        return AppColors.systemYellow;
      case SmartCollectionRule.shared:
        return AppColors.systemGreen;
      case SmartCollectionRule.largeNotebooks:
        return AppColors.systemIndigo;
      case SmartCollectionRule.custom:
        return AppColors.systemOrange;
    }
  }

  IconData _iconFor(SmartCollectionRule rule) {
    switch (rule) {
      case SmartCollectionRule.recent:
        return Icons.access_time_rounded;
      case SmartCollectionRule.favorites:
        return Icons.star_rounded;
      case SmartCollectionRule.shared:
        return Icons.people_rounded;
      case SmartCollectionRule.largeNotebooks:
        return Icons.library_books_rounded;
      case SmartCollectionRule.custom:
        return Icons.auto_awesome_rounded;
    }
  }
}
