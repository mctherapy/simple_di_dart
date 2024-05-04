import 'package:simple_di/simple_di.dart';
import 'package:simple_di/src/service_descriptors/scoped_provider.dart';
import 'package:simple_di/src/abstraction/service_descriptor.dart';
import 'package:simple_di/src/service_descriptors/transient_provider.dart';

class ServiceContainerBuilder {
  late final Map<int, ServiceDescriptor> _services;
  bool _sealed = false;
  get sealed => _sealed;

  ServiceContainerBuilder() {
    _services = {};
  }

  /// Adds a service registration to the current container
  ///
  /// Throws [ContainerSealed] if container was sealed beforehand
  ServiceContainerBuilder add<T>(T Function(ServiceContainer) builder,
      {ServiceLifetime lifetime = ServiceLifetime.singleton}) {
    if (_sealed) throw ContainerSealed();

    final descriptor = switch (lifetime) {
      ServiceLifetime.singleton => ScopedProvider(builder, true),
      ServiceLifetime.scoped => ScopedProvider(builder, false),
      ServiceLifetime.transient => TransientProvider(builder),
    };

    _services[T.hashCode] = descriptor;

    return this;
  }

  ServiceContainer build() {
    _sealed = true;
    return ServiceContainer(_services);
  }
}
