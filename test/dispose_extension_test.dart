import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:simple_di/simple_di.dart';

import 'common/disposable_mock.dart';

void main() {
  group("Dispose<T>", () {
    var disposeCalls = 0;
    var subject = DisposableMock();

    setUp(() {
      disposeCalls = 0;
      subject = DisposableMock();
      when(subject.dispose()).thenAnswer((realInvocation) {
        disposeCalls++;
      });
    });

    test("whileAlive() disposes passed instance and called passed function",
        () {
      var called = 0;
      Dispose.of(subject).whileAlive((p0) {
        called++;
        return;
      });

      expect(called, 1);
      expect(disposeCalls, 1);
    });
    test("whileAlive() disposes instance even if error was thrown", () {
      var called = 0;

      expect(
          () => Dispose.of(subject).whileAlive((p0) {
                called++;
                throw Exception();
              }),
          throwsException);

      expect(called, 1);
      expect(disposeCalls, 1);
    });

    test(
        "whileAliveAsync() disposes passed instance and called passed function",
        () async {
      var called = 0;

      await Dispose.of(subject).whileAliveAsync((p0) async {
        called++;
        await Future.delayed(Duration(microseconds: 2));
        return;
      });

      expect(called, 1);
      expect(disposeCalls, 1);
    });
    test("whileAliveAsync() disposes instance even if error was thrown",
        () async {
      var called = 0;
      bool thrown = false;

      try {
        await Dispose.of(subject).whileAliveAsync((p0) async {
          called++;
          await Future.delayed(Duration(microseconds: 2));
          throw Exception();
        });
      } catch (ex) {
        thrown = true;
      }

      expect(thrown, true);
      expect(called, 1);
      expect(disposeCalls, 1);
    });
  });
}
