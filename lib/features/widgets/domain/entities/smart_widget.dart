import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Types of interactive smart widgets.
enum SmartWidgetType {
  checkboxList,
  timer,
  progressBar,
  counter,
  rating,
  datePicker,
  colorSwatch,
  stickyTimer,
  weather,
  linkCard,
  calculator,
  voiceNote,
}

/// Base class for all interactive canvas widgets.
abstract class SmartWidget extends Equatable {
  SmartWidget({
    String? id,
    required this.type,
    required this.position,
    required this.size,
    this.config = const {},
    this.state = const {},
  }) : id = id ?? const Uuid().v4();

  final String id;
  final SmartWidgetType type;
  final Offset position;
  final Size size;
  final Map<String, dynamic> config;
  final Map<String, dynamic> state;

  /// Human-readable label.
  String get label;

  /// Preview icon emoji.
  String get iconEmoji;

  /// Creates a copy with updated fields.
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  });

  /// Builds the interactive Flutter overlay for this widget.
  Widget buildInteractiveOverlay(BuildContext context,
      {required ValueChanged<Map<String, dynamic>> onStateChanged});

  /// Returns the [Rect] of this widget on the canvas.
  Rect get bounds => Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );

  @override
  List<Object?> get props => [id, type, position, size, config, state];
}
