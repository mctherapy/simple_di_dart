import 'package:mockito/mockito.dart';
import 'package:simple_di/simple_di.dart';
import 'package:simple_di/src/service_descriptors/transient_provider.dart';
import 'package:test/test.dart';

import '../mocks/service_container_mock.dart';

const String expectedString = "this is probably the most unnecessary library";
const int dependantSuffix = 4;
String independantFactory(ServiceContainer _) => expectedString;
String dependantFactory(ServiceContainer sp) =>
    expectedString + sp.provide<int>().toString();

void main() {
  group("TransientProvider", () {
    final containerMock = ServiceContainerMock();

    setUp(() {
      when(containerMock.provide<int>()).thenReturn(dependantSuffix);
    });

    String buildExpectedString(
            {int? overrideSuffix, required bool isFactoryDependant}) =>
        isFactoryDependant
            ? "$expectedString${overrideSuffix ?? dependantSuffix}"
            : expectedString;

    for (final isFactoryDependant in [true, false]) {
      final factory =
          isFactoryDependant ? dependantFactory : independantFactory;

      String desc(String description) =>
          "$description [isFactoryDependant: $isFactoryDependant]";

      test(desc("provideWith() should construct new value each time"), () {
        var calls = 0;
        final subject = TransientProvider<String>((sp) {
          calls++;
          return factory(sp);
        });

        for (final callNumber in List.generate(10, (index) => index + 1)) {
          expect(subject.provideWith(containerMock),
              buildExpectedString(isFactoryDependant: isFactoryDependant),
              reason:
                  "provideWith() should always return the same value if container values didn't change");
          expect(calls, callNumber,
              reason:
                  "provideWith() should always call factory method when providing value");
        }
      });

      test(desc("constructed returns false no matter what"), () {
        final subject = TransientProvider<String>(factory);

        expect(subject.constructed, false,
            reason: "constructed should not return true on clean descriptor");

        subject.provideWith(containerMock);

        expect(subject.constructed, false,
            reason:
                "as transients are not stored, they should not change constructed state even if they were provided");

        subject.unsafeProvideWith<String>(containerMock);
        expect(subject.constructed, false,
            reason:
                "unsafeProvideWith() with valid type should not cause constructed to return true");

        subject.unsafeProvideWith<int>(containerMock);
        expect(subject.constructed, false,
            reason:
                "unsafeProvideWith() with invalid type should not cause constructed to return true");
      });

      test(desc("unsafeProvideWith() with invalid type returns null"), () {
        final subject = TransientProvider<String>(factory);
        expect(subject.unsafeProvideWith<int>(containerMock), null);
      });
    }

    test(
        "provideWith() changes in dependant services should be reflected in constructed values",
        () {
      final subject = TransientProvider<String>(dependantFactory);
      for (final callNumber in List.generate(10, (index) => index + 1)) {
        when(containerMock.provide<int>()).thenReturn(callNumber);

        expect(
            subject.provideWith(containerMock),
            buildExpectedString(
                isFactoryDependant: true, overrideSuffix: callNumber));
      }
    });
    test(
        "unsafeProvideWith() with valid type changes in dependant services should be reflected in constructed values",
        () {
      final subject = TransientProvider<String>(dependantFactory);
      for (final callNumber in List.generate(10, (index) => index + 1)) {
        when(containerMock.provide<int>()).thenReturn(callNumber);

        expect(
            subject.unsafeProvideWith<String>(containerMock),
            buildExpectedString(
                isFactoryDependant: true, overrideSuffix: callNumber));
      }
    });
  });
}
