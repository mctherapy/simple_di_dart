import 'package:mockito/mockito.dart';
import 'package:simple_di/simple_di.dart';
import 'package:simple_di/src/abstraction/service_descriptor.dart';
import 'package:simple_di/src/service_descriptors/scoped_provider.dart';
import 'package:test/test.dart';

import '../mocks/service_container_mock.dart';

const String expectedString = "this is probably the most unnecessary library";
const int dependantSuffix = 4;
String independantFactory(ServiceContainer _) => expectedString;
String dependantFactory(ServiceContainer sp) =>
    expectedString + sp.provide<int>().toString();

void main() {
  group("ScopedProvider", () {
    ServiceContainerMock containerMock = ServiceContainerMock();

    setUp(() {
      containerMock = ServiceContainerMock();
      when(containerMock.provide<int>()).thenReturn(dependantSuffix);
    });

    for (final testCase in GenericTestParams.generateCases()) {
      final GenericTestParams(
        :isGlobal,
        :expectedValue,
        :factory,
        :isFactoryDependant
      ) = testCase;

      // Generates test description based on test case
      String desc(String description) => "$description ${testCase.toString()}";

      test(desc("provideWith() properly constructs value"), () {
        final subject = ScopedProvider<String>(factory, isGlobal);
        expect(subject.provideWith(containerMock), expectedValue);
      });

      test(desc("constructed prop returns false is value was never provided"),
          () {
        final subject = ScopedProvider<String>(factory, isGlobal);
        expect(subject.constructed, false);
      });

      test(
          desc(
              "constructed prop returns true after value was at least once constructed"),
          () {
        final subject = ScopedProvider<String>(factory, isGlobal);
        subject.provideWith(containerMock);
        expect(subject.constructed, true);
      });

      test(desc("factory must only run once"), () {
        var calls = 0;
        final subject = ScopedProvider((sp) {
          calls++;
          return factory(sp);
        }, isGlobal);

        for (final provideCount in List.generate(10, (index) => index + 1)) {
          subject.provideWith(containerMock);

          expect(calls, 1,
              reason:
                  "Factory method must only be called once, but was called again at call: $provideCount");
        }
      });

      test(desc("unsafeProvide() invalid type returns null"), () {
        final subject = ScopedProvider<String>(factory, isGlobal);
        expect(subject.unsafeProvideWith<int>(containerMock), null);
      });

      test(desc("unsafeProvide() valid type returns constructed value"), () {
        final subject = ScopedProvider<String>(factory, isGlobal);
        expect(subject.unsafeProvideWith<String>(containerMock),
            subject.provideWith(containerMock));
      });

      test(desc("scopify() returns ${isGlobal ? "null" : "a copy"}"), () {
        final subject = ScopedProvider<String>(factory, isGlobal);
        final subjectValue = subject.provideWith(containerMock);

        final result = subject.tryCopy();

        if (isGlobal) {
          expect(result, null);
          return;
        }
        expect(result is ServiceProvider<String>, true);
        final typedResult = result as ServiceProvider<String>;

        expect(typedResult.constructed, false,
            reason: "it should be clean state copy");

        if (isFactoryDependant) {
          final expectedSuffix = dependantSuffix + 1;
          when(containerMock.provide<int>()).thenReturn(expectedSuffix);
          final resultValue = typedResult.provideWith(containerMock);
          expect(resultValue != subjectValue, true,
              reason:
                  "Dependant value change should be reflected on scopified copy");
          expect(resultValue, expectedString + expectedSuffix.toString(),
              reason:
                  "Scopified copy should have value created in the same way as original with only change being the dependant value");
        }
      });
    }
  });
}

class GenericTestParams {
  final bool isGlobal;
  final bool isFactoryDependant;

  String get expectedValue => isFactoryDependant
      ? expectedString + dependantSuffix.toString()
      : expectedString;

  const GenericTestParams(
      {required this.isGlobal, required this.isFactoryDependant});

  String Function(ServiceContainer) get factory =>
      isFactoryDependant ? dependantFactory : independantFactory;

  @override
  String toString() {
    return "[isGlobal: $isGlobal, isFactoryDependant: $isFactoryDependant]";
  }

  static List<GenericTestParams> generateCases() {
    return [
      const GenericTestParams(isGlobal: true, isFactoryDependant: true),
      const GenericTestParams(isGlobal: true, isFactoryDependant: false),
      const GenericTestParams(isGlobal: false, isFactoryDependant: false),
      const GenericTestParams(isGlobal: false, isFactoryDependant: true),
    ];
  }
}
