import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'graph_function.dart';
import 'math_variable.dart';
import 'matrix_data.dart';

/// Represents an interactive math graph placed on the canvas.
///
/// Contains one or more [GraphFunction]s, user-defined [MathVariable]s,
/// optional [MatrixData] entries, and the viewport/axis configuration.
class GraphElement extends Equatable {
  const GraphElement({
    required this.id,
    required this.bounds,
    this.functions = const [],
    this.variables = const [],
    this.matrices = const [],
    this.xMin = -10.0,
    this.xMax = 10.0,
    this.yMin = -10.0,
    this.yMax = 10.0,
    this.showGrid = true,
    this.showAxes = true,
    this.showLabels = true,
    this.gridColor = const Color(0xFFE0E0E0),
    this.axisColor = const Color(0xFF424242),
    this.backgroundColor = Colors.white,
    this.title,
  });

  /// Create a new graph with a generated UUID and default viewport.
  factory GraphElement.create({
    required Rect bounds,
    List<GraphFunction> functions = const [],
    List<MathVariable> variables = const [],
    String? title,
  }) =>
      GraphElement(
        id: const Uuid().v4(),
        bounds: bounds,
        functions: functions,
        variables: variables,
        title: title,
      );

  final String id;

  /// Position and size on the canvas.
  final Rect bounds;

  /// Functions to plot.
  final List<GraphFunction> functions;

  /// User-defined variables.
  final List<MathVariable> variables;

  /// Matrices for linear algebra display.
  final List<MatrixData> matrices;

  // ── Axis / viewport configuration ─────────────────────────────────────────

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  final bool showGrid;
  final bool showAxes;
  final bool showLabels;
  final Color gridColor;
  final Color axisColor;
  final Color backgroundColor;

  /// Optional title displayed above the graph.
  final String? title;

  // ── Derived ──────────────────────────────────────────────────────────────

  double get xRange => xMax - xMin;
  double get yRange => yMax - yMin;
  Offset get center => bounds.center;

  /// Resolve variables into a lookup map.
  Map<String, double> get variableMap =>
      {for (final v in variables) v.name: v.value};

  GraphElement copyWith({
    Rect? bounds,
    List<GraphFunction>? functions,
    List<MathVariable>? variables,
    List<MatrixData>? matrices,
    double? xMin,
    double? xMax,
    double? yMin,
    double? yMax,
    bool? showGrid,
    bool? showAxes,
    bool? showLabels,
    Color? gridColor,
    Color? axisColor,
    Color? backgroundColor,
    String? title,
    bool clearTitle = false,
  }) =>
      GraphElement(
        id: id,
        bounds: bounds ?? this.bounds,
        functions: functions ?? this.functions,
        variables: variables ?? this.variables,
        matrices: matrices ?? this.matrices,
        xMin: xMin ?? this.xMin,
        xMax: xMax ?? this.xMax,
        yMin: yMin ?? this.yMin,
        yMax: yMax ?? this.yMax,
        showGrid: showGrid ?? this.showGrid,
        showAxes: showAxes ?? this.showAxes,
        showLabels: showLabels ?? this.showLabels,
        gridColor: gridColor ?? this.gridColor,
        axisColor: axisColor ?? this.axisColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        title: clearTitle ? null : (title ?? this.title),
      );

  @override
  List<Object?> get props => [
        id,
        bounds,
        functions,
        variables,
        matrices,
        xMin,
        xMax,
        yMin,
        yMax,
        showGrid,
        showAxes,
        showLabels,
        gridColor,
        axisColor,
        backgroundColor,
        title,
      ];
}
