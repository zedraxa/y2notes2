import 'package:equatable/equatable.dart';

/// Represents a 2D matrix for linear algebra operations.
class MatrixData extends Equatable {
  const MatrixData({
    required this.rows,
    required this.cols,
    required this.values,
    this.label,
  });

  /// Create a zero-filled matrix.
  factory MatrixData.zero(int rows, int cols, {String? label}) => MatrixData(
        rows: rows,
        cols: cols,
        values: List.generate(rows, (_) => List.filled(cols, 0.0)),
        label: label,
      );

  /// Create an identity matrix of size [n].
  factory MatrixData.identity(int n, {String? label}) => MatrixData(
        rows: n,
        cols: n,
        values: List.generate(
          n,
          (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0),
        ),
        label: label,
      );

  final int rows;
  final int cols;

  /// Row-major 2D list of values.
  final List<List<double>> values;

  /// Optional display label (e.g. "A", "B").
  final String? label;

  /// Get a single element.
  double at(int row, int col) => values[row][col];

  /// Whether this is a square matrix.
  bool get isSquare => rows == cols;

  MatrixData copyWith({
    int? rows,
    int? cols,
    List<List<double>>? values,
    String? label,
    bool clearLabel = false,
  }) =>
      MatrixData(
        rows: rows ?? this.rows,
        cols: cols ?? this.cols,
        values: values ?? this.values,
        label: clearLabel ? null : (label ?? this.label),
      );

  Map<String, dynamic> toJson() => {
        'rows': rows,
        'cols': cols,
        'values': values
            .map((row) => row.map((v) => v).toList())
            .toList(),
        if (label != null) 'label': label,
      };

  factory MatrixData.fromJson(Map<String, dynamic> json) => MatrixData(
        rows: json['rows'] as int,
        cols: json['cols'] as int,
        values: (json['values'] as List<dynamic>)
            .map((row) => (row as List<dynamic>)
                .map((v) => (v as num).toDouble())
                .toList())
            .toList(),
        label: json['label'] as String?,
      );

  @override
  List<Object?> get props => [rows, cols, values, label];
}
