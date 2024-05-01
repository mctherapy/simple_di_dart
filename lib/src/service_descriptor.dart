import 'service_container.dart';
import 'service_lifetime.dart';

abstract class ServiceDescriptor {
  final ServiceLifetime lifetime;
  bool get constructed;
  const ServiceDescriptor(this.lifetime);

  TRequested? unsafeProvideWith<TRequested>(ServiceContainer sp);
}

abstract class Scoped {
  ServiceDescriptor? scopeify();
}

abstract class ServiceProvider<T> extends ServiceDescriptor {
  const ServiceProvider(super.lifetime);
  T provideWith(ServiceContainer sp);
}

typedef Factory<T> = T Function(ServiceContainer);
