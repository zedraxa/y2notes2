import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/graph_element.dart';
import '../../domain/entities/graph_function.dart';
import '../../domain/entities/math_variable.dart';
import '../../domain/entities/matrix_data.dart';
import '../../engine/matrix_engine.dart';
import '../../engine/point_calculator.dart';
import 'graph_event.dart';
import 'graph_state.dart';

/// BLoC that manages interactive math graph creation and editing.
///
/// Owns the list of [GraphElement]s and handles function evaluation,
/// variable updates, and matrix operations.
class GraphBloc extends Bloc<GraphEvent, GraphState> {
  GraphBloc() : super(const GraphState()) {
    on<GraphCreated>(_onGraphCreated);
    on<GraphSelected>(_onGraphSelected);
    on<GraphDeselected>(_onGraphDeselected);
    on<GraphDeleteRequested>(_onGraphDeleteRequested);
    on<GraphBoundsChanged>(_onGraphBoundsChanged);
    on<GraphViewportChanged>(_onGraphViewportChanged);
    on<GraphGridToggled>(_onGraphGridToggled);
    on<FunctionAdded>(_onFunctionAdded);
    on<FunctionExpressionChanged>(_onFunctionExpressionChanged);
    on<FunctionStyleChanged>(_onFunctionStyleChanged);
    on<FunctionVisibilityToggled>(_onFunctionVisibilityToggled);
    on<FunctionRemoved>(_onFunctionRemoved);
    on<VariableSet>(_onVariableSet);
    on<VariableRemoved>(_onVariableRemoved);
    on<MatrixAdded>(_onMatrixAdded);
    on<MatrixCellUpdated>(_onMatrixCellUpdated);
    on<MatrixRemoved>(_onMatrixRemoved);
    on<MatrixOperationRequested>(_onMatrixOperationRequested);
    on<GraphRecalculated>(_onGraphRecalculated);
  }

  final _calc = const PointCalculator();
  final _matrix = const MatrixEngine();
  final _uuid = const Uuid();

  // ─── Graph lifecycle ────────────────────────────────────────────────────

  void _onGraphCreated(GraphCreated event, Emitter<GraphState> emit) {
    final graph = GraphElement(
      id: _uuid.v4(),
      bounds: event.bounds,
      title: event.title,
    );
    emit(state.copyWith(
      graphs: [...state.graphs, graph],
      selectedGraphId: graph.id,
      clearError: true,
    ));
  }

  void _onGraphSelected(GraphSelected event, Emitter<GraphState> emit) {
    emit(state.copyWith(selectedGraphId: event.graphId, clearError: true));
  }

  void _onGraphDeselected(GraphDeselected event, Emitter<GraphState> emit) {
    emit(state.copyWith(clearSelection: true));
  }

  void _onGraphDeleteRequested(
      GraphDeleteRequested event, Emitter<GraphState> emit) {
    final id = state.selectedGraphId;
    if (id == null) return;
    final graphs = state.graphs.where((g) => g.id != id).toList();
    emit(state.copyWith(graphs: graphs, clearSelection: true));
  }

  void _onGraphBoundsChanged(
      GraphBoundsChanged event, Emitter<GraphState> emit) {
    final updated = _updateSelectedGraph(
      (g) => g.copyWith(bounds: event.bounds),
    );
    if (updated != null) {
      emit(state.copyWith(graphs: _replaceGraph(updated)));
      _recalcAll(emit, updated);
    }
  }

  void _onGraphViewportChanged(
      GraphViewportChanged event, Emitter<GraphState> emit) {
    final updated = _updateSelectedGraph(
      (g) => g.copyWith(
        xMin: event.xMin,
        xMax: event.xMax,
        yMin: event.yMin,
        yMax: event.yMax,
      ),
    );
    if (updated != null) {
      emit(state.copyWith(graphs: _replaceGraph(updated)));
      _recalcAll(emit, updated);
    }
  }

  void _onGraphGridToggled(
      GraphGridToggled event, Emitter<GraphState> emit) {
    final updated = _updateSelectedGraph(
      (g) => g.copyWith(showGrid: event.visible),
    );
    if (updated != null) emit(state.copyWith(graphs: _replaceGraph(updated)));
  }

