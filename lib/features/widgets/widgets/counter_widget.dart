import 'package:flutter/material.dart';
import 'package:biscuitse/features/widgets/domain/entities/smart_widget.dart';

class CounterWidget extends SmartWidget {
  CounterWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(160, 140),
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.counter,
          config: config ?? const {'step': 1, 'label': 'Counter'},
          state: state ?? const {'count': 0},
        );

  @override
  String get label => 'Counter';
  @override
  String get iconEmoji => '🔢';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      CounterWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _CounterOverlay(widget: this, onStateChanged: onStateChanged);
}

class _CounterOverlay extends StatefulWidget {
  const _CounterOverlay(
      {required this.widget, required this.onStateChanged});
  final CounterWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_CounterOverlay> createState() => _CounterOverlayState();
}

class _CounterOverlayState extends State<_CounterOverlay> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.widget.state['count'] as int? ?? 0;
  }

  int get _step => widget.widget.config['step'] as int? ?? 1;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.widget.config['label'] as String? ?? 'Counter',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '$_count',
                style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: () {
                      setState(() => _count -= _step);
                      widget.onStateChanged({'count': _count});
                    },
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: () {
                      setState(() => _count += _step);
                      widget.onStateChanged({'count': _count});
                    },
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
