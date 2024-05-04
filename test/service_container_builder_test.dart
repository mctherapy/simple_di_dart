import 'package:simple_di/simple_di.dart';
import 'package:test/test.dart';

void main() {
  group("ServiceContainerBuilder", () {
    var subject = ServiceContainerBuilder();

    setUp(() => subject = ServiceContainerBuilder());

    test("builder throws when called add() after building ServiceContainer",
        () {
      subject.build();
      expect(() => subject.add((sp) => 3),
          throwsA(TypeMatcher<ContainerSealed>()));
    });

    test("sealed returns false when builder didn't create ServiceContainer",
        () {
      expect(subject.sealed, false);
    });

    test("sealed returns true when builder created ServiceContainer", () {
      subject.build();
      expect(subject.sealed, true);
    });

    for (final lifetime in ServiceLifetime.values) {
      test(
          "properly constructed descriptor for $lifetime and created container",
          () {
        final singletonValue = 1;
        var currentValue = 0;

        subject.add((p0) => ++currentValue, lifetime: lifetime);

        final container = subject.build();

        // Root container
        for (final index in List.generate(10, (index) => index)) {
          final providedValue = container.provide<int>();

          switch (lifetime) {
            case ServiceLifetime.scoped || ServiceLifetime.singleton:
              expect(providedValue, singletonValue,
                  reason:
                      "singleton and scoped values for root container should be constructed only once (problem at index: $index)");
              break;
            case ServiceLifetime.transient:
              expect(providedValue, currentValue,
                  reason:
                      "transient service should be constructed each time it was provided (problem at index: $index)");
              break;
          }
        }

        final scopedContainer = container.createScope();

        // Scoped container
        for (final index in List.generate(10, (index) => index)) {
          final providedValue = scopedContainer.provide<int>();

          switch (lifetime) {
            case ServiceLifetime.singleton:
              expect(providedValue, singletonValue,
                  reason:
                      "singleton values for scoped container should be constructed only once (problem at index: $index)");
              break;
            case ServiceLifetime.scoped:
              expect(providedValue, singletonValue + 1,
                  reason:
                      "scoped service should be constructed twice, once for root and once for scoped (problem at index: $index)");
              break;
            case ServiceLifetime.transient:
              expect(providedValue, currentValue,
                  reason:
                      "transient service should be constructed each time it was provided (problem at index: $index)");
              break;
          }
        }
      });
    }
  });
}
