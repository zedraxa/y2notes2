import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

/// Basic calculator widget — result can be inserted as text.
class CalculatorWidget extends SmartWidget {
  CalculatorWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(220, 300),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.calculator,
          state: state ?? const {'display': '0', 'memory': 0.0},
        );

  @override
  String get label => 'Calculator';
  @override
  String get iconEmoji => '🧮';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      CalculatorWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _CalculatorOverlay(onStateChanged: onStateChanged);
}

class _CalculatorOverlay extends StatefulWidget {
  const _CalculatorOverlay({required this.onStateChanged});
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_CalculatorOverlay> createState() => _CalculatorOverlayState();
}

class _CalculatorOverlayState extends State<_CalculatorOverlay> {
  String _display = '0';
  double _mem = 0;
  String _op = '';
  bool _clear = false;

  void _press(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0';
        _mem = 0;
        _op = '';
        _clear = false;
      } else if (key == '=') {
        final cur = double.tryParse(_display) ?? 0;
        final result = _calc(_mem, cur, _op);
        _display = _fmt(result);
        _mem = result;
        _op = '';
        _clear = true;
      } else if ('+-×÷'.contains(key)) {
        _mem = double.tryParse(_display) ?? 0;
        _op = key;
        _clear = true;
      } else if (key == '.') {
        if (_clear) {
          _display = '0.';
          _clear = false;
        } else if (!_display.contains('.')) {
          _display += '.';
        }
      } else {
        if (_clear || _display == '0') {
          _display = key;
          _clear = false;
        } else {
          _display += key;
        }
      }
    });
    widget.onStateChanged({'display': _display, 'memory': _mem});
  }

  double _calc(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b != 0 ? a / b : 0;
      default:
        return b;
    }
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['C', '±', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '⌫', '='],
    ];

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              alignment: Alignment.centerRight,
              child: Text(
                _display,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Column(
                children: rows
                    .map(
                      (row) => Expanded(
                        child: Row(
                          children: row
                              .map(
                                (k) => Expanded(
                                  child: InkWell(
                                    onTap: () => k == '⌫'
                                        ? setState(() {
                                            _display = _display.length > 1
                                                ? _display.substring(
                                                    0, _display.length - 1)
                                                : '0';
                                          })
                                        : _press(k),
                                    child: Center(
                                      child: Text(
                                        k,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: k == '='
                                              ? FontWeight.bold
                                              : FontWeight.w400,
                                          color: '÷×-+='.contains(k)
                                              ? Colors.orange
                                              : k == 'C'
                                                  ? Colors.red
                                                  : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
