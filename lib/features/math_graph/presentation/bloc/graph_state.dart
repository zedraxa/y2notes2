import 'package:equatable/equatable.dart';

import '../../domain/entities/graph_element.dart';
import '../../domain/entities/matrix_data.dart';

/// Immutable state for the graph feature BLoC.
class GraphState extends Equatable {
  const GraphState({
    this.graphs = const [],
    this.selectedGraphId,
    this.matrixResult,
    this.matrixResultLabel,
    this.scalarResult,
    this.errorMessage,
    this.isProcessing = false,
  });

  /// All graph elements on the canvas.
  final List<GraphElement> graphs;

  /// ID of the currently selected graph, or null if none.
  final String? selectedGraphId;

  /// Result of the last matrix operation (if matrix-valued).
  final MatrixData? matrixResult;

  /// Human-readable label for [matrixResult] (e.g. "A × B").
  final String? matrixResultLabel;

  /// Scalar result of the last matrix operation (e.g. determinant).
  final double? scalarResult;

  /// Error message to show in the UI.
  final String? errorMessage;

  /// Whether a computation is in progress.
  final bool isProcessing;

  // ─── Derived ────────────────────────────────────────────────────────────

  /// The currently selected graph element.
  GraphElement? get selectedGraph => selectedGraphId == null
      ? null
      : graphs
          .cast<GraphElement?>()
          .firstWhere((g) => g!.id == selectedGraphId, orElse: () => null);

  bool get hasSelection => selectedGraphId != null;

  GraphState copyWith({
    List<GraphElement>? graphs,
    String? selectedGraphId,
    bool clearSelection = false,
    MatrixData? matrixResult,
    bool clearMatrixResult = false,
    String? matrixResultLabel,
    double? scalarResult,
    bool clearScalarResult = false,
    String? errorMessage,
    bool clearError = false,
    bool? isProcessing,
  }) =>
      GraphState(
        graphs: graphs ?? this.graphs,
        selectedGraphId:
            clearSelection ? null : (selectedGraphId ?? this.selectedGraphId),
        matrixResult:
            clearMatrixResult ? null : (matrixResult ?? this.matrixResult),
        matrixResultLabel: clearMatrixResult
            ? null
            : (matrixResultLabel ?? this.matrixResultLabel),
        scalarResult:
            clearScalarResult ? null : (scalarResult ?? this.scalarResult),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isProcessing: isProcessing ?? this.isProcessing,
      );

  @override
  List<Object?> get props => [
        graphs,
        selectedGraphId,
        matrixResult,
        matrixResultLabel,
        scalarResult,
        errorMessage,
        isProcessing,
      ];
}
