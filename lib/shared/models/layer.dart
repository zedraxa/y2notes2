import 'package:equatable/equatable.dart';

/// Layer type identifiers for future multi-layer canvas support.
enum LayerType {
  strokes,
  stickers,
  shapes,
  textBoxes,
  images,
  widgets,
}

/// Abstract canvas layer model.
///
/// All canvas object types (strokes, stickers, shapes, widgets) will extend
/// this in future PRs. Defined here so the architecture is established.
abstract class Layer extends Equatable {
  const Layer({
    required this.id,
    required this.type,
    required this.isVisible,
    required this.isLocked,
    required this.opacity,
    required this.name,
  });

  final String id;
  final LayerType type;
  final bool isVisible;
  final bool isLocked;
  final double opacity;
  final String name;

  Layer copyWithBase({
    bool? isVisible,
    bool? isLocked,
    double? opacity,
    String? name,
  });

  @override
  List<Object?> get props =>
      [id, type, isVisible, isLocked, opacity, name];
}
