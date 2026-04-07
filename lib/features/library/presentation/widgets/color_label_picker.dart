import 'package:flutter/material.dart';
import 'package:y2notes2/features/library/domain/entities/library_item.dart';

/// A row of colour-label circles for quick item labelling.
class ColorLabelPicker extends StatelessWidget {
  const ColorLabelPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ColorLabel? selected;
  final void Function(ColorLabel? label) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        // "No colour" option
        GestureDetector(
          onTap: () => onSelect(null),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected == null ? Colors.blue : Colors.grey,
                width: selected == null ? 3 : 1,
              ),
              color: Colors.transparent,
            ),
            child: const Icon(Icons.block, size: 14, color: Colors.grey),
          ),
        ),
        ...ColorLabel.values.map((label) {
          final isSelected = selected == label;
          return GestureDetector(
            onTap: () => onSelect(label),
            child: Tooltip(
              message: label.label,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: label.color,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: label.color.withAlpha(128),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
