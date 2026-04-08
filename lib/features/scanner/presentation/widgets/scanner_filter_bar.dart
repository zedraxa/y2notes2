import 'package:flutter/material.dart';
import 'package:biscuits/features/scanner/domain/entities/scanned_document.dart';

/// A horizontal row of filter chips that lets the user
/// preview and select a scan filter.
class ScannerFilterBar extends StatelessWidget {
  const ScannerFilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
    super.key,
  });

  final ScannerFilter selectedFilter;
  final ValueChanged<ScannerFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 16),
          itemCount: ScannerFilter.values.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = ScannerFilter.values[index];
            final isSelected = filter == selectedFilter;
            return ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: isSelected,
              onSelected: (_) =>
                  onFilterChanged(filter),
              avatar: Icon(
                _filterIcon(filter),
                size: 18,
              ),
            );
          },
        ),
      );

  String _filterLabel(ScannerFilter filter) {
    switch (filter) {
      case ScannerFilter.auto:
        return 'Auto';
      case ScannerFilter.document:
        return 'Document';
      case ScannerFilter.original:
        return 'Original';
      case ScannerFilter.greyscale:
        return 'Greyscale';
      case ScannerFilter.highContrast:
        return 'High Contrast';
      case ScannerFilter.whiteboard:
        return 'Whiteboard';
    }
  }

  IconData _filterIcon(ScannerFilter filter) {
    switch (filter) {
      case ScannerFilter.auto:
        return Icons.auto_fix_high;
      case ScannerFilter.document:
        return Icons.description_outlined;
      case ScannerFilter.original:
        return Icons.image_outlined;
      case ScannerFilter.greyscale:
        return Icons.tonality;
      case ScannerFilter.highContrast:
        return Icons.contrast;
      case ScannerFilter.whiteboard:
        return Icons.tv_outlined;
    }
  }
}
