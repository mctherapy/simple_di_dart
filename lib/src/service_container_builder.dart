import 'package:simple_di/src/disposable.dart';
import 'package:simple_di/src/errors/service_not_registered.dart';
import 'package:simple_di/src/scoped_provider.dart';
import 'package:simple_di/src/service_descriptor.dart';
import 'package:simple_di/src/service_lifetime.dart';
import 'package:simple_di/src/transient_provider.dart';

import 'service_container.dart';

class ServiceContainerBuilder extends ServiceContainer {
  late final Map<int, ServiceDescriptor> _services;
  late final ServiceContainerBuilder? _parent;
  late final List<Disposable> _toDispose = [];
  bool _sealed = false;

  ServiceContainerBuilder._createScope(ServiceContainerBuilder parent) {
    _services = {};
    _sealed = true;
    _parent = parent;
  }

  ServiceContainerBuilder() {
    _services = {};
    _parent = null;
  }

  /// Adds a service registration to the current container
  ///
  /// Throws if container was sealed beforehand
  ServiceContainerBuilder add<T>(T Function(ServiceContainer) builder,
      {ServiceLifetime lifetime = ServiceLifetime.singleton}) {
    if (_sealed) throw Exception("Cannot register service in sealed container");

    final descriptor = switch (lifetime) {
      ServiceLifetime.singleton => ScopedProvider(builder, true),
      ServiceLifetime.scoped => ScopedProvider(builder, false),
      ServiceLifetime.transient => TransientProvider(builder),
    };

    _services[T.hashCode] = descriptor;

    return this;
  }

  @override
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

  @override
  T provideRequired<T>() {
    final instance = provide<T>();

    if (instance == null) throw ServiceNotRegistered(T);
    return instance;
  }

  /// Creates a new scope.
  ///
  /// Providing scoped services from the constructed container will cause
  /// creation of new instances of those services.
  ///
  /// Singleton and Transient services will behave normally.
  @override
  ServiceContainer createScope() =>
      ServiceContainerBuilder._createScope(_parent ?? this);

  /// Seals current container preventing any further registrations
  ServiceContainer seal() {
    _sealed = true;

    return this;
  }

  /// Tracks service for disposal if it's of [Disposable] type and is not already
  /// on the list.
  void _tryTrackForDisposal<T>(T disposable) {
    if (disposable is Disposable && !_toDispose.contains(disposable)) {
      _toDispose.add(disposable as Disposable);
    }
  }

  /// Cleans up all [Destructable]s constructed in current instance.
  @override
  void dispose() {
    for (final disposable in _toDispose) {
      disposable.dispose();
    }
  }
}
