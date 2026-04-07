import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

class ProgressBarWidget extends SmartWidget {
  ProgressBarWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(220, 100),
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.progressBar,
          config: config ??
              const {'label': 'Progress', 'color': 0xFF4CAF50, 'max': 100},
          state: state ?? const {'value': 0},
        );

  @override
  String get label => 'Progress Bar';
  @override
  String get iconEmoji => '📊';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      ProgressBarWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _ProgressBarOverlay(widget: this, onStateChanged: onStateChanged);
}

class _ProgressBarOverlay extends StatefulWidget {
  const _ProgressBarOverlay(
      {required this.widget, required this.onStateChanged});
  final ProgressBarWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_ProgressBarOverlay> createState() => _ProgressBarOverlayState();
}

class _ProgressBarOverlayState extends State<_ProgressBarOverlay> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = (widget.widget.state['value'] as num?)?.toDouble() ?? 0;
  }

  double get _max =>
      (widget.widget.config['max'] as num?)?.toDouble() ?? 100;

  @override
  Widget build(BuildContext context) {
    final barColor =
        Color(widget.widget.config['color'] as int? ?? 0xFF4CAF50);
    final lbl = widget.widget.config['label'] as String? ?? 'Progress';
    final pct = _max > 0 ? (_value / _max * 100).round() : 0;

    return Material(
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
            Row(
              children: [
                Text(lbl,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('$pct%', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _max > 0 ? _value / _max : 0,
                backgroundColor: barColor.withOpacity(0.15),
                color: barColor,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () {
                    setState(() => _value = (_value - 1).clamp(0, _max));
                    widget.onStateChanged({'value': _value});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    setState(() => _value = (_value + 1).clamp(0, _max));
                    widget.onStateChanged({'value': _value});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
