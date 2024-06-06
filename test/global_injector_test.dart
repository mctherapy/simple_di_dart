import 'package:mockito/mockito.dart';
import 'package:simple_di/simple_di.dart';
import 'package:simple_di/src/errors/global_container_not_registered.dart';
import 'package:simple_di/src/global_injector.dart';
import 'package:test/test.dart';

import 'common/disposable_mock.dart';

// ignore: constant_identifier_names, non_constant_identifier_names
var EXPECTED_INTEGER = 4;

typedef DescriptionBuilder = String Function(String description);

void main() {
  test("[Scoped] disposes scope successfully", () {
    var disposeCalls = 0;
    final subject = DisposableMock();
    when(subject.dispose()).thenAnswer((invocation) {
      disposeCalls++;
    });

    registerGlobalContainer(ServiceContainerBuilder()
        .add((p0) => subject, lifetime: ServiceLifetime.scoped)
        .add((p0) => 4)
        .build()
        .createScope());

    final scoped = ScopedMock();
    scoped.scope.provide<DisposableMock>();
    scoped.dispose();

    expect(disposeCalls, 1);

    registerGlobalContainer(null);
  });
  group('Global Functional Injectors', () {
    test(("inject<T>() throws when scope == null"), () {
      registerGlobalContainer(null);
      try {
        inject<int>();
      } on Exception catch (ex) {
        expect(ex.runtimeType, GlobalContainerNotRegistered);
      }
    });
    test(("injectRequired<T>() throws when scope == null"), () {
      registerGlobalContainer(null);
      try {
        inject<int>();
      } on Exception catch (ex) {
        expect(ex.runtimeType, GlobalContainerNotRegistered);
      }
    });
  });

  test("[Injected] fails to construct when global scope is null", () {
    bool thrown = false;
    try {
      DependencyMock();
    } on GlobalContainerNotRegistered {
      thrown = true;
    }

    expect(thrown, true);
  });

  runTests(true, globalFunctionalInjectorsTests);
  runTests(false, globalFunctionalInjectorsTests);
  runTests(true, injectedTests);
  runTests(false, injectedTests);
  runTests(true, scopedTests);
  runTests(false, scopedTests);
}

void runTests(bool scoped, void Function(DescriptionBuilder) testsRunner) {
  desc(String description) => "(${scoped ? "Scoped" : "Root"}) $description";
  testsRunner.call(desc);
}

globalFunctionalInjectorsTests(DescriptionBuilder desc) {
  group(desc("Global Functional Injectors"), () {
    setUp(() {
      final container =
          ServiceContainerBuilder().add((sp) => EXPECTED_INTEGER).build();
      registerGlobalContainer(container);
    });

    tearDown(() {
      registerGlobalContainer(null);
    });

    test(desc("inject<T>() injected service"), () {
      expect(inject<int>(), EXPECTED_INTEGER);
    });

    test(desc("injectRequired<T>() injected service"), () {
      expect(injectRequired<int>(), EXPECTED_INTEGER);
    });

    test(desc("inject<T>() returns null if service was not registered"), () {
      expect(inject<String>(), null);
    });

    test(
        desc("injectRequired<T>() should throw ServiceNotRegistered"
            "when service was not registered"), () {
      try {
        injectRequired<String>();
      } on Exception catch (ex) {
        expect(ex.runtimeType, ServiceNotRegistered);
      }
    });
  });
}

injectedTests(DescriptionBuilder desc) {
  buildCurrentlyExpected() => DependencyMock.buildResult(injectRequired<int>());
  group("Injected", () {
    setUp(() {
      var value = 0;
      final container = ServiceContainerBuilder()
          .add((p0) => value++, lifetime: ServiceLifetime.scoped)
          .build();

      registerGlobalContainer(container);
    });

    tearDown(() => registerGlobalContainer(null));

    test(
        desc("[Injected] provides during construction sucessfully "
            "within same scope"), () {
      final expected = buildCurrentlyExpected();

      expect(DependencyMock().resultFromConstructedDependency(), expected);
    });

    test(
        desc("[Injected] provides during method injection sucessfully "
            "within same scope"), () {
      final expected = buildCurrentlyExpected();

      expect(DependencyMock().resultFromInjectedDependency(), expected);
    });
    test(
        desc("[Injected] provides during construction sucessfully "
            "and retains previous scope"
            "when global scope changes"), () {
      final instance = DependencyMock();
      final expected = buildCurrentlyExpected();

      registerGlobalContainer(getCurrentScope().createScope());
      expect(expected == buildCurrentlyExpected(), false);

      expect(instance.resultFromConstructedDependency(), expected);
    });

    test(
        desc("[Injected] provides during method injection sucessfully "
            "and retains previous scope "
            "when global scope changes"), () {
      final instance = DependencyMock();
      final expected = buildCurrentlyExpected();

      registerGlobalContainer(getCurrentScope().createScope());
      expect(expected == buildCurrentlyExpected(), false);

      expect(instance.resultFromInjectedDependency(), expected);
    });
  });
}

scopedTests(DescriptionBuilder desc) {
  buildCurrentlyExpected() =>
      DependencyMock.buildResult(injectRequired<int>() + 1);
  group("Scoped", () {
    setUp(() {
      final container = ServiceContainerBuilder()
          .add((sp) => EXPECTED_INTEGER++, lifetime: ServiceLifetime.scoped)
          .build();
      registerGlobalContainer(container);
    });

    tearDown(() {
      registerGlobalContainer(null);
    });

    test(
        desc(
            "[Scoped] constructed message from provideInScope() shows expected value"),
        () {
      final expected = buildCurrentlyExpected();
      expect(ScopedMock().resultFromConstructedDependency(), expected);
    });
    test(
        desc(
            "[Scoped] injected message from provideInScope() shows expected value"),
        () {
      final currentExpectedInteger = EXPECTED_INTEGER;
      final expected = buildCurrentlyExpected();
      final scoped = ScopedMock();
      expect(scoped.resultFromInjectedDependency(), expected);

      // new scope
      registerGlobalContainer(getCurrentScope().createScope());
      expect(inject<int>(), currentExpectedInteger + 2);
      expect(scoped.resultFromInjectedDependency(), expected);
    });
  });
}

class DependencyMock with Injected {
  final int _value = injectRequired<int>();

  resultFromConstructedDependency() => buildResult(_value);
  resultFromInjectedDependency() => buildResult(this.injectRequired<int>());

  static buildResult(int expectedValue) => "Hello world $expectedValue";
}

class ScopedMock with Scoped {
  late String _value;

  ServiceContainer get scope => provideInScope((scope) => scope);
  ScopedMock() {
    _value = _buildScopedResult();
  }

  resultFromConstructedDependency() => _value;

  resultFromInjectedDependency() => _buildScopedResult();

  _buildScopedResult() =>
      provideInScope((scope) => buildResult(scope.provideRequired<int>()));

  static buildResult(int expectedValue) => "Hello world $expectedValue";
}
