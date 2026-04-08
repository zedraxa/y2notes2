import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

class ProgressBarWidget extends SmartWidget {
  ProgressBarWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(240, 120),
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.progressBar,
          config: config ??
              const {
                'label': 'Progress',
                'color': 0xFF4CAF50,
                'max': 100,
              },
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
  Widget buildInteractiveOverlay(
    BuildContext context, {
    required ValueChanged<Map<String, dynamic>> onStateChanged,
  }) =>
      _ProgressBarOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _ProgressBarOverlay extends StatefulWidget {
  const _ProgressBarOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final ProgressBarWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_ProgressBarOverlay> createState() =>
      _ProgressBarOverlayState();
}

class _ProgressBarOverlayState
    extends State<_ProgressBarOverlay>
    with SingleTickerProviderStateMixin {
  late double _value;
  bool _editingValue = false;
  final _valueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value = (widget.widget.state['value'] as num?)
            ?.toDouble() ??
        0;
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  double get _max =>
      (widget.widget.config['max'] as num?)
          ?.toDouble() ??
      100;

  void _update(double v) {
    setState(() => _value = v.clamp(0, _max));
    widget.onStateChanged({'value': _value});
  }

  @override
  Widget build(BuildContext context) {
    final barColor = Color(
      widget.widget.config['color'] as int? ??
          0xFF4CAF50,
    );
    final lbl =
        widget.widget.config['label'] as String? ??
            'Progress';
    final pct =
        _max > 0 ? (_value / _max * 100).round() : 0;
    final isComplete =
        _value >= _max && _max > 0;
    final fraction =
        _max > 0 ? _value / _max : 0.0;

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
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            // Header row
            Row(
              children: [
                if (isComplete)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text(
                      '✅',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                Text(
                  lbl,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Reset button
                if (_value > 0)
                  GestureDetector(
                    onTap: () => _update(0),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 6,
                      ),
                      child: Icon(
                        Icons.restart_alt,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                // Tappable percentage
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _editingValue = true;
                      _valueCtrl.text =
                          _value.round().toString();
                    });
                  },
                  child: _editingValue
                      ? SizedBox(
                          width: 50,
                          height: 20,
                          child: TextField(
                            controller: _valueCtrl,
                            autofocus: true,
                            keyboardType:
                                TextInputType.number,
                            style: const TextStyle(
                              fontSize: 12,
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
                                  double.tryParse(
                                    v,
                                  );
                              if (parsed != null) {
                                _update(parsed);
                              }
                              setState(
                                () => _editingValue =
                                    false,
                              );
                            },
                          ),
                        )
                      : Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w500,
                            color: isComplete
                                ? Colors.green
                                : null,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Progress bar with milestone markers
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    backgroundColor:
                        barColor.withOpacity(0.15),
                    color: isComplete
                        ? Colors.green
                        : barColor,
                    minHeight: 14,
                  ),
                ),
                // Milestone markers at 25%, 50%, 75%
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final w = constraints.maxWidth;
                      return Stack(
                        children: [
                          for (final m in [
                            0.25,
                            0.5,
                            0.75,
                          ])
                            Positioned(
                              left: w * m - 0.5,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 1,
                                color: fraction >= m
                                    ? Colors.white
                                        .withOpacity(
                                        0.5,
                                      )
                                    : Colors.grey
                                        .shade300,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Value label with milestone labels
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_value.round()} / ${_max.round()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (pct >= 25 && pct < 50)
                  Text(
                    '¼ done',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue.shade300,
                    ),
                  )
                else if (pct >= 50 && pct < 75)
                  Text(
                    'Halfway!',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue.shade400,
                    ),
                  )
                else if (pct >= 75 && pct < 100)
                  Text(
                    'Almost there!',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.orange.shade400,
                    ),
                  )
                else if (isComplete)
                  Text(
                    '🎉 Complete!',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.green.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Slider + buttons
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove,
                    size: 16,
                  ),
                  constraints:
                      const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      _update(_value - 1),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape:
                          const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                      activeTrackColor: barColor,
                      inactiveTrackColor:
                          barColor.withOpacity(0.2),
                      thumbColor: barColor,
                    ),
                    child: Slider(
                      value:
                          _value.clamp(0, _max),
                      max: _max,
                      onChanged: _update,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                  ),
                  constraints:
                      const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      _update(_value + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
