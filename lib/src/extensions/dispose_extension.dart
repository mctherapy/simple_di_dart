import 'dart:async';

import 'package:simple_di/simple_di.dart';

extension type Dispose<T extends Disposable>._(T instance) {
  Dispose.of(this.instance);

  /// Perform a function specified as an argument, but also
  /// disposes [TSelf] instance before returning result.
  TResult whileAlive<TResult>(TResult Function(T) func) {
    final result = func(this as T);
    instance.dispose();
    return result;
  }

  /// Perform a function specified as an argument, but also
  /// disposes [TSelf] instance before returning result.
  Future<TResult> whileAliveAsync<TResult>(
      Future<TResult> Function(T) func) async {
    final result = await func(this as T);
    instance.dispose();
    return result;
  }
}
