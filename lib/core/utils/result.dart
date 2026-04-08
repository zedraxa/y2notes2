/// A discriminated union representing either a successful [value] or
/// a [failure].
///
/// Use pattern matching or the convenience helpers to handle both cases:
///
/// ```dart
/// final result = await repository.loadNotebook(id);
/// result.when(
///   success: (notebook) => emit(state.copyWith(notebook: notebook)),
///   failure: (error) => emit(state.copyWith(error: error)),
/// );
/// ```
sealed class Result<T> {
  const Result._();

  /// Creates a successful result containing [value].
  const factory Result.success(T value) = Success<T>;

  /// Creates a failure result containing [error] and an optional
  /// [stackTrace].
  const factory Result.failure(
    AppError error, [
    StackTrace? stackTrace,
  ]) = Failure<T>;

  /// Returns `true` when this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns `true` when this is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Returns the success value or `null`.
  T? get valueOrNull {
    final self = this;
    return self is Success<T> ? self.value : null;
  }

  /// Returns the error or `null`.
  AppError? get errorOrNull {
    final self = this;
    return self is Failure<T> ? self.error : null;
  }

  /// Exhaustive fold – both callbacks are required.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.value);
    return failure((self as Failure<T>).error);
  }

  /// Transforms the success value with [transform], passing failures
  /// through unchanged.
  Result<R> map<R>(R Function(T value) transform) {
    final self = this;
    if (self is Success<T>) {
      return Result<R>.success(transform(self.value));
    }
    final fail = self as Failure<T>;
    return Result<R>.failure(fail.error, fail.stackTrace);
  }

  /// Chains an asynchronous operation that itself returns a [Result].
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    final self = this;
    if (self is Success<T>) return transform(self.value);
    final fail = self as Failure<T>;
    return Result<R>.failure(fail.error, fail.stackTrace);
  }
}

/// Represents a successful outcome.
final class Success<T> extends Result<T> {
  const Success(this.value) : super._();

  /// The wrapped value.
  final T value;

  @override
  String toString() => 'Success($value)';
}

/// Represents a failed outcome.
final class Failure<T> extends Result<T> {
  const Failure(this.error, [this.stackTrace]) : super._();

  /// The structured error.
  final AppError error;

  /// Optional stack trace captured at the point of failure.
  final StackTrace? stackTrace;

  @override
  String toString() => 'Failure($error)';
}

// ── Structured error ──────────────────────────────────────────────────────────

/// Categorised application error with a human-readable [message] and
/// machine-readable [code].
class AppError {
  const AppError({
    required this.code,
    required this.message,
    this.exception,
  });

  /// Machine-readable error identifier (e.g. `storage.write_failed`).
  final String code;

  /// Human-readable description suitable for logging or (after
  /// localisation) display.
  final String message;

  /// The underlying exception, if any.
  final Object? exception;

  @override
  String toString() => 'AppError($code: $message)';
}
