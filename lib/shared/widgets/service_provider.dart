import 'package:flutter/material.dart';

/// Simple [InheritedWidget]-based provider for a single service type [T].
///
/// Used to pass [SettingsService] (and future services) down the widget tree
/// without pulling in the full `provider` package.
class ServiceProvider<T> extends InheritedWidget {
  const ServiceProvider({
    super.key,
    required T service,
    required super.child,
  }) : _service = service;

  final T _service;

  /// Retrieve the nearest [ServiceProvider<T>] value from the widget tree.
  static T of<T>(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ServiceProvider<T>>();
    assert(provider != null, 'No ServiceProvider<$T> found in the widget tree');
    return provider!._service;
  }

  @override
  bool updateShouldNotify(ServiceProvider<T> old) => _service != old._service;
}
