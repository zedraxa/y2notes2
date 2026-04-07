import 'package:flutter/material.dart';
import 'package:biscuitse/features/widgets/data/builtin_widgets.dart';
import 'package:biscuitse/features/widgets/domain/entities/smart_widget.dart';

/// Bottom sheet that shows available smart widgets for adding to canvas.
class WidgetPickerPanel extends StatelessWidget {
  const WidgetPickerPanel({super.key, required this.onSelected});

  final void Function(SmartWidget widget) onSelected;

  @override
  Widget build(BuildContext context) {
    final prototypes = BuiltinWidgets.all();

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
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Smart Widgets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

class _WidgetCard extends StatelessWidget {
  const _WidgetCard({required this.proto, required this.onTap});

  final SmartWidget proto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(proto.iconEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                proto.label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