  // ─── Function management ────────────────────────────────────────────────

  void _onFunctionAdded(FunctionAdded event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;

    var func = GraphFunction.create(
      expression: event.expression,
      type: event.type,
      style: event.style,
      label: event.label,
    );

    func = _calc.calculate(
      func: func,
      xMin: graph.xMin,
      xMax: graph.xMax,
      yMin: graph.yMin,
      yMax: graph.yMax,
      variables: graph.variableMap,
    );

    final updated = graph.copyWith(functions: [...graph.functions, func]);
    emit(state.copyWith(graphs: _replaceGraph(updated), clearError: true));
  }

  void _onFunctionExpressionChanged(
      FunctionExpressionChanged event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;

    final functions = graph.functions.map((f) {
      if (f.id != event.functionId) return f;
      var updated = f.copyWith(expression: event.expression);
      updated = _calc.calculate(
        func: updated,
        xMin: graph.xMin,
        xMax: graph.xMax,
        yMin: graph.yMin,
        yMax: graph.yMax,
        variables: graph.variableMap,
      );
      return updated;
    }).toList();

    final updated = graph.copyWith(functions: functions);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
  }

  void _onFunctionStyleChanged(
      FunctionStyleChanged event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;

    final functions = graph.functions
        .map((f) => f.id == event.functionId
            ? f.copyWith(style: event.style)
            : f)
        .toList();

    final updated = graph.copyWith(functions: functions);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
  }

  void _onFunctionVisibilityToggled(
      FunctionVisibilityToggled event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;

    final functions = graph.functions
        .map((f) =>
            f.id == event.functionId ? f.copyWith(isVisible: !f.isVisible) : f)
        .toList();

    final updated = graph.copyWith(functions: functions);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
  }

  void _onFunctionRemoved(
      FunctionRemoved event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;

    final functions =
        graph.functions.where((f) => f.id != event.functionId).toList();
    final updated = graph.copyWith(functions: functions);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
  }

  // ─── Variable management ────────────────────────────────────────────────

  void _onVariableSet(VariableSet event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;

    final variables = List<MathVariable>.of(graph.variables);
    final idx = variables.indexWhere((v) => v.name == event.name);
    final newVar = MathVariable(
      name: event.name,
      value: event.value,
      min: event.min,
      max: event.max,
      step: event.step,
    );

    if (idx >= 0) {
      variables[idx] = newVar;
    } else {
      variables.add(newVar);
    }

    final updated = graph.copyWith(variables: variables);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
    _recalcAll(emit, updated);
  }

  void _onVariableRemoved(
      VariableRemoved event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;

    final variables =
        graph.variables.where((v) => v.name != event.name).toList();
    final updated = graph.copyWith(variables: variables);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
    _recalcAll(emit, updated);
  }

  // ─── Matrix operations ──────────────────────────────────────────────────

  void _onMatrixAdded(MatrixAdded event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;

    final updated =
        graph.copyWith(matrices: [...graph.matrices, event.matrix]);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
  }

  void _onMatrixCellUpdated(
      MatrixCellUpdated event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;
    if (event.matrixIndex < 0 || event.matrixIndex >= graph.matrices.length) {
      return;
    }

    final m = graph.matrices[event.matrixIndex];
    final newValues =
        m.values.map((row) => List<double>.of(row)).toList();
    if (event.row >= 0 &&
        event.row < m.rows &&
        event.col >= 0 &&
        event.col < m.cols) {
      newValues[event.row][event.col] = event.value;
    }

    final matrices = List<MatrixData>.of(graph.matrices);
    matrices[event.matrixIndex] = m.copyWith(values: newValues);
    final updated = graph.copyWith(matrices: matrices);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
  }

  void _onMatrixRemoved(MatrixRemoved event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;
    if (event.matrixIndex < 0 || event.matrixIndex >= graph.matrices.length) {
      return;
    }

    final matrices = List<MatrixData>.of(graph.matrices)
      ..removeAt(event.matrixIndex);
    final updated = graph.copyWith(matrices: matrices);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
  }

