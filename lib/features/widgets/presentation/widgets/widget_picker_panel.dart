import 'package:flutter/material.dart';
import 'package:biscuits/features/widgets/data/builtin_widgets.dart';
import 'package:biscuits/features/widgets/domain/entities/smart_widget.dart';

/// Bottom sheet that shows available smart widgets for adding to canvas.
class WidgetPickerPanel extends StatelessWidget {
  const WidgetPickerPanel({super.key, required this.onSelected});

  final void Function(SmartWidget widget) onSelected;

  @override
  Widget build(BuildContext context) {
    final prototypes = BuiltinWidgets.all();
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Smart Widgets',
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: prototypes.length,
              itemBuilder: (context, i) {
                final proto = prototypes[i];
                return _WidgetCard(
                  proto: proto,
                  onTap: () {
                    // Create a positioned copy for placement.
                    final placed = proto.copyWith(
                      position: const Offset(200, 200),
                    );
                    Navigator.of(context).pop();
                    onSelected(placed);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetCard extends StatefulWidget {
  const _WidgetCard({required this.proto, required this.onTap});

  final SmartWidget proto;
  final VoidCallback onTap;

  @override
  State<_WidgetCard> createState() => _WidgetCardState();
}

class _WidgetCardState extends State<_WidgetCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: _pressed
            ? (Matrix4.identity()..scale(0.95))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.04 : 0.08),
              blurRadius: _pressed ? 2 : 6,
              offset: Offset(0, _pressed ? 1 : 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.proto.iconEmoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              widget.proto.label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
