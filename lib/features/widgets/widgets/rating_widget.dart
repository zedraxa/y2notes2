import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

class RatingWidget extends SmartWidget {
  RatingWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(220, 100),
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.rating,
          config: config ??
              const {
                'maxStars': 5,
                'useEmoji': false,
                'allowHalf': true,
              },
          state: state ??
              const {
                'rating': 0.0,
                'label': '',
              },
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
  Widget buildInteractiveOverlay(
    BuildContext context, {
    required ValueChanged<Map<String, dynamic>> onStateChanged,
  }) =>
      _RatingOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _RatingOverlay extends StatefulWidget {
  const _RatingOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final RatingWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_RatingOverlay> createState() =>
      _RatingOverlayState();
}

class _RatingOverlayState
    extends State<_RatingOverlay> {
  late double _rating;
  late String _label;
  bool _editingLabel = false;
  final _labelCtrl = TextEditingController();

  static const _descriptions = [
    '',
    'Poor',
    'Fair',
    'Good',
    'Very Good',
    'Excellent',
  ];

  @override
  void initState() {
    super.initState();
    _rating = (widget.widget.state['rating'] as num?)
            ?.toDouble() ??
        0.0;
    _label =
        widget.widget.state['label'] as String? ?? '';
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  int get _maxStars =>
      widget.widget.config['maxStars'] as int? ?? 5;
  bool get _useEmoji =>
      widget.widget.config['useEmoji'] as bool? ??
      false;
  bool get _allowHalf =>
      widget.widget.config['allowHalf'] as bool? ??
      true;

  void _notify() {
    widget.onStateChanged({
      'rating': _rating,
      'label': _label,
    });
  }

  String get _ratingText {
    if (_rating == 0) return 'Tap to rate';
    if (_rating == _rating.roundToDouble()) {
      return '${_rating.toInt()}/$_maxStars';
    }
    return '${_rating.toStringAsFixed(1)}/$_maxStars';
  }

  String get _ratingDescription {
    if (_rating == 0) return '';
    final idx = _rating.ceil().clamp(0, 5);
    return _descriptions[idx];
  }

  @override
  Widget build(BuildContext context) => Material(
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
              // Stars row
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: List.generate(
                  _maxStars,
                  (i) => _buildStar(i),
                ),
              ),
              const SizedBox(height: 4),
              // Rating text + description
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    _ratingText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _rating > 0
                          ? Colors.amber.shade700
                          : Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_ratingDescription
                      .isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '· $_ratingDescription',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Colors.grey.shade500,
                      ),
                    ),
                  ],
                  if (_rating > 0) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(
                          () => _rating = 0,
                        );
                        _notify();
                      },
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color:
                            Colors.grey.shade400,
                      ),
                    ),
                  ],
                ],
              ),
              // Editable label
              const SizedBox(height: 4),
              if (_editingLabel)
                SizedBox(
                  height: 22,
                  width: 160,
                  child: TextField(
                    controller: _labelCtrl,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                    decoration:
                        const InputDecoration(
                      isDense: true,
                      hintText: 'Add a label...',
                      contentPadding:
                          EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                    onSubmitted: (v) {
                      setState(() {
                        _label = v;
                        _editingLabel = false;
                      });
                      _notify();
                    },
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _editingLabel = true;
                      _labelCtrl.text = _label;
                    });
                  },
                  child: Text(
                    _label.isEmpty
                        ? 'Tap to add label'
                        : _label,
                    style: TextStyle(
                      fontSize: 11,
                      color: _label.isEmpty
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontStyle: _label.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildStar(int index) {
    final starValue = index + 1.0;
    final halfValue = index + 0.5;

    if (_useEmoji) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _rating = _rating == starValue
                ? (_allowHalf ? halfValue : 0)
                : starValue;
          });
          _notify();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
          ),
          child: Text(
            _rating >= starValue
                ? '😍'
                : _rating >= halfValue
                    ? '🙂'
                    : '😶',
            style: const TextStyle(fontSize: 28),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_rating == starValue && _allowHalf) {
            _rating = halfValue;
          } else if (_rating == halfValue) {
            _rating = 0;
          } else {
            _rating = starValue;
          }
        });
        _notify();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
        ),
        child: _rating >= starValue
            ? Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 32,
              )
            : _rating >= halfValue
                ? Icon(
                    Icons.star_half_rounded,
                    color: Colors.amber,
                    size: 32,
                  )
                : Icon(
                    Icons.star_border_rounded,
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
      ),
    );
  }
}
