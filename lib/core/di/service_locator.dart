/// Lightweight service locator for dependency injection.
///
/// Provides lazy-initialised singleton registration, factory registration,
/// and type-safe retrieval without pulling in an external package.
///
/// Usage:
/// ```dart
/// final sl = ServiceLocator.instance;
/// sl.registerLazySingleton<MyService>(() => MyService());
/// final service = sl<MyService>();
/// ```
class ServiceLocator {
  ServiceLocator._();

  /// The global [ServiceLocator] instance.
  static final ServiceLocator instance = ServiceLocator._();

  /// Shorthand accessor so callers can write `sl<T>()`.
  static ServiceLocator get I => instance;

  final Map<Type, _Registration<dynamic>> _registrations = {};

  // ── Registration ──────────────────────────────────────────────────────────

  /// Registers a pre-created singleton [instance].
  void registerSingleton<T extends Object>(T instance) {
    _registrations[T] = _Registration<T>.singleton(instance);
  }

  /// Registers a factory [create] that is invoked lazily on first access.
  ///
  /// Subsequent calls to [call] return the cached instance.
  void registerLazySingleton<T extends Object>(T Function() create) {
    _registrations[T] = _Registration<T>.lazy(create);
  }

  /// Registers a [factory] that creates a new instance on every access.
  void registerFactory<T extends Object>(T Function() factory) {
    _registrations[T] = _Registration<T>.factory(factory);
  }

  // ── Retrieval ─────────────────────────────────────────────────────────────

  /// Retrieves the registered instance of [T].
  ///
  /// Throws [StateError] if [T] was never registered.
  T call<T extends Object>() {
    final reg = _registrations[T];
    if (reg == null) {
      throw StateError(
        'ServiceLocator: No registration found for $T. '
        'Did you forget to call register*<$T>()?',
      );
    }
    return reg.resolve() as T;
  }

  /// Returns `true` when [T] has been registered.
  bool isRegistered<T extends Object>() => _registrations.containsKey(T);

  /// Removes the registration for [T].
  void unregister<T extends Object>() => _registrations.remove(T);

  /// Clears all registrations. Useful for testing.
  void reset() => _registrations.clear();
}

// ── Internal registration wrapper ─────────────────────────────────────────────

enum _RegistrationType { singleton, lazy, factory }

class _Registration<T> {
  _Registration.singleton(T instance)
      : _type = _RegistrationType.singleton,
        _instance = instance,
        _factory = null;

  _Registration.lazy(T Function() factory)
      : _type = _RegistrationType.lazy,
        _instance = null,
        _factory = factory;

  _Registration.factory(T Function() factory)
      : _type = _RegistrationType.factory,
        _instance = null,
        _factory = factory;

  final _RegistrationType _type;
  T? _instance;
  final T Function()? _factory;

  T resolve() {
    switch (_type) {
      case _RegistrationType.singleton:
        return _instance as T;
      case _RegistrationType.lazy:
        _instance ??= _factory!();
        return _instance as T;
      case _RegistrationType.factory:
        return _factory!();
    }
  }
}
