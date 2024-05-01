import 'package:simple_di/src/abstraction/disposable.dart';

abstract class ServiceContainer implements Disposable {
  /// Provides a registered service of type [T]
  ///
  /// Returns null if service was not registered.
  T? provide<T>();

  T provideRequired<T>();

  /// Creates a new scope.
  ///
  /// For scoped services it will cause creation of completely new instances.
  ServiceContainer createScope();
}
