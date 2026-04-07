import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

/// Weather widget with stub data, ready for API integration.
class WeatherWidget extends SmartWidget {
  WeatherWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(180, 120),
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.weather,
          config: config ?? const {'location': 'Istanbul', 'unit': 'C'},
          state: state ?? const {'temp': 22, 'condition': 'Sunny', 'icon': '☀️'},
        );

  @override
  String get label => 'Weather';
  @override
  String get iconEmoji => '🌤️';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      WeatherWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _WeatherOverlay(widget: this);
}

class _WeatherOverlay extends StatelessWidget {
  const _WeatherOverlay({required this.widget});
  final WeatherWidget widget;

  @override
  Widget build(BuildContext context) {
    final loc = widget.config['location'] as String? ?? 'Unknown';
    final unit = widget.config['unit'] as String? ?? 'C';
    final temp = widget.state['temp'] as int? ?? 0;
    final condition = widget.state['condition'] as String? ?? '';
    final icon = widget.state['icon'] as String? ?? '🌤️';

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
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text('$temp°$unit',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text(condition, style: const TextStyle(fontSize: 12)),
            Text(loc,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
