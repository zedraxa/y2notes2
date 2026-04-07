/// Supported graph visualization types.
enum GraphType {
  /// Standard y = f(x) line graph.
  line,

  /// Scatter plot of discrete data points.
  scatter,

  /// Parametric curve x(t), y(t).
  parametric,

  /// Polar curve r(θ).
  polar,

  /// Implicit equation f(x,y) = 0 (rendered via contour sampling).
  implicit,
}
