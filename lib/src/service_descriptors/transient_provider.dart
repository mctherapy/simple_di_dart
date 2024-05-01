import 'package:simple_di/src/abstraction/service_descriptor.dart';
import 'package:simple_di/src/service_lifetime.dart';

import '../abstraction/service_container.dart';

class TransientProvider<T> extends ServiceProvider<T> {
  final Factory<T> _factory;
  TransientProvider(this._factory) : super(ServiceLifetime.transient);

  @override
  bool get constructed => false;

  @override
  T provideWith(ServiceContainer sp) {
    return _factory(sp);
  }

  @override
  TRequested? unsafeProvideWith<TRequested>(ServiceContainer sp) =>
      T == TRequested ? provideWith(sp) as TRequested : null;
}
