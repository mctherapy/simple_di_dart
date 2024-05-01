import 'package:simple_di/src/disposable.dart';
import 'package:simple_di/src/service_descriptor.dart';
import 'package:simple_di/src/service_lifetime.dart';

import 'service_container.dart';

class ScopedProvider<T> extends ServiceProvider<T> implements Scoped {
  Factory<T>? _factory;
  final bool singleton;
  T? _instance;

  ScopedProvider(Factory<T> factory, this.singleton)
      : super(singleton ? ServiceLifetime.singleton : ServiceLifetime.scoped) {
    if (singleton) {
      _factory = (sp) {
        final result = factory(sp);
        _factory = null;
        return result;
      };
    } else {
      _factory = factory;
    }
  }

  @override
  T provideWith(ServiceContainer sp) {
    _instance ??= _factory!(sp);
    return _instance!;
  }

  @override
  ServiceDescriptor? scopeify() =>
      singleton ? null : ScopedProvider(_factory!, singleton);

  @override
  bool get constructed => _instance != null;

  @override
  void dispose() {
    if (_instance is Disposable) {
      (_instance as Disposable).dispose();
    }
  }

  @override
  TRequested? unsafeProvideWith<TRequested>(ServiceContainer sp) {
    return provideWith(sp) as TRequested?;
  }
}
