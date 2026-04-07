import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

class ColorSwatchWidget extends SmartWidget {
  ColorSwatchWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(220, 110),
    Map<String, dynamic>? config,
    super.state,
  }) : super(
          type: SmartWidgetType.colorSwatch,
          config: config ??
              const {
                'colors': [
                  0xFFFF6B6B,
                  0xFFFFA502,
                  0xFF2ECC71,
                  0xFF0984E3,
                  0xFF6C5CE7,
                  0xFFE84393,
                ],
              },
        );

  @override
  String get label => 'Color Swatch';
  @override
  String get iconEmoji => '🎨';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      ColorSwatchWidget(
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
      _ColorSwatchOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _ColorSwatchOverlay extends StatefulWidget {
  const _ColorSwatchOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final ColorSwatchWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_ColorSwatchOverlay> createState() =>
      _ColorSwatchOverlayState();
}

class _ColorSwatchOverlayState
    extends State<_ColorSwatchOverlay> {
  late List<int> _colors;
  int? _selectedIndex;
  bool _showPicker = false;
  double _hue = 0;
  double _saturation = 0.7;
  double _lightness = 0.5;

  @override
  void initState() {
    super.initState();
    final raw =
        widget.widget.config['colors'] as List?;
    _colors = raw?.map((c) => c as int).toList() ??
        [];
  }

  String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  void _notifyConfig() {
    widget.onStateChanged({'_config_colors': _colors});
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        _colors.map((c) => Color(c)).toList();
    final pickerColor = HSLColor.fromAHSL(
      1,
      _hue,
      _saturation,
      _lightness,
    ).toColor();

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color circles row
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                ...colors.asMap().entries.map(
                  (entry) {
                    final i = entry.key;
                    final c = entry.value;
                    final hex = _hex(c);
                    final isSelected =
                        _selectedIndex == i;
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: hex),
                          );
                          setState(
                            () => _selectedIndex = i,
                          );
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content:
                                  Text('Copied $hex'),
                              duration: const Duration(
                                seconds: 1,
                              ),
                            ),
                          );
                        },
                        onLongPress: () {
                          if (_colors.length > 1) {
                            setState(() {
                              _colors.removeAt(i);
                              _selectedIndex = null;
                            });
                            _notifyConfig();
                          }
                        },
                        child: Tooltip(
                          message: hex,
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 200,
                            ),
                            width: isSelected ? 32 : 28,
                            height:
                                isSelected ? 32 : 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black54
                                    : Colors.black12,
                                width: isSelected
                                    ? 2
                                    : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: c
                                            .withOpacity(
                                          0.4,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Add button
                if (_colors.length < 10)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _showPicker = !_showPicker,
                      ),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Selected hex display
            if (_selectedIndex != null &&
                _selectedIndex! < colors.length)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _hex(colors[_selectedIndex!]),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            // Color picker
            if (_showPicker) ...[
              const SizedBox(height: 6),
              // Hue slider
              Row(
                children: [
                  Text(
                    'H',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        thumbShape:
                            const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape:
                            const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                        activeTrackColor:
                            pickerColor,
                        inactiveTrackColor:
                            Colors.grey.shade200,
                      ),
                      child: Slider(
                        value: _hue,
                        max: 360,
                        onChanged: (v) =>
                            setState(() => _hue = v),
                      ),
                    ),
                  ),
                ],
              ),
              // Preview + add
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: pickerColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hex(pickerColor),
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _colors
                            .add(pickerColor.toARGB32());
                        _showPicker = false;
                      });
                      _notifyConfig();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
