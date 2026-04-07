/// Iterable convenience extensions shared across the codebase.
extension IterableX<T> on Iterable<T> {
  /// Returns the first element, or `null` if the iterable is empty.
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
