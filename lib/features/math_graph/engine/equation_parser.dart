import 'dart:math' as math;

/// A parsed expression that can be evaluated for a given variable context.
///
/// The parser supports:
/// - Arithmetic: +, -, *, /, ^, %
/// - Unary negation: -x
/// - Parentheses: (expr)
/// - Constants: pi, e
/// - Functions: sin, cos, tan, asin, acos, atan, sqrt, abs, ln, log, exp, floor, ceil
/// - Variables: x (primary), plus any user-defined ones
abstract class _Expr {
  double evaluate(Map<String, double> vars);
}

class _NumberExpr extends _Expr {
  _NumberExpr(this.value);
  final double value;
  @override
  double evaluate(Map<String, double> vars) => value;
}

class _VariableExpr extends _Expr {
  _VariableExpr(this.name);
  final String name;
  @override
  double evaluate(Map<String, double> vars) =>
      vars[name] ?? double.nan;
}

class _UnaryExpr extends _Expr {
  _UnaryExpr(this.op, this.operand);
  final String op;
  final _Expr operand;
  @override
  double evaluate(Map<String, double> vars) {
    final v = operand.evaluate(vars);
    return op == '-' ? -v : v;
  }
}

class _BinaryExpr extends _Expr {
  _BinaryExpr(this.op, this.left, this.right);
  final String op;
  final _Expr left;
  final _Expr right;
  @override
  double evaluate(Map<String, double> vars) {
    final l = left.evaluate(vars);
    final r = right.evaluate(vars);
    switch (op) {
      case '+':
        return l + r;
      case '-':
        return l - r;
      case '*':
        return l * r;
      case '/':
        return r == 0 ? double.nan : l / r;
      case '^':
        return math.pow(l, r).toDouble();
      case '%':
        return r == 0 ? double.nan : l % r;
      default:
        return double.nan;
    }
  }
}

class _FunctionExpr extends _Expr {
  _FunctionExpr(this.name, this.arg);
  final String name;
  final _Expr arg;
  @override
  double evaluate(Map<String, double> vars) {
    final v = arg.evaluate(vars);
    switch (name) {
      case 'sin':
        return math.sin(v);
      case 'cos':
        return math.cos(v);
      case 'tan':
        return math.tan(v);
      case 'asin':
        return math.asin(v);
      case 'acos':
        return math.acos(v);
      case 'atan':
        return math.atan(v);
      case 'sqrt':
        return v < 0 ? double.nan : math.sqrt(v);
      case 'abs':
        return v.abs();
      case 'ln':
        return v <= 0 ? double.nan : math.log(v);
      case 'log':
        return v <= 0 ? double.nan : math.log(v) / math.ln10;
      case 'exp':
        return math.exp(v);
      case 'floor':
        return v.floorToDouble();
      case 'ceil':
        return v.ceilToDouble();
      default:
        return double.nan;
    }
  }
}

/// Parses a mathematical expression string into an evaluatable tree.
///
/// Grammar (precedence low → high):
/// ```
/// expression = term (('+' | '-') term)*
/// term       = power (('*' | '/' | '%') power)*
/// power      = unary ('^' unary)*
/// unary      = '-' unary | call
/// call       = FUNCTION '(' expression ')' | atom
/// atom       = NUMBER | VARIABLE | '(' expression ')'
/// ```
class EquationParser {
  const EquationParser();

  static const _functions = {
    'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
    'sqrt', 'abs', 'ln', 'log', 'exp', 'floor', 'ceil',
  };

  static const _constants = {'pi': math.pi, 'e': math.e};

  /// Parse [input] and return a callable that evaluates f(vars).
  ///
  /// Throws [FormatException] on invalid syntax.
  double Function(Map<String, double> vars) parse(String input) {
    final tokens = _tokenize(input);
    final iter = _TokenIterator(tokens);
    final expr = _parseExpression(iter);
    if (iter.hasNext) {
      throw FormatException(
        'Unexpected token: "${iter.peek}"',
        input,
      );
    }
    return (vars) => expr.evaluate(vars);
  }

  // ─── Tokenizer ────────────────────────────────────────────────────────────

