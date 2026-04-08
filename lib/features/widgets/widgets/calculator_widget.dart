import 'dart:math';

import 'package:flutter/material.dart';
import 'package:biscuits/features/widgets/domain/entities/smart_widget.dart';

/// Full-featured calculator with history and memory operations.
class CalculatorWidget extends SmartWidget {
  CalculatorWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(220, 340),
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
                'lastAnswer': 0.0,
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

class _CalculatorOverlayState
    extends State<_CalculatorOverlay> {
  String _display = '0';
  double _mem = 0;
  double _storedMem = 0;
  String _op = '';
  bool _clear = false;
  String _expression = '';
  List<String> _history = [];
  double _lastAnswer = 0;
  bool _hasError = false;

  static const int _maxHistory = 20;

  @override
  void initState() {
    super.initState();
    final s = widget.widget.state;
    _display = s['display'] as String? ?? '0';
    _mem = (s['memory'] as num?)?.toDouble() ?? 0;
    _storedMem =
        (s['storedMemory'] as num?)?.toDouble() ?? 0;
    _lastAnswer =
        (s['lastAnswer'] as num?)?.toDouble() ?? 0;
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
      'lastAnswer': _lastAnswer,
    });
  }

  void _press(String key) {
    setState(() {
      _hasError = false;
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
        if (_op.isNotEmpty) {
          // Percentage of the first operand
          _display = _fmt(_mem * v / 100);
        } else {
          _display = _fmt(v / 100);
        }
      } else if (key == '√') {
        final v = double.tryParse(_display) ?? 0;
        if (v < 0) {
          _hasError = true;
          _display = 'Error';
        } else {
          final result = sqrt(v);
          _expression = '√${_fmt(v)}';
          _display = _fmt(result);
          _clear = true;
        }
      } else if (key == 'x²') {
        final v = double.tryParse(_display) ?? 0;
        final result = v * v;
        _expression = '${_fmt(v)}²';
        _display = _fmt(result);
        _clear = true;
      } else if (key == 'ANS') {
        _display = _fmt(_lastAnswer);
        _clear = true;
      } else if (key == '=') {
        final cur =
            double.tryParse(_display) ?? 0;
        final result = _calc(_mem, cur, _op);
        if (result.isInfinite || result.isNaN) {
          _hasError = true;
          _display = 'Error';
        } else {
          final entry =
              '${_fmt(_mem)} $_op ${_fmt(cur)}'
              ' = ${_fmt(result)}';
          _history.insert(0, entry);
          if (_history.length > _maxHistory) {
            _history =
                _history.sublist(0, _maxHistory);
          }
          _display = _fmt(result);
          _lastAnswer = result;
          _mem = result;
        }
        _expression = '';
        _op = '';
        _clear = true;
      } else if ('+-×÷'.contains(key)) {
        if (_hasError) return;
        // Chain operations: evaluate pending op
        if (_op.isNotEmpty && !_clear) {
          final cur =
              double.tryParse(_display) ?? 0;
          final result = _calc(_mem, cur, _op);
          _display = _fmt(result);
          _mem = result;
        } else {
          _mem = double.tryParse(_display) ?? 0;
        }
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
        if (_hasError) {
          _display = key;
          _hasError = false;
          _clear = false;
        } else if (_clear || _display == '0') {
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
        return b != 0 ? a / b : double.infinity;
      default:
        return b;
    }
  }

  String _fmt(double v) {
    if (v == v.roundToDouble() && !v.isInfinite) {
      return v.toInt().toString();
    }
    final s = v.toStringAsFixed(8);
    final dotIdx = s.indexOf('.');
    if (dotIdx == -1) return s;
    var end = s.length;
    while (end > dotIdx + 1 && s[end - 1] == '0') {
      end--;
    }
    if (end == dotIdx + 1) end = dotIdx;
    return s.substring(0, end);
  }

  void _clearHistory() {
    setState(() => _history.clear());
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['C', '±', '√', '÷'],
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _hasError
                      ? Colors.red
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Memory + last answer indicator
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 2,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  if (_lastAnswer != 0)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                      ),
                      child: GestureDetector(
                        onTap: () => _press('ANS'),
                        child: Text(
                          'ANS=${_fmt(_lastAnswer)}',
                          style: TextStyle(
                            fontSize: 9,
                            color:
                                Colors.green.shade400,
                          ),
                        ),
                      ),
                    ),
                  if (_storedMem != 0)
                    Text(
                      'M: ${_fmt(_storedMem)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade400,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Memory + extra ops row
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  'MC',
                  'MR',
                  'M-',
                  'M+',
                  'x²',
                  '%',
                ].map((k) {
                  return Expanded(
                    child: InkWell(
                      onTap: () => _press(k),
                      child: Center(
                        child: Text(
                          k,
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                Colors.blue.shade600,
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
                                    onTap: () =>
                                        k == '⌫'
                                            ? setState(
                                                () {
                                                _display = _display
                                                            .length >
                                                        1
                                                    ? _display
                                                        .substring(
                                                        0,
                                                        _display.length -
                                                            1,
                                                      )
                                                    : '0';
                                                _hasError =
                                                    false;
                                                _notify();
                                              })
                                            : _press(k),
                                    onLongPress:
                                        k == '⌫'
                                            ? () {
                                                setState(
                                                  () {
                                                  _display =
                                                      '0';
                                                  _hasError =
                                                      false;
                                                },
                                                );
                                                _notify();
                                              }
                                            : null,
                                    child: Center(
                                      child: Text(
                                        k,
                                        style:
                                            TextStyle(
                                          fontSize: 18,
                                          fontWeight: k ==
                                                  '='
                                              ? FontWeight
                                                  .bold
                                              : FontWeight
                                                  .w400,
                                          color: '÷×-+='
                                                  .contains(
                                            k,
                                          )
                                              ? Colors
                                                  .orange
                                              : k ==
                                                      'C'
                                                  ? Colors
                                                      .red
                                                  : k ==
                                                          '√'
                                                      ? Colors
                                                          .purple
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
            // History strip with clear
            if (_history.isNotEmpty)
              Container(
                height: 28,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        scrollDirection:
                            Axis.horizontal,
                        itemCount: _history.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, i) =>
                            Center(
                          child: Text(
                            _history[i],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors
                                  .grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearHistory,
                      child: Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
