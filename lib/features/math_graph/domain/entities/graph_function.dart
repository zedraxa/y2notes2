import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../models/graph_style.dart';
import '../models/graph_type.dart';

/// A single mathematical function to be plotted on a graph.
///
/// Stores the expression string and computed plot points.
class GraphFunction extends Equatable {
  const GraphFunction({
    required this.id,
    required this.expression,
    this.type = GraphType.line,
    this.style = const GraphStyle(),
    this.isVisible = true,
    this.label,
    this.plotPoints = const [],
    this.errorMessage,
  });

  factory GraphFunction.create({
    required String expression,
    GraphType type = GraphType.line,
    GraphStyle style = const GraphStyle(),
    String? label,
  }) =>
      GraphFunction(
        id: const Uuid().v4(),
        expression: expression,
        type: type,
        style: style,
        label: label,
      );

  final String id;

  /// The raw expression string, e.g. "2*x + 1", "sin(x)", "x^2".
  final String expression;

  final GraphType type;
  final GraphStyle style;
  final bool isVisible;

  /// Optional display label for the function legend.
  final String? label;

  /// Pre-computed plot points in graph coordinate space.
  /// Each element is an (x, y) pair.
  final List<(double, double)> plotPoints;

  /// Error message if the expression failed to parse or evaluate.
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  GraphFunction copyWith({
    String? expression,
    GraphType? type,
    GraphStyle? style,
    bool? isVisible,
    String? label,
    bool clearLabel = false,
    List<(double, double)>? plotPoints,
    String? errorMessage,
    bool clearError = false,
  }) =>
      GraphFunction(
        id: id,
        expression: expression ?? this.expression,
        type: type ?? this.type,
        style: style ?? this.style,
        isVisible: isVisible ?? this.isVisible,
        label: clearLabel ? null : (label ?? this.label),
        plotPoints: plotPoints ?? this.plotPoints,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        id,
        expression,
        type,
        style,
        isVisible,
        label,
        plotPoints,
        errorMessage,
      ];
}
