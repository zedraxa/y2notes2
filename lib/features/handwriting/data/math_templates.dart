/// Templates for math expression detection.
class MathTemplates {
  MathTemplates._();

  static const Set<String> operators = {'+', '-', '×', '÷', '*', '/', '=', '<', '>', '^', '%'};
  static const Set<String> digits = {'0','1','2','3','4','5','6','7','8','9'};
  static const Set<String> grouping = {'(', ')', '[', ']'};

  static bool isMathToken(String token) =>
      operators.contains(token) || digits.contains(token) || grouping.contains(token);

  /// Heuristic: returns true if the token sequence looks like a math expression.
  static bool looksLikeMath(List<String> tokens) {
    if (tokens.length < 3) return false;
    var digitCount = 0;
    var opCount = 0;
    for (final t in tokens) {
      if (digits.contains(t)) digitCount++;
      if (operators.contains(t)) opCount++;
    }
    return digitCount >= 2 && opCount >= 1;
  }
}
