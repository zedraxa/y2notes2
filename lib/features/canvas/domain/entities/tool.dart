import 'package:equatable/equatable.dart';

/// Available drawing tools.
enum StrokeTool {
  fountainPen,
  ballpoint,
  highlighter,
  eraser,
}

/// Descriptor for the active drawing tool.
class Tool extends Equatable {
  const Tool({
    required this.type,
    required this.color,
    required this.baseWidth,
    this.opacity = 1.0,
  });

  final StrokeTool type;
  final int color; // Stored as ARGB int for equatable simplicity
  final double baseWidth;
  final double opacity;

  static const Tool defaultFountainPen = Tool(
    type: StrokeTool.fountainPen,
    color: 0xFF2D2D2D,
    baseWidth: 3.0,
  );

  static const Tool defaultBallpoint = Tool(
    type: StrokeTool.ballpoint,
    color: 0xFF2D2D2D,
    baseWidth: 2.0,
  );

  static const Tool defaultHighlighter = Tool(
    type: StrokeTool.highlighter,
    color: 0xCCFFEB3B,
    baseWidth: 20.0,
    opacity: 0.5,
  );

  static const Tool defaultEraser = Tool(
    type: StrokeTool.eraser,
    color: 0xFFFFFFFF,
    baseWidth: 25.0,
  );

  Tool copyWith({
    StrokeTool? type,
    int? color,
    double? baseWidth,
    double? opacity,
  }) =>
      Tool(
        type: type ?? this.type,
        color: color ?? this.color,
        baseWidth: baseWidth ?? this.baseWidth,
        opacity: opacity ?? this.opacity,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'color': color,
        'baseWidth': baseWidth,
        'opacity': opacity,
      };

  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
        type: StrokeTool.values.byName(json['type'] as String),
        color: json['color'] as int,
        baseWidth: (json['baseWidth'] as num).toDouble(),
        opacity: (json['opacity'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [type, color, baseWidth, opacity];
}
