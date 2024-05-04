import '../service_container.dart';
import '../service_lifetime.dart';

abstract class ServiceDescriptor {
  final ServiceLifetime lifetime;
  bool get constructed;
  const ServiceDescriptor(this.lifetime);

  /// Provides a value described by a descriptor.
  ///
  /// This is internal method used by default Service Container!
  ///
  /// If you wish to use it, check properly if requested descriptor holds type you ask for!
  TRequested? unsafeProvideWith<TRequested>(ServiceContainer sp);
  ServiceDescriptor? tryCopy() => null;
}

abstract class ServiceProvider<T> extends ServiceDescriptor {
  const ServiceProvider(super.lifetime);
  T provideWith(ServiceContainer sp);
}

typedef Factory<T> = T Function(ServiceContainer);
