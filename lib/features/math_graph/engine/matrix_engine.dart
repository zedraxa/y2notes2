import 'dart:math' as math;
import '../domain/entities/matrix_data.dart';

/// Engine for basic matrix operations.
///
/// Supports addition, subtraction, multiplication, transpose, determinant,
/// scalar multiplication, and inverse (for square matrices).
class MatrixEngine {
  const MatrixEngine();

  /// Matrix addition: A + B.
  MatrixData add(MatrixData a, MatrixData b) {
    _assertSameSize(a, b, 'addition');
    final values = List.generate(
      a.rows,
      (i) => List.generate(a.cols, (j) => a.at(i, j) + b.at(i, j)),
    );
    return MatrixData(rows: a.rows, cols: a.cols, values: values);
  }

  /// Matrix subtraction: A - B.
  MatrixData subtract(MatrixData a, MatrixData b) {
    _assertSameSize(a, b, 'subtraction');
    final values = List.generate(
      a.rows,
      (i) => List.generate(a.cols, (j) => a.at(i, j) - b.at(i, j)),
    );
    return MatrixData(rows: a.rows, cols: a.cols, values: values);
  }

  /// Matrix multiplication: A × B.
  MatrixData multiply(MatrixData a, MatrixData b) {
    if (a.cols != b.rows) {
      throw ArgumentError(
        'Cannot multiply ${a.rows}×${a.cols} by ${b.rows}×${b.cols}: '
        'column count of A must equal row count of B.',
      );
    }
    final values = List.generate(
      a.rows,
      (i) => List.generate(b.cols, (j) {
        var sum = 0.0;
        for (var k = 0; k < a.cols; k++) {
          sum += a.at(i, k) * b.at(k, j);
        }
        return sum;
      }),
    );
    return MatrixData(rows: a.rows, cols: b.cols, values: values);
  }

  /// Scalar multiplication: k × A.
  MatrixData scale(MatrixData a, double scalar) {
    final values = List.generate(
      a.rows,
      (i) => List.generate(a.cols, (j) => a.at(i, j) * scalar),
    );
    return MatrixData(rows: a.rows, cols: a.cols, values: values);
  }

  /// Transpose: Aᵀ.
  MatrixData transpose(MatrixData a) {
    final values = List.generate(
      a.cols,
      (i) => List.generate(a.rows, (j) => a.at(j, i)),
    );
    return MatrixData(rows: a.cols, cols: a.rows, values: values);
  }

  /// Determinant (square matrices only).
  double determinant(MatrixData a) {
    if (!a.isSquare) {
      throw ArgumentError('Determinant requires a square matrix.');
    }
    return _det(a.values, a.rows);
  }

  /// Matrix inverse using cofactor/adjugate method (square matrices only).
  MatrixData? inverse(MatrixData a) {
    if (!a.isSquare) return null;
    final det = determinant(a);
    if (det.abs() < 1e-12) return null; // singular

    final n = a.rows;
    final adj = List.generate(
      n,
      (i) => List.generate(n, (j) {
        final cofactor = _cofactor(a.values, n, i, j);
        return cofactor / det;
      }),
    );

    // Transpose the adjugate
    final inv = List.generate(
      n,
      (i) => List.generate(n, (j) => adj[j][i]),
    );

    return MatrixData(rows: n, cols: n, values: inv);
  }

  /// Trace of a square matrix (sum of diagonal).
  double trace(MatrixData a) {
    if (!a.isSquare) {
      throw ArgumentError('Trace requires a square matrix.');
    }
    var sum = 0.0;
    for (var i = 0; i < a.rows; i++) {
      sum += a.at(i, i);
    }
    return sum;
  }

  // ─── Private helpers ────────────────────────────────────────────────────

  void _assertSameSize(MatrixData a, MatrixData b, String op) {
    if (a.rows != b.rows || a.cols != b.cols) {
      throw ArgumentError(
        'Cannot perform $op on ${a.rows}×${a.cols} and '
        '${b.rows}×${b.cols} matrices: dimensions must match.',
      );
    }
  }

  /// Recursive determinant via cofactor expansion.
  double _det(List<List<double>> m, int n) {
    if (n == 1) return m[0][0];
    if (n == 2) return m[0][0] * m[1][1] - m[0][1] * m[1][0];

    var det = 0.0;
    for (var j = 0; j < n; j++) {
      final sub = _subMatrix(m, n, 0, j);
      det += math.pow(-1, j) * m[0][j] * _det(sub, n - 1);
    }
    return det;
  }

  double _cofactor(List<List<double>> m, int n, int row, int col) {
    final sub = _subMatrix(m, n, row, col);
    return math.pow(-1, row + col).toDouble() * _det(sub, n - 1);
  }

  /// Returns the (n-1)×(n-1) submatrix excluding [skipRow] and [skipCol].
  List<List<double>> _subMatrix(
      List<List<double>> m, int n, int skipRow, int skipCol) {
    final sub = <List<double>>[];
    for (var i = 0; i < n; i++) {
      if (i == skipRow) continue;
      final row = <double>[];
      for (var j = 0; j < n; j++) {
        if (j == skipCol) continue;
        row.add(m[i][j]);
      }
      sub.add(row);
    }
    return sub;
  }
}
