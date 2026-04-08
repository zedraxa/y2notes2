import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/graph_function.dart';
import '../../domain/entities/math_variable.dart';
import '../../domain/entities/matrix_data.dart';
import '../../domain/models/graph_style.dart';
import '../../domain/models/graph_type.dart';

/// Base class for all graph-related events.
abstract class GraphEvent extends Equatable {
  const GraphEvent();
  @override
  List<Object?> get props => [];
}

// ─── Graph element lifecycle ──────────────────────────────────────────────────

/// Create a new graph element on the canvas.
class GraphCreated extends GraphEvent {
  const GraphCreated({required this.bounds, this.title});
  final Rect bounds;
  final String? title;
  @override
  List<Object?> get props => [bounds, title];
}

/// Select a graph for editing.
class GraphSelected extends GraphEvent {
  const GraphSelected(this.graphId);
  final String graphId;
  @override
  List<Object?> get props => [graphId];
}

/// Deselect the active graph.
class GraphDeselected extends GraphEvent {
  const GraphDeselected();
}

/// Delete the selected graph.
class GraphDeleteRequested extends GraphEvent {
  const GraphDeleteRequested();
}

/// Move/resize the selected graph.
class GraphBoundsChanged extends GraphEvent {
  const GraphBoundsChanged(this.bounds);
  final Rect bounds;
  @override
  List<Object?> get props => [bounds];
}

// ─── Viewport / axis ──────────────────────────────────────────────────────────

/// Pan/zoom the graph viewport.
class GraphViewportChanged extends GraphEvent {
  const GraphViewportChanged({
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
  });
  final double? xMin;
  final double? xMax;
  final double? yMin;
  final double? yMax;
  @override
  List<Object?> get props => [xMin, xMax, yMin, yMax];
}

/// Toggle grid visibility.
class GraphGridToggled extends GraphEvent {
  const GraphGridToggled({required this.visible});
  final bool visible;
  @override
  List<Object?> get props => [visible];
}

// ─── Function management ──────────────────────────────────────────────────────

/// Add a new function to the selected graph.
class FunctionAdded extends GraphEvent {
  const FunctionAdded({
    required this.expression,
    this.type = GraphType.line,
    this.style = const GraphStyle(),
    this.label,
  });
  final String expression;
  final GraphType type;
  final GraphStyle style;
  final String? label;
  @override
  List<Object?> get props => [expression, type, style, label];
}

/// Update an existing function's expression.
class FunctionExpressionChanged extends GraphEvent {
  const FunctionExpressionChanged({
    required this.functionId,
    required this.expression,
  });
  final String functionId;
  final String expression;
  @override
  List<Object?> get props => [functionId, expression];
}

/// Update a function's visual style.
class FunctionStyleChanged extends GraphEvent {
  const FunctionStyleChanged({
    required this.functionId,
    required this.style,
  });
  final String functionId;
  final GraphStyle style;
  @override
  List<Object?> get props => [functionId, style];
}

/// Toggle a function's visibility.
class FunctionVisibilityToggled extends GraphEvent {
  const FunctionVisibilityToggled(this.functionId);
  final String functionId;
  @override
  List<Object?> get props => [functionId];
}

/// Remove a function from the selected graph.
class FunctionRemoved extends GraphEvent {
  const FunctionRemoved(this.functionId);
  final String functionId;
  @override
  List<Object?> get props => [functionId];
}

// ─── Variable management ──────────────────────────────────────────────────────

/// Add or update a variable.
class VariableSet extends GraphEvent {
  const VariableSet({
    required this.name,
    required this.value,
    this.min,
    this.max,
    this.step,
  });
  final String name;
  final double value;
  final double? min;
  final double? max;
  final double? step;
  @override
  List<Object?> get props => [name, value, min, max, step];
}

/// Remove a variable.
class VariableRemoved extends GraphEvent {
  const VariableRemoved(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

// ─── Matrix operations ────────────────────────────────────────────────────────

/// Add a new matrix.
class MatrixAdded extends GraphEvent {
  const MatrixAdded({required this.matrix});
  final MatrixData matrix;
  @override
  List<Object?> get props => [matrix];
}

/// Update a matrix cell value.
class MatrixCellUpdated extends GraphEvent {
  const MatrixCellUpdated({
    required this.matrixIndex,
    required this.row,
    required this.col,
    required this.value,
  });
  final int matrixIndex;
  final int row;
  final int col;
  final double value;
  @override
  List<Object?> get props => [matrixIndex, row, col, value];
}

/// Remove a matrix.
class MatrixRemoved extends GraphEvent {
  const MatrixRemoved(this.matrixIndex);
  final int matrixIndex;
  @override
  List<Object?> get props => [matrixIndex];
}

/// Perform a matrix operation and store the result.
class MatrixOperationRequested extends GraphEvent {
  const MatrixOperationRequested({
    required this.operation,
    required this.operandIndices,
  });

  /// Operation name: "add", "subtract", "multiply", "transpose",
  /// "determinant", "inverse", "scale".
  final String operation;

  /// Indices into the matrices list. For unary ops, only first is used.
  final List<int> operandIndices;

  @override
  List<Object?> get props => [operation, operandIndices];
}

/// Force recalculation of all functions.
class GraphRecalculated extends GraphEvent {
  const GraphRecalculated();
}
