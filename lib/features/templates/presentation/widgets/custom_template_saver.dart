import 'package:flutter/material.dart';
import 'package:biscuitse/features/canvas/domain/models/canvas_config.dart';
import 'package:biscuitse/features/templates/domain/entities/page_template.dart';

/// Dialog for saving the current canvas as a custom template.
class CustomTemplateSaver extends StatefulWidget {
  const CustomTemplateSaver({
    super.key,
    required this.currentConfig,
    required this.onSave,
  });

  final CanvasConfig currentConfig;
  final void Function(NoteTemplate template) onSave;

  @override
  State<CustomTemplateSaver> createState() => _CustomTemplateSaverState();
}

class _CustomTemplateSaverState extends State<CustomTemplateSaver> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Custom';
  String _emoji = '📄';

  static const _emojiOptions = [
    '📄', '📝', '📒', '📓', '📔', '📕', '📗', '📘', '📙', '📚',
    '✏️', '🖊️', '🖋️', '✒️', '📎', '🔖', '💡', '⭐', '🎯', '🔑',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Save as Template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji picker
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _emojiOptions.map((e) {
                  final selected = _emoji == e;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                          child: Text(e, style: const TextStyle(fontSize: 20))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Study', child: Text('Study')),
                  DropdownMenuItem(value: 'Planning', child: Text('Planning')),
                  DropdownMenuItem(value: 'Creative', child: Text('Creative')),
                  DropdownMenuItem(
                      value: 'Productivity', child: Text('Productivity')),
                  DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Custom'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_nameController.text.isEmpty) return;
              final template = NoteTemplate(
                name: _nameController.text,
                description: _descController.text,
                category: _category,
                iconEmoji: _emoji,
                accentColor: Theme.of(context).colorScheme.primary,
                background: widget.currentConfig.template,
                isCustom: true,
              );
              widget.onSave(template);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      );
}
