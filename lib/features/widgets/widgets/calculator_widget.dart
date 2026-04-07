import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

/// Full-featured calculator with history and memory operations.
class CalculatorWidget extends SmartWidget {
  CalculatorWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(220, 320),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.calculator,
          state: state ??
              const {
                'display': '0',
                'memory': 0.0,
                'storedMemory': 0.0,
                'history': <String>[],
              },
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
  Widget buildInteractiveOverlay(
    BuildContext context, {
    required ValueChanged<Map<String, dynamic>> onStateChanged,
  }) =>
      _CalculatorOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _CalculatorOverlay extends StatefulWidget {
  const _CalculatorOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final CalculatorWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_CalculatorOverlay> createState() =>
      _CalculatorOverlayState();
}

class _CalculatorOverlayState extends State<_CalculatorOverlay> {
  String _display = '0';
  double _mem = 0;
  double _storedMem = 0;
  String _op = '';
  bool _clear = false;
  String _expression = '';
  List<String> _history = [];

  static const int _maxHistory = 10;

  @override
  void initState() {
    super.initState();
    final s = widget.widget.state;
    _display = s['display'] as String? ?? '0';
    _mem = (s['memory'] as num?)?.toDouble() ?? 0;
    _storedMem = (s['storedMemory'] as num?)?.toDouble() ?? 0;
    final rawHist = s['history'] as List?;
    _history = rawHist
            ?.map((e) => e.toString())
            .toList() ??
        [];
  }

  void _notify() {
    widget.onStateChanged({
      'display': _display,
      'memory': _mem,
      'storedMemory': _storedMem,
      'history': _history,
    });
  }

  void _press(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0';
        _mem = 0;
        _op = '';
        _clear = false;
        _expression = '';
      } else if (key == '±') {
        final v = double.tryParse(_display) ?? 0;
        _display = _fmt(-v);
      } else if (key == '%') {
        final v = double.tryParse(_display) ?? 0;
        _display = _fmt(v / 100);
      } else if (key == '=') {
        final cur = double.tryParse(_display) ?? 0;
        final result = _calc(_mem, cur, _op);
        final entry =
            '${_fmt(_mem)} $_op ${_fmt(cur)} = ${_fmt(result)}';
        _history.insert(0, entry);
        if (_history.length > _maxHistory) {
          _history = _history.sublist(0, _maxHistory);
        }
        _display = _fmt(result);
        _expression = '';
        _mem = result;
        _op = '';
        _clear = true;
      } else if ('+-×÷'.contains(key)) {
        _mem = double.tryParse(_display) ?? 0;
        _expression = '${_fmt(_mem)} $key';
        _op = key;
        _clear = true;
      } else if (key == '.') {
        if (_clear) {
          _display = '0.';
          _clear = false;
        } else if (!_display.contains('.')) {
          _display += '.';
        }
      } else if (key == 'M+') {
        _storedMem +=
            double.tryParse(_display) ?? 0;
      } else if (key == 'M-') {
        _storedMem -=
            double.tryParse(_display) ?? 0;
      } else if (key == 'MR') {
        _display = _fmt(_storedMem);
        _clear = true;
      } else if (key == 'MC') {
        _storedMem = 0;
      } else {
        if (_clear || _display == '0') {
          _display = key;
          _clear = false;
        } else {
          _display += key;
        }
      }
    });
    _notify();
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
    if (v == v.roundToDouble()) {
      return v.toInt().toString();
    }
    final s = v.toStringAsFixed(6);
    final dotIdx = s.indexOf('.');
    if (dotIdx == -1) return s;
    var end = s.length;
    while (end > dotIdx + 1 && s[end - 1] == '0') {
      end--;
    }
    if (end == dotIdx + 1) end = dotIdx;
    return s.substring(0, end);
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
            // Expression preview
            if (_expression.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 4,
                ),
                alignment: Alignment.centerRight,
                child: Text(
                  _expression,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              alignment: Alignment.centerRight,
              child: Text(
                _display,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Memory indicator
            if (_storedMem != 0)
              Padding(
                padding: const EdgeInsets.only(
                  right: 12,
                  bottom: 2,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'M: ${_fmt(_storedMem)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade400,
                    ),
                  ),
                ),
              ),
            const Divider(height: 1),
            // Memory row
            SizedBox(
              height: 28,
              child: Row(
                children: ['MC', 'MR', 'M-', 'M+'].map((k) {
                  return Expanded(
                    child: InkWell(
                      onTap: () => _press(k),
                      child: Center(
                        child: Text(
                          k,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            // Main keypad
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
                                            _display =
                                                _display.length > 1
                                                    ? _display.substring(
                                                        0,
                                                        _display.length -
                                                            1,
                                                      )
                                                    : '0';
                                            _notify();
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
                                          color:
                                              '÷×-+='.contains(k)
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
            // History strip
            if (_history.isNotEmpty)
              Container(
                height: 28,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _history.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 12),
                  itemBuilder: (_, i) => Center(
                    child: Text(
                      _history[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
