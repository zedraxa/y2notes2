import 'package:flutter/material.dart';
import 'package:biscuitse/features/widgets/domain/entities/smart_widget.dart';

class RatingWidget extends SmartWidget {
  RatingWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(200, 80),
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.rating,
          config: config ?? const {'maxStars': 5, 'useEmoji': false},
          state: state ?? const {'rating': 0},
        );

  @override
  String get label => 'Rating';
  @override
  String get iconEmoji => '⭐';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      RatingWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _RatingOverlay(widget: this, onStateChanged: onStateChanged);
}

class _RatingOverlay extends StatefulWidget {
  const _RatingOverlay(
      {required this.widget, required this.onStateChanged});
  final RatingWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_RatingOverlay> createState() => _RatingOverlayState();
}

class _RatingOverlayState extends State<_RatingOverlay> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.widget.state['rating'] as int? ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final maxStars = widget.widget.config['maxStars'] as int? ?? 5;
    final useEmoji = widget.widget.config['useEmoji'] as bool? ?? false;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(maxStars, (i) {
            final filled = i < _rating;
            return GestureDetector(
              onTap: () {
                setState(() => _rating = i + 1);
                widget.onStateChanged({'rating': _rating});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: useEmoji
                    ? Text(
                        filled ? '😍' : '😶',
                        style: const TextStyle(fontSize: 28),
                      )
                    : Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: filled ? Colors.amber : Colors.grey.shade400,
                        size: 32,
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
