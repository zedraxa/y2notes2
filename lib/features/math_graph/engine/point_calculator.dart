import 'dart:math' as math;

import '../domain/entities/graph_function.dart';
import '../domain/models/graph_type.dart';
import 'equation_parser.dart';

/// Generates plot points for a [GraphFunction] over a given domain.
class PointCalculator {
  const PointCalculator({this.parser = const EquationParser()});

  final EquationParser parser;

  /// Number of sample points for the default domain.
  static const int defaultSamples = 400;

  /// Calculate plot points for [func] within the given domain.
  ///
  /// [variables] supplies user-defined variable values (e.g. a=3).
  /// Returns a new [GraphFunction] with populated [plotPoints] or an error.
  GraphFunction calculate({
    required GraphFunction func,
    required double xMin,
    required double xMax,
    required double yMin,
    required double yMax,
    Map<String, double> variables = const {},
    int samples = defaultSamples,
  }) {
    try {
      switch (func.type) {
        case GraphType.line:
        case GraphType.scatter:
          return _calculateCartesian(
              func, xMin, xMax, yMin, yMax, variables, samples);
        case GraphType.parametric:
          return _calculateParametric(
              func, xMin, xMax, yMin, yMax, variables, samples);
        case GraphType.polar:
          return _calculatePolar(
              func, xMin, xMax, yMin, yMax, variables, samples);
        case GraphType.implicit:
          return _calculateImplicit(
              func, xMin, xMax, yMin, yMax, variables, samples);
      }
    } on FormatException catch (e) {
      return func.copyWith(
        plotPoints: [],
        errorMessage: 'Parse error: ${e.message}',
      );
    } catch (e) {
      return func.copyWith(
        plotPoints: [],
        errorMessage: 'Evaluation error: $e',
      );
    }
  }

  /// Standard y = f(x) calculation.
  GraphFunction _calculateCartesian(
    GraphFunction func,
    double xMin,
    double xMax,
    double yMin,
    double yMax,
    Map<String, double> variables,
    int samples,
  ) {
    final evaluator = parser.parse(func.expression);
    final step = (xMax - xMin) / samples;
    final points = <(double, double)>[];

    for (var i = 0; i <= samples; i++) {
      final x = xMin + i * step;
      final vars = {...variables, 'x': x};
      final y = evaluator(vars);
      if (y.isFinite) {
        points.add((x, y));
      }
    }

    return func.copyWith(plotPoints: points, clearError: true);
  }

  /// Parametric: expression should contain both x(t) and y(t).
  /// For simplicity, we split on ';' → e.g. "cos(t);sin(t)"
  GraphFunction _calculateParametric(
    GraphFunction func,
    double xMin,
    double xMax,
    double yMin,
    double yMax,
    Map<String, double> variables,
    int samples,
  ) {
    final parts = func.expression.split(';');
    if (parts.length != 2) {
      return func.copyWith(
        plotPoints: [],
        errorMessage: 'Parametric requires "x(t);y(t)" format',
      );
    }

    final evalX = parser.parse(parts[0].trim());
    final evalY = parser.parse(parts[1].trim());

    final tMin = variables['tMin'] ?? 0.0;
    final tMax = variables['tMax'] ?? 6.283185307; // 2π
    final step = (tMax - tMin) / samples;
    final points = <(double, double)>[];

    for (var i = 0; i <= samples; i++) {
      final t = tMin + i * step;
      final vars = {...variables, 't': t};
      final x = evalX(vars);
      final y = evalY(vars);
      if (x.isFinite && y.isFinite) {
        points.add((x, y));
      }
    }

    return func.copyWith(plotPoints: points, clearError: true);
  }

  /// Polar: r = f(θ)
  GraphFunction _calculatePolar(
    GraphFunction func,
    double xMin,
    double xMax,
    double yMin,
    double yMax,
    Map<String, double> variables,
    int samples,
  ) {
    final evaluator = parser.parse(func.expression);
    final thetaMin = variables['thetaMin'] ?? 0.0;
    final thetaMax = variables['thetaMax'] ?? 6.283185307;
    final step = (thetaMax - thetaMin) / samples;
    final points = <(double, double)>[];

    for (var i = 0; i <= samples; i++) {
      final theta = thetaMin + i * step;
      final vars = {...variables, 'x': theta, 'theta': theta};
      final r = evaluator(vars);
      if (r.isFinite) {
        final x = r * math.cos(theta);
        final y = r * math.sin(theta);
        points.add((x, y));
      }
    }

    return func.copyWith(plotPoints: points, clearError: true);
  }

  /// Implicit: f(x,y) = 0. We sample a grid and look for sign changes.
  GraphFunction _calculateImplicit(
    GraphFunction func,
    double xMin,
    double xMax,
    double yMin,
    double yMax,
    Map<String, double> variables,
    int samples,
  ) {
    final evaluator = parser.parse(func.expression);
    final gridSize = (samples * 0.5).toInt().clamp(50, 200);
    final dx = (xMax - xMin) / gridSize;
    final dy = (yMax - yMin) / gridSize;
    final points = <(double, double)>[];

    for (var i = 0; i < gridSize; i++) {
      for (var j = 0; j < gridSize; j++) {
        final x = xMin + i * dx;
        final y = yMin + j * dy;
        final vars = {...variables, 'x': x, 'y': y};
        final v = evaluator(vars);
        // Check sign change with right and bottom neighbours.
        if (i < gridSize - 1) {
          final vr = evaluator({...vars, 'x': x + dx});
          if (v.isFinite && vr.isFinite && v * vr <= 0) {
            points.add((x + dx / 2, y));
          }
        }
        if (j < gridSize - 1) {
          final vb = evaluator({...vars, 'y': y + dy});
          if (v.isFinite && vb.isFinite && v * vb <= 0) {
            points.add((x, y + dy / 2));
          }
        }
      }
    }

    return func.copyWith(plotPoints: points, clearError: true);
  }
}
