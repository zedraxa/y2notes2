import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biscuitse/features/widgets/domain/entities/smart_widget.dart';

class ColorSwatchWidget extends SmartWidget {
  ColorSwatchWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(200, 60),
    Map<String, dynamic>? config,
    super.state,
  }) : super(
          type: SmartWidgetType.colorSwatch,
          config: config ??
              const {
                'colors': [
                  0xFFFF6B6B, 0xFFFFA502, 0xFF2ECC71,
                  0xFF0984E3, 0xFF6C5CE7, 0xFFE84393,
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
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _ColorSwatchOverlay(widget: this);
}

class _ColorSwatchOverlay extends StatelessWidget {
  const _ColorSwatchOverlay({required this.widget});
  final ColorSwatchWidget widget;

  @override
  Widget build(BuildContext context) {
    final colors = (widget.config['colors'] as List?)
            ?.map((c) => Color(c as int))
            .toList() ??
        [];

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: colors.map((c) {
            final hex = '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: hex));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied $hex'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Tooltip(
                  message: hex,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
