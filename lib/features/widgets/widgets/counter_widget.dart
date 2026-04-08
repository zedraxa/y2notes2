import 'package:flutter/material.dart';
import 'package:biscuits/features/widgets/domain/entities/smart_widget.dart';

class CounterWidget extends SmartWidget {
  CounterWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(180, 180),
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.counter,
          config: config ??
              const {
                'step': 1,
                'label': 'Counter',
                'min': -999999,
                'max': 999999,
                'target': 0,
              },
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
  Widget buildInteractiveOverlay(
    BuildContext context, {
    required ValueChanged<Map<String, dynamic>> onStateChanged,
  }) =>
      _CounterOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _CounterOverlay extends StatefulWidget {
  const _CounterOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final CounterWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_CounterOverlay> createState() =>
      _CounterOverlayState();
}

class _CounterOverlayState extends State<_CounterOverlay> {
  late int _count;
  bool _editingStep = false;
  final _stepCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _count =
        widget.widget.state['count'] as int? ?? 0;
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    super.dispose();
  }

  int get _step =>
      widget.widget.config['step'] as int? ?? 1;
  int get _min =>
      widget.widget.config['min'] as int? ?? -999999;
  int get _max =>
      widget.widget.config['max'] as int? ?? 999999;
  int get _target =>
      widget.widget.config['target'] as int? ?? 0;
  bool get _hasTarget => _target != 0;

  void _update(int value) {
    setState(() => _count = value.clamp(_min, _max));
    widget.onStateChanged({'count': _count});
  }

  @override
  Widget build(BuildContext context) {
    final atTarget = _hasTarget && _count >= _target;
    final targetProgress = _hasTarget && _target != 0
        ? (_count / _target).clamp(0.0, 1.0)
        : 0.0;

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
            // Label
            Text(
              widget.widget.config['label']
                      as String? ??
                  'Counter',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            // Count display with optional ring
            if (_hasTarget)
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: targetProgress,
                      strokeWidth: 4,
                      backgroundColor:
                          Colors.grey.shade200,
                      color: atTarget
                          ? Colors.green
                          : Colors.blue,
                    ),
                    Center(
                      child: Text(
                        '$_count',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: atTarget
                              ? Colors.green
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                '$_count',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            // Target indicator
            if (_hasTarget)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  atTarget
                      ? '🎯 Target reached!'
                      : 'Target: $_target',
                  style: TextStyle(
                    fontSize: 10,
                    color: atTarget
                        ? Colors.green
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            // Controls
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: _count > _min
                      ? () => _update(_count - _step)
                      : null,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 8),
                // Reset button
                GestureDetector(
                  onTap: () => _update(0),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                    ),
                    child: Icon(
                      Icons.restart_alt,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: _count < _max
                      ? () => _update(_count + _step)
                      : null,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Step size indicator
            GestureDetector(
              onTap: () {
                setState(() {
                  _editingStep = true;
                  _stepCtrl.text = '$_step';
                });
              },
              child: _editingStep
                  ? SizedBox(
                      width: 60,
                      height: 20,
                      child: TextField(
                        controller: _stepCtrl,
                        autofocus: true,
                        keyboardType:
                            TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                        decoration:
                            const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        onSubmitted: (v) {
                          final parsed =
                              int.tryParse(v);
                          if (parsed != null &&
                              parsed > 0) {
                            widget.onStateChanged({
                              'count': _count,
                              '_config_step': parsed,
                            });
                          }
                          setState(
                            () =>
                                _editingStep = false,
                          );
                        },
                      ),
                    )
                  : Text(
                      'Step: $_step',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
