import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:simple_di/simple_di.dart';
import 'package:test/test.dart';

import 'package:simple_di/src/abstraction/service_descriptor.dart';
@GenerateNiceMocks([MockSpec<ServiceDescriptor>()])
import 'service_container_test.mocks.dart';

const int expectedValue = 4;
void main() {
  group("ServiceContainer", () {
    Map<int, ServiceDescriptor> services = {};
    var subject = ServiceContainer(services);

    configureMock(
        {required ServiceLifetime lifetime,
        int providedValue = expectedValue,
        bool registerInRoot = true}) {
      final expectedValue = 4;
      final descriptor = MockServiceDescriptor();

      when(descriptor.unsafeProvideWith<int>(any)).thenReturn(providedValue);
      when(descriptor.lifetime).thenReturn(lifetime);

      if (registerInRoot) {
        services[expectedValue.runtimeType.hashCode] = descriptor;
      }

      return descriptor;
    }

    setUp(() {
      services = {};
      subject = ServiceContainer(services);
    });

    test("provide() returns null if type was not registered in called instance",
        () {
      expect(subject.provide<int>(), null);
    });

    test("successfuly created scope on empty container", () {
      final scope = subject.createScope();
      expect(scope != subject, true,
          reason: "it should be completely new object");
    });

    for (final lifetime in [
      ServiceLifetime.scoped,
      ServiceLifetime.transient,
      ServiceLifetime.singleton
    ]) {
      desc(String description) => "$description [lifetime: $lifetime]";

      test(
          desc(
              "service ${lifetime == ServiceLifetime.singleton ? "was not disposed" : "was properly disposed"} after scoped container disposal"),
          () {
        final descriptor = MockServiceDescriptor();
        final expectedValue = DisposableImplementation();
        var diposeCalls = 0;

        when(descriptor.lifetime).thenReturn(lifetime);
        when(descriptor.unsafeProvideWith<DisposableImplementation>(any))
            .thenReturn(expectedValue);
        when(descriptor.tryCopy()).thenReturn(descriptor);

        when(expectedValue.dispose()).thenAnswer((realInvocation) {
          diposeCalls++;
        });

        services[expectedValue.runtimeType.hashCode] = descriptor;

        final scopeSubject = subject.createScope();
        final value = scopeSubject.provide<DisposableImplementation>();
        expect(value, expectedValue);

        scopeSubject.dispose();

        if (lifetime != ServiceLifetime.singleton) {
          expect(diposeCalls, 1);
        } else {
          expect(diposeCalls, 0);
        }
      });

      test(
          "successfuly created scope on container containing service of lifetime: $lifetime",
          () {
        configureMock(lifetime: lifetime);
        final scope = subject.createScope();
        expect(scope != subject, true,
            reason: "it should be completely new object");
      });

      test(
          desc(
              "provide() returns value if type was registered in called instance"),
          () {
        configureMock(lifetime: lifetime);

        expect(subject.provide<int>(), expectedValue);
      });

      test(
          desc(
              "provideRequired() returns value if type was registered in called instance"),
          () {
        configureMock(lifetime: lifetime);
        expect(subject.provideRequired<int>(), expectedValue);
      });

      if (lifetime != ServiceLifetime.scoped) {
        test(desc("scoped provide() returns value if root had it registered"),
            () {
          configureMock(lifetime: lifetime);
          final scope = subject.createScope();

          expect(scope.provide<int>(), expectedValue);
        });
      }

      test(
          desc(
              "services are ${lifetime == ServiceLifetime.transient ? "not " : ""}disposed alongside root container"),
          () {
        final descriptor = MockServiceDescriptor();
        final expectedValue = DisposableImplementation();
        var diposeCalls = 0;

        when(descriptor.lifetime).thenReturn(lifetime);
        when(descriptor.unsafeProvideWith<DisposableImplementation>(any))
            .thenReturn(expectedValue);

        when(expectedValue.dispose()).thenAnswer((realInvocation) {
          diposeCalls++;
        });

        services[expectedValue.runtimeType.hashCode] = descriptor;

        final providedValue = subject.provide<DisposableImplementation>();

        expect(providedValue, expectedValue);

        subject.dispose();

        if (lifetime == ServiceLifetime.transient) {
          expect(diposeCalls, 0);
        } else {
          expect(diposeCalls, 1);
        }
      });
    }

    test("scoped provide() returns value from copied descriptor", () {
      final descriptorValue = 1;
      var calls = 0;

      final descriptor = configureMock(
          lifetime: ServiceLifetime.scoped, providedValue: descriptorValue);
      final scopedDescriptor = configureMock(
          lifetime: ServiceLifetime.scoped,
          providedValue: expectedValue,
          registerInRoot: false);

      when(descriptor.tryCopy()).thenAnswer((_) {
        calls++;
        return scopedDescriptor;
      });

      services[expectedValue.runtimeType.hashCode] = descriptor;

      expect(subject.provide<int>(), descriptorValue);
      expect(subject.createScope().provide<int>(), expectedValue);
      expect(calls, 1);
    });

    test("provideRequired() throws if service was not registered", () {
      expect(() => subject.provideRequired<int>(),
          throwsA(TypeMatcher<ServiceNotRegistered>()));
    });
  });
}

class DisposableImplementation extends Mock implements Disposable {}