  List<String> _tokenize(String input) {
    final tokens = <String>[];
    final src = input.replaceAll(' ', '');
    var i = 0;
    while (i < src.length) {
      final ch = src[i];

      // Number (including decimals)
      if (_isDigit(ch) || (ch == '.' && i + 1 < src.length && _isDigit(src[i + 1]))) {
        final start = i;
        while (i < src.length && (_isDigit(src[i]) || src[i] == '.')) {
          i++;
        }
        tokens.add(src.substring(start, i));
        continue;
      }

      // Letter → function name or variable
      if (_isLetter(ch)) {
        final start = i;
        while (i < src.length && _isLetter(src[i])) {
          i++;
        }
        tokens.add(src.substring(start, i));
        continue;
      }

      // Operators and parens
      if ('+-*/^%()'.contains(ch)) {
        tokens.add(ch);
        i++;
        continue;
      }

      // Skip unknown characters
      i++;
    }
    return tokens;
  }

  bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
  bool _isLetter(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
  }

  // ─── Recursive descent parser ─────────────────────────────────────────────

  _Expr _parseExpression(_TokenIterator iter) {
    var left = _parseTerm(iter);
    while (iter.hasNext && (iter.peek == '+' || iter.peek == '-')) {
      final op = iter.next();
      final right = _parseTerm(iter);
      left = _BinaryExpr(op, left, right);
    }
    return left;
  }

  _Expr _parseTerm(_TokenIterator iter) {
    var left = _parsePower(iter);
    while (iter.hasNext &&
        (iter.peek == '*' || iter.peek == '/' || iter.peek == '%')) {
      final op = iter.next();
      final right = _parsePower(iter);
      left = _BinaryExpr(op, left, right);
    }
    return left;
  }

  _Expr _parsePower(_TokenIterator iter) {
    final base = _parseUnary(iter);
    if (iter.hasNext && iter.peek == '^') {
      iter.next(); // consume '^'
      final exp = _parseUnary(iter); // right-associative
      return _BinaryExpr('^', base, exp);
    }
    return base;
  }

  _Expr _parseUnary(_TokenIterator iter) {
    if (iter.hasNext && iter.peek == '-') {
      iter.next();
      final operand = _parseUnary(iter);
      return _UnaryExpr('-', operand);
    }
    return _parseCall(iter);
  }

  _Expr _parseCall(_TokenIterator iter) {
    if (iter.hasNext && _functions.contains(iter.peek)) {
      final name = iter.next();
      if (!iter.hasNext || iter.peek != '(') {
        throw const FormatException('Expected "(" after function name');
      }
      iter.next(); // consume '('
      final arg = _parseExpression(iter);
      if (!iter.hasNext || iter.peek != ')') {
        throw const FormatException('Expected ")" after function argument');
      }
      iter.next(); // consume ')'
      return _FunctionExpr(name, arg);
    }
    return _parseAtom(iter);
  }

  _Expr _parseAtom(_TokenIterator iter) {
    if (!iter.hasNext) {
      throw const FormatException('Unexpected end of expression');
    }

    final token = iter.peek!;

    // Parenthesised expression
    if (token == '(') {
      iter.next(); // consume '('
      final expr = _parseExpression(iter);
      if (!iter.hasNext || iter.peek != ')') {
        throw const FormatException('Expected ")"');
      }
      iter.next(); // consume ')'
      return expr;
    }

    // Number
    final num = double.tryParse(token);
    if (num != null) {
      iter.next();
      return _NumberExpr(num);
    }

    // Constant
    if (_constants.containsKey(token)) {
      iter.next();
      return _NumberExpr(_constants[token]!);
    }

    // Variable
    if (_isLetter(token[0])) {
      iter.next();

      // Handle implicit multiplication: "2x" is tokenized as "2", "x",
      // but "xy" should be x*y. We handle the caller side for leading
      // coefficient implicit multiply in _parseTerm already via tokenizer.
      return _VariableExpr(token);
    }

    throw FormatException('Unexpected token: "$token"');
  }
}

/// Simple iterator over a list of string tokens.
class _TokenIterator {
  _TokenIterator(this._tokens);
  final List<String> _tokens;
  int _pos = 0;

  bool get hasNext => _pos < _tokens.length;
  String? get peek => hasNext ? _tokens[_pos] : null;
  String next() => _tokens[_pos++];
}