  void _onMatrixOperationRequested(
      MatrixOperationRequested event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;

    try {
      final indices = event.operandIndices;
      if (indices.isEmpty) return;

      final a = graph.matrices[indices[0]];
      final labelA = a.label ?? 'M${indices[0] + 1}';

      switch (event.operation) {
        case 'add':
          if (indices.length < 2) return;
          final b = graph.matrices[indices[1]];
          final labelB = b.label ?? 'M${indices[1] + 1}';
          final result = _matrix.add(a, b);
          emit(state.copyWith(
            matrixResult: result,
            matrixResultLabel: '$labelA + $labelB',
            clearScalarResult: true,
            clearError: true,
          ));
        case 'subtract':
          if (indices.length < 2) return;
          final b = graph.matrices[indices[1]];
          final labelB = b.label ?? 'M${indices[1] + 1}';
          final result = _matrix.subtract(a, b);
          emit(state.copyWith(
            matrixResult: result,
            matrixResultLabel: '$labelA - $labelB',
            clearScalarResult: true,
            clearError: true,
          ));
        case 'multiply':
          if (indices.length < 2) return;
          final b = graph.matrices[indices[1]];
          final labelB = b.label ?? 'M${indices[1] + 1}';
          final result = _matrix.multiply(a, b);
          emit(state.copyWith(
            matrixResult: result,
            matrixResultLabel: '$labelA × $labelB',
            clearScalarResult: true,
            clearError: true,
          ));
        case 'transpose':
          final result = _matrix.transpose(a);
          emit(state.copyWith(
            matrixResult: result,
            matrixResultLabel: '${labelA}ᵀ',
            clearScalarResult: true,
            clearError: true,
          ));
        case 'determinant':
          final det = _matrix.determinant(a);
          emit(state.copyWith(
            scalarResult: det,
            matrixResultLabel: 'det($labelA)',
            clearMatrixResult: true,
            clearError: true,
          ));
        case 'inverse':
          final inv = _matrix.inverse(a);
          if (inv == null) {
            emit(state.copyWith(
              errorMessage: 'Matrix is singular (non-invertible)',
            ));
          } else {
            emit(state.copyWith(
              matrixResult: inv,
              matrixResultLabel: '${labelA}⁻¹',
              clearScalarResult: true,
              clearError: true,
            ));
          }
        case 'trace':
          final tr = _matrix.trace(a);
          emit(state.copyWith(
            scalarResult: tr,
            matrixResultLabel: 'tr($labelA)',
            clearMatrixResult: true,
            clearError: true,
          ));
        default:
          emit(state.copyWith(
              errorMessage: 'Unknown operation: ${event.operation}'));
      }
    } on ArgumentError catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Matrix error: $e'));
    }
  }

  void _onGraphRecalculated(
      GraphRecalculated event, Emitter<GraphState> emit) {
    final graph = state.selectedGraph;
    if (graph == null) return;
    _recalcAll(emit, graph);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  /// Apply [update] to the selected graph element and return the result.
  GraphElement? _updateSelectedGraph(
      GraphElement Function(GraphElement) update) {
    final graph = state.selectedGraph;
    if (graph == null) return null;
    return update(graph);
  }

  /// Replace a graph in the list by ID.
  List<GraphElement> _replaceGraph(GraphElement updated) {
    return state.graphs
        .map((g) => g.id == updated.id ? updated : g)
        .toList();
  }

  /// Recalculate all functions in [graph] and emit updated state.
  void _recalcAll(Emitter<GraphState> emit, GraphElement graph) {
    final functions = graph.functions.map((f) {
      return _calc.calculate(
        func: f,
        xMin: graph.xMin,
        xMax: graph.xMax,
        yMin: graph.yMin,
        yMax: graph.yMax,
        variables: graph.variableMap,
      );
    }).toList();

    final updated = graph.copyWith(functions: functions);
    emit(state.copyWith(graphs: _replaceGraph(updated)));
  }
}
