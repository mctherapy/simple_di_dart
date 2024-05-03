import 'package:simple_di/src/abstraction/service_descriptor.dart';
import 'package:simple_di/src/service_lifetime.dart';

import '../service_container.dart';

class ScopedProvider<T> extends ServiceProvider<T> implements Scoped {
  Factory<T>? _factory;
  final bool isGlobal;
  T? _instance;

  ScopedProvider(Factory<T> factory, this.isGlobal)
      : super(isGlobal ? ServiceLifetime.singleton : ServiceLifetime.scoped) {
    if (isGlobal) {
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
      isGlobal ? null : ScopedProvider(_factory!, isGlobal);

  @override
  bool get constructed => _instance != null;

  @override
  TRequested? unsafeProvideWith<TRequested>(ServiceContainer sp) {
    return T == TRequested ? provideWith(sp) as TRequested? : null;
  }
}
