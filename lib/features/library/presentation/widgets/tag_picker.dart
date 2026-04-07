import 'package:flutter/material.dart';
import 'package:y2notes2/features/library/domain/entities/tag.dart';

/// A chip-based tag picker that lets the user toggle tags on/off.
class TagPicker extends StatelessWidget {
  const TagPicker({
    super.key,
    required this.allTags,
    required this.selectedTagIds,
    required this.onToggle,
    this.onCreateTag,
  });

  final List<Tag> allTags;
  final Set<String> selectedTagIds;
  final void Function(String tagId) onToggle;

  /// Optional callback to create a brand-new tag (opens its own dialog).
  final VoidCallback? onCreateTag;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ...allTags.map((tag) {
          final selected = selectedTagIds.contains(tag.id);
          return ChoiceChip(
            avatar: CircleAvatar(
              backgroundColor: tag.color,
              radius: 6,
            ),
            label: Text(
              tag.emoji != null ? '${tag.emoji} ${tag.name}' : tag.name,
            ),
            selected: selected,
            onSelected: (_) => onToggle(tag.id),
          );
        }),
        if (onCreateTag != null)
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('New tag'),
            onPressed: onCreateTag,
          ),
      ],
    );
  }
}

/// Shows a bottom sheet for managing tags on a specific item.
Future<void> showTagPickerSheet(
  BuildContext context, {
  required List<Tag> allTags,
  required Set<String> selectedTagIds,
  required void Function(String tagId, bool add) onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _TagPickerSheet(
      allTags: allTags,
      selectedTagIds: Set.of(selectedTagIds),
      onChanged: onChanged,
    ),
  );
}

class _TagPickerSheet extends StatefulWidget {
  const _TagPickerSheet({
    required this.allTags,
    required this.selectedTagIds,
    required this.onChanged,
  });

  final List<Tag> allTags;
  final Set<String> selectedTagIds;
  final void Function(String tagId, bool add) onChanged;

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.selectedTagIds);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Add Tags',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: widget.allTags.map((tag) {
                  final selected = _selected.contains(tag.id);
                  return CheckboxListTile(
                    value: selected,
                    title: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: tag.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (tag.emoji != null)
                          Text('${tag.emoji} ',
                              style: const TextStyle(fontSize: 14)),
                        Text(tag.name),
                      ],
                    ),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(tag.id);
                        } else {
                          _selected.remove(tag.id);
                        }
                        widget.onChanged(tag.id, v ?? false);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
