import 'dart:async';

import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/connection.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:test/test.dart';

import '../helpers/mock_transport.dart';

void main() {
  group('Write queue serialization', () {
    test('concurrent sendRequest calls produce messages in call order', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      addTearDown(() => conn.close());

      final futureA = conn.sendRequest('method_a', null);
      final futureB = conn.sendRequest('method_b', null);
      final futureC = conn.sendRequest('method_c', null);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(transport.sent, hasLength(3));
      final methods = transport.sent
          .cast<JsonRpcRequest>()
          .map((JsonRpcRequest r) => r.method)
          .toList();
      expect(methods, ['method_a', 'method_b', 'method_c']);

      // Respond to all requests so they complete cleanly.
      for (final msg in transport.sent) {
        final req = msg as JsonRpcRequest;
        transport.receive(
          JsonRpcResponse(id: req.id, result: <String, dynamic>{}),
        );
      }

      await Future.wait<Map<String, dynamic>>([futureA, futureB, futureC]);
    });
  });

  group('Request timeout', () {
    test('request times out after specified duration', () async {
      final transport = MockTransport();
      final conn = Connection(
        transport,
        defaultTimeout: const Duration(milliseconds: 100),
      );
      conn.start();
      conn.markOpen();
      addTearDown(() => conn.close());

      await expectLater(
        conn.sendRequest('slow', null),
        throwsA(isA<RequestTimeoutException>()),
      );

      // Late response should not throw — pending request was already cleaned up.
      if (transport.sent.isNotEmpty) {
        final req = transport.sent.first as JsonRpcRequest;
        transport.receive(
          JsonRpcResponse(id: req.id, result: <String, dynamic>{}),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('per-request timeout overrides default', () async {
      final transport = MockTransport();
      final conn = Connection(
        transport,
        defaultTimeout: const Duration(seconds: 60),
      );
      conn.start();
      conn.markOpen();
      addTearDown(() => conn.close());

      await expectLater(
        conn.sendRequest(
          'slow',
          null,
          timeout: const Duration(milliseconds: 100),
        ),
        throwsA(isA<RequestTimeoutException>()),
      );
    });
  });

  group('Cancellation', () {
    test('cancel token cancels pending request', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      addTearDown(() => conn.close());

      final source = AcpCancellationSource();
      final future = conn.sendRequest('work', null, cancelToken: source.token);

      // Cancel before response arrives.
      source.cancel();

      await expectLater(future, throwsA(isA<RequestCanceledException>()));
    });

    test('already-canceled token rejects immediately', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      addTearDown(() => conn.close());

      final source = AcpCancellationSource();
      source.cancel();

      expect(
        () => conn.sendRequest('work', null, cancelToken: source.token),
        throwsA(isA<RequestCanceledException>()),
      );
    });
  });

  group('Close during pending requests', () {
    test('close() during pending request fails it with '
        'ConnectionClosedException', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      final completer = Completer<Object>();
      unawaited(
        conn.sendRequest('pending', null).then(
              (_) => completer.complete('no-error'),
              onError: (Object e) => completer.complete(e),
            ),
      );
      await conn.close();
      final error = await completer.future;
      expect(error, isA<ConnectionClosedException>());
    });

    test('multiple pending requests all fail on close', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      final completers = <Completer<Object>>[];
      for (final method in ['a', 'b', 'c']) {
        final completer = Completer<Object>();
        completers.add(completer);
        unawaited(
          conn.sendRequest(method, null).then(
                (_) => completer.complete('no-error'),
                onError: (Object e) => completer.complete(e),
              ),
        );
      }

      await conn.close();

      for (final completer in completers) {
        final error = await completer.future;
        expect(error, isA<ConnectionClosedException>());
      }
    });
  });

  group('Transport error handling', () {
    test('transport error transitions to closed state', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      transport.simulateError(Exception('boom'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(conn.state, ConnectionState.closed);
    });

    test('transport EOF transitions to closed state', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      await transport.simulateClose();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(conn.state, ConnectionState.closed);
    });
  });

  group('Send after close', () {
    test('sendRequest after close throws ConnectionClosedException', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      await conn.close();

      expect(
        () => conn.sendRequest('late', null),
        throwsA(isA<ConnectionClosedException>()),
      );
    });

    test('notify after close throws ConnectionClosedException', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      await conn.close();

      expect(
        () => conn.notify('late'),
        throwsA(isA<ConnectionClosedException>()),
      );
    });

    test('sendResponse after close throws ConnectionClosedException', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      await conn.close();

      expect(
        () => conn.sendResponse(
          const JsonRpcResponse(id: 999, result: <String, dynamic>{}),
        ),
        throwsA(isA<ConnectionClosedException>()),
      );
    });
  });

  group('Double close', () {
    test('calling close() twice is safe', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      await conn.close();
      await conn.close(); // Should not throw.

      expect(conn.state, ConnectionState.closed);
    });
  });

  group('State change events', () {
    test('onStateChange emits correct sequence', () async {
      final transport = MockTransport();
      final conn = Connection(transport);

      final states = <ConnectionState>[];
      conn.onStateChange.listen(states.add);

      conn.start();
      conn.markOpen();
      await conn.close();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, [
        ConnectionState.opening,
        ConnectionState.open,
        ConnectionState.closing,
        ConnectionState.closed,
      ]);
    });
  });
}
