import 'package:simple_di/simple_di.dart';
import 'package:simple_di/src/errors/global_container_not_registered.dart';

ServiceContainer? _scope;

/// Registers passed container for use by [ScopeInjected] and [Injected] mixins
void registerGlobalContainer(ServiceContainer? container) {
  _scope = container;
}

T? inject<T>() {
  return getCurrentScope().provide<T>();
}

T injectRequired<T>() {
  return getCurrentScope().provideRequired<T>();
}

ServiceContainer getCurrentScope() {
  if (_scope == null) throw GlobalContainerNotRegistered();
  return _scope as ServiceContainer;
}

mixin Injected {
  final ServiceContainer _currentScope = getCurrentScope();

  T? inject<T>() {
    return _currentScope.provide<T>();
  }

  T injectRequired<T>() {
    return _currentScope.provideRequired<T>();
  }
}

mixin Scoped implements Disposable {
  late final ServiceContainer? _currentScope;

  @override
  void dispose() {
    _currentScope?.dispose();
  }

  T provideInScope<T>(T Function(ServiceContainer) injector) {
    final previousScope = getCurrentScope();
    _currentScope ??= previousScope.createScope();

    registerGlobalContainer(_currentScope!);
    final result = injector.call(_currentScope);
    registerGlobalContainer(previousScope);

    return result;
  }
}
