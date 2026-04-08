import 'dart:math' as math;
import 'package:biscuits/features/handwriting/data/math_templates.dart';
import 'package:biscuits/features/handwriting/domain/entities/recognition_result.dart';

/// Result of math expression recognition.
class MathRecognitionResult {
  const MathRecognitionResult({
    required this.expression,
    required this.latex,
    this.result,
    this.isValid = false,
  });

  final String expression; // human-readable: "2 + 3"
  final String latex;      // LaTeX: "2 + 3"
  final String? result;    // computed: "5"
  final bool isValid;

  static const empty = MathRecognitionResult(
    expression: '',
    latex: '',
    isValid: false,
  );
}

/// Detects and evaluates simple math expressions from recognized text.
class MathRecognizer {
  const MathRecognizer();

  /// Returns a [MathRecognitionResult] if [text] looks like a math expression.
  MathRecognitionResult? tryRecognize(String text) {
    final tokens = _tokenize(text);
    if (!MathTemplates.looksLikeMath(tokens)) return null;

    final expr = tokens.join(' ');
    final latex = _toLatex(tokens);
    final result = _evaluate(tokens);

    return MathRecognitionResult(
      expression: expr,
      latex: latex,
      result: result,
      isValid: result != null,
    );
  }

  List<String> _tokenize(String text) {
    // Split on spaces and treat each character that is an operator separately
    final result = <String>[];
    for (final part in text.split(RegExp(r'\s+'))) {
      if (part.isEmpty) continue;
      // If part is a single math token, add directly
      if (MathTemplates.isMathToken(part)) {
        result.add(part);
      } else {
        // Try to split into digits and operators
        var current = '';
        for (final ch in part.split('')) {
          if (MathTemplates.operators.contains(ch) || MathTemplates.grouping.contains(ch)) {
            if (current.isNotEmpty) {
              result.add(current);
              current = '';
            }
            result.add(ch);
          } else {
            current += ch;
          }
        }
        if (current.isNotEmpty) result.add(current);
      }
    }
    return result;
  }

  String _toLatex(List<String> tokens) {
    final sb = StringBuffer();
    var i = 0;
    while (i < tokens.length) {
      final t = tokens[i];
      switch (t) {
        case '×':
          sb.write(r' \times ');
          i++;
        case '÷':
          sb.write(r' \div ');
          i++;
        case '^':
          if (i + 1 < tokens.length) {
            sb.write('^{${tokens[i + 1]}}');
            i += 2; // consume '^' and the exponent token
          } else {
            sb.write('^');
            i++;
          }
        default:
          sb.write(' $t ');
          i++;
      }
    }
    return sb.toString().trim();
  }

  /// Evaluate simple arithmetic. Returns null if evaluation fails.
  String? _evaluate(List<String> tokens) {
    try {
      final expr = tokens.join('').replaceAll('×', '*').replaceAll('÷', '/');
      final result = _evalExpr(expr);
      if (result == null) return null;
      // Format: remove trailing zeros from decimals
      if (result == result.truncateToDouble()) {
        return result.toInt().toString();
      }
      return result.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } catch (_) {
      return null;
    }
  }

  /// Very simple recursive descent evaluator (addition/subtraction/multiplication/division).
  double? _evalExpr(String expr) {
    final clean = expr.replaceAll(' ', '');
    if (clean.isEmpty) return null;

    // Find last + or - (not inside parens)
    var depth = 0;
    for (var i = clean.length - 1; i >= 0; i--) {
      final ch = clean[i];
      if (ch == ')') depth++;
      if (ch == '(') depth--;
      if (depth == 0 && (ch == '+' || ch == '-') && i > 0) {
        final left = _evalExpr(clean.substring(0, i));
        final right = _evalExpr(clean.substring(i + 1));
        if (left == null || right == null) return null;
        return ch == '+' ? left + right : left - right;
      }
    }

    // Then * and /
    depth = 0;
    for (var i = clean.length - 1; i >= 0; i--) {
      final ch = clean[i];
      if (ch == ')') depth++;
      if (ch == '(') depth--;
      if (depth == 0 && (ch == '*' || ch == '/')) {
        final left = _evalExpr(clean.substring(0, i));
        final right = _evalExpr(clean.substring(i + 1));
        if (left == null || right == null) return null;
        if (ch == '/' && right == 0) return null;
        return ch == '*' ? left * right : left / right;
      }
    }

    // Then ^ (power)
    depth = 0;
    for (var i = clean.length - 1; i >= 0; i--) {
      final ch = clean[i];
      if (ch == ')') depth++;
      if (ch == '(') depth--;
      if (depth == 0 && ch == '^') {
        final left = _evalExpr(clean.substring(0, i));
        final right = _evalExpr(clean.substring(i + 1));
        if (left == null || right == null) return null;
        return _pow(left, right);
      }
    }

    // Parentheses
    if (clean.startsWith('(') && clean.endsWith(')')) {
      return _evalExpr(clean.substring(1, clean.length - 1));
    }

    return double.tryParse(clean);
  }

  double _pow(double base, double exp) {
    return math.pow(base, exp).toDouble();
  }
}
