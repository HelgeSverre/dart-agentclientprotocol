import 'dart:async';

import 'package:acp/src/protocol/cancellation.dart';
import 'package:test/test.dart';

void main() {
  group('AcpCancellationSource', () {
    test('token starts uncanceled', () {
      final source = AcpCancellationSource();
      expect(source.token.isCanceled, isFalse);
    });

    test('cancel sets isCanceled', () {
      final source = AcpCancellationSource();
      source.cancel();
      expect(source.token.isCanceled, isTrue);
    });

    test('cancel completes whenCanceled', () async {
      final source = AcpCancellationSource();
      var completed = false;
      unawaited(source.token.whenCanceled.then((_) => completed = true));
      source.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(completed, isTrue);
    });

    test('throwIfCanceled does nothing when not canceled', () {
      final source = AcpCancellationSource();
      expect(() => source.token.throwIfCanceled(), returnsNormally);
    });

    test('throwIfCanceled throws CanceledException when canceled', () {
      final source = AcpCancellationSource();
      source.cancel('test reason');
      expect(
        () => source.token.throwIfCanceled(),
        throwsA(isA<CanceledException>()),
      );
    });

    test('cancel is idempotent', () {
      final source = AcpCancellationSource();
      source.cancel('first');
      source.cancel('second');
      expect(source.token.isCanceled, isTrue);
    });

    test('CanceledException preserves reason', () {
      final source = AcpCancellationSource();
      source.cancel('the reason');
      try {
        source.token.throwIfCanceled();
      } on CanceledException catch (e) {
        expect(e.reason, 'the reason');
        expect(e.toString(), contains('the reason'));
      }
    });

    test(
      'cooperative cancellation: whenCanceled wins a race with work',
      () async {
        // Simulates a long-running handler racing its work against the
        // cancel signal — the canonical cooperative-cancel pattern. If the
        // handler returns the result of `Future.any([work, cancel])`, the
        // cancellation should resolve the future as soon as `cancel()` is
        // called, not wait for `work` to complete.
        final source = AcpCancellationSource();
        final work = Completer<String>();
        final racer = Future.any<Object?>([
          work.future,
          source.token.whenCanceled,
        ]);

        source.cancel();
        await racer;
        expect(source.token.isCanceled, isTrue);
        expect(work.isCompleted, isFalse);
      },
    );
  });
}
