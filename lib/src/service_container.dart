import 'package:simple_di/simple_di.dart';
import 'package:simple_di/src/abstraction/service_descriptor.dart';
import 'package:simple_di/src/service_descriptors/scoped_provider.dart';

class ServiceContainer implements Disposable {
  late final Map<int, ServiceDescriptor> _services;
  late final ServiceContainer? _parent;
  late final List<Disposable> _toDispose = [];

  ServiceContainer(this._services) {
    _parent = null;
  }
  ServiceContainer._scope(ServiceContainer parent) {
    _services = parent._services;
    _parent = parent._parent ?? parent;
  }

  T? provide<T>() {
    var descriptor = _services[T.hashCode];
    late final T? service;

    if (descriptor != null) {
      final typedDescriptor = descriptor as ServiceProvider<T>;
      service = typedDescriptor.provideWith(this);

      /// Roots transients are not subjects for disposal
      if (descriptor.lifetime != ServiceLifetime.transient || _parent != null) {
        _tryTrackForDisposal(service);
      }
      return service;
    }

    // Fallback
    return _provideFromParent(descriptor);
  }

  T? _provideFromParent<T>(ServiceDescriptor? descriptor) {
    if (_parent == null) return null;

    late final T? service;
    descriptor = _parent._services[T.hashCode];

    switch (descriptor) {
      /// Singletons are not subject of disposal in scoped containers
      case ServiceDescriptor(lifetime: ServiceLifetime.singleton):
        return descriptor.unsafeProvideWith<T>(this);

      /// Transients are subject for scoped disposal if it's not root
      case ServiceDescriptor(lifetime: ServiceLifetime.transient):
        service = descriptor.unsafeProvideWith<T>(this);
        break;

      /// Scoped descriptors are copied to current container,
      /// in case scopeify() fails, it falls back to original implementation.
      ///
      /// In case it succeeds, new descriptor is saved for further use and
      /// service constructed.
      case ScopedProvider<T> descriptor:
        final typedDescriptor = descriptor.scopeify();

        if (typedDescriptor == null) {
          return descriptor.unsafeProvideWith<T>(this);
        }

        _services[T.hashCode] = typedDescriptor;
        service = typedDescriptor.unsafeProvideWith(this);
        break;

      default:
        return null;
    }

    _tryTrackForDisposal(service);
    return service;
  }

  /// Tracks service for disposal if it's of [Disposable] type and is not already
  /// on the list.
  void _tryTrackForDisposal<T>(T disposable) {
    if (disposable is Disposable && !_toDispose.contains(disposable)) {
      _toDispose.add(disposable as Disposable);
    }
  }

  T provideRequired<T>() {
    final instance = provide<T>();

    if (instance == null) throw ServiceNotRegistered(T);
    return instance;
  }

  /// Creates a new scope.
  ///
  /// For scoped services it will cause creation of completely new instances.
  ServiceContainer createScope() {
    return ServiceContainer._scope(this);
  }

  /// Cleans up all [Destructable]s constructed in current instance.
  @override
  void dispose() {
    for (final disposable in _toDispose) {
      disposable.dispose();
    }
  }
}
