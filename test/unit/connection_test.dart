import 'package:acp/src/protocol/connection.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/protocol/protocol_warning.dart';
import 'package:test/test.dart';

import '../helpers/mock_transport.dart';

void main() {
  group('Connection lifecycle', () {
    test('starts in idle state', () {
      final transport = MockTransport();
      final conn = Connection(transport);
      expect(conn.state, ConnectionState.idle);
    });

    test('start transitions to opening', () {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      expect(conn.state, ConnectionState.opening);
    });

    test('markOpen transitions to open', () {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      expect(conn.state, ConnectionState.open);
    });

    test('close transitions to closed', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      await conn.close();
      expect(conn.state, ConnectionState.closed);
    });

    test('start throws if not idle', () {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      expect(() => conn.start(), throwsStateError);
    });

    test('markOpen throws if not opening', () {
      final transport = MockTransport();
      final conn = Connection(transport);
      expect(() => conn.markOpen(), throwsStateError);
    });

    test('sendRequest throws when closed', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      await conn.close();
      expect(
        () => conn.sendRequest('test', null),
        throwsA(isA<ConnectionClosedException>()),
      );
    });

    test('notify throws when closed', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();
      await conn.close();
      expect(
        () => conn.notify('test'),
        throwsA(isA<ConnectionClosedException>()),
      );
    });

    test('transport EOF transitions to closed', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      final states = <ConnectionState>[];
      conn.onStateChange.listen(states.add);

      await transport.simulateClose();
      // Give event loop time to process
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(conn.state, ConnectionState.closed);
    });
  });

  group('Request/response correlation', () {
    test('sendRequest writes a request and returns response result', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      final future = conn.sendRequest('initialize', {'protocolVersion': 1});

      // Wait for the write to be processed
      await Future<void>.delayed(Duration.zero);
      expect(transport.sent, hasLength(1));
      final sentReq = transport.sent.first as JsonRpcRequest;
      expect(sentReq.method, 'initialize');

      // Simulate response
      transport.receive(JsonRpcResponse(
        id: sentReq.id,
        result: {'protocolVersion': 1},
      ));

      final result = await future;
      expect(result['protocolVersion'], 1);

      await conn.close();
    });

    test('sendRequest rejects with RpcErrorException on error response',
        () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      final future = conn.sendRequest('bad_method', null);
      await Future<void>.delayed(Duration.zero);

      final sentReq = transport.sent.first as JsonRpcRequest;
      transport.receive(JsonRpcResponse(
        id: sentReq.id,
        error: const JsonRpcError(
          code: -32601,
          message: 'Method not found',
        ),
      ));

      await expectLater(future, throwsA(isA<RpcErrorException>()));

      await conn.close();
    });

    test('pending requests fail on close', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      Object? caughtError;
      final future = conn.sendRequest('slow_method', null).catchError((
        Object e,
      ) {
        caughtError = e;
        return <String, dynamic>{};
      });
      await Future<void>.delayed(Duration.zero);

      await conn.close();
      await future;

      expect(caughtError, isA<ConnectionClosedException>());
    });
  });

  group('Notification handling', () {
    test('sends notifications without expecting response', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      await conn.notify('session/cancel', {'sessionId': 's1'});

      expect(transport.sent, hasLength(1));
      expect(transport.sent.first, isA<JsonRpcNotification>());
      final notif = transport.sent.first as JsonRpcNotification;
      expect(notif.method, 'session/cancel');

      await conn.close();
    });
  });

  group('Request handler dispatch', () {
    test('dispatches incoming requests to registered handlers', () async {
      final transport = MockTransport();
      final conn = Connection(transport);

      conn.setRequestHandler('test/echo', (req, cancel) async {
        return req.params ?? {};
      });

      conn.start();
      conn.markOpen();

      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'test/echo',
        params: {'hello': 'world'},
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(transport.sent, hasLength(1));
      final resp = transport.sent.first as JsonRpcResponse;
      expect(resp.id, 1);
      expect(resp.isSuccess, isTrue);
      expect((resp.result! as Map<String, dynamic>)['hello'], 'world');

      await conn.close();
    });

    test('returns METHOD_NOT_FOUND for unknown methods', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      conn.start();
      conn.markOpen();

      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'nonexistent',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(transport.sent, hasLength(1));
      final resp = transport.sent.first as JsonRpcResponse;
      expect(resp.isError, isTrue);
      expect(resp.error!.code, -32601);

      await conn.close();
    });

    test('routes _-prefixed methods to extension handler', () async {
      final transport = MockTransport();
      final conn = Connection(transport);

      conn.setExtensionRequestHandler((req, cancel) async {
        return {'ext': true, 'method': req.method};
      });

      conn.start();
      conn.markOpen();

      transport.receive(const JsonRpcRequest(
        id: 1,
        method: '_vendor/custom',
        params: {'data': 42},
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(transport.sent, hasLength(1));
      final resp = transport.sent.first as JsonRpcResponse;
      expect(resp.isSuccess, isTrue);
      expect((resp.result! as Map<String, dynamic>)['ext'], true);

      await conn.close();
    });
  });

  group('Tracing hooks', () {
    test('onSend is called before writing', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      final traced = <Map<String, dynamic>>[];
      conn.onSend = traced.add;

      conn.start();
      conn.markOpen();
      await conn.notify('test');

      expect(traced, hasLength(1));
      expect(traced.first['method'], 'test');

      await conn.close();
    });

    test('onReceive is called for incoming messages', () async {
      final transport = MockTransport();
      final conn = Connection(transport);
      final traced = <Map<String, dynamic>>[];
      conn.onReceive = traced.add;

      conn.setRequestHandler('ping', (_, __) async => {'pong': true});
      conn.start();
      conn.markOpen();

      transport.receive(const JsonRpcRequest(id: 1, method: 'ping'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(traced, hasLength(1));
      expect(traced.first['method'], 'ping');

      await conn.close();
    });
  });

  group('Late response handling', () {
    test('emits warning for late responses', () async {
      final transport = MockTransport();
      final conn = Connection(
        transport,
        defaultTimeout: const Duration(milliseconds: 50),
      );

      final warnings = <ProtocolWarning>[];
      conn.warnings.listen(warnings.add);

      conn.start();
      conn.markOpen();

      final future = conn.sendRequest('slow', null).catchError((Object e) {
        return <String, dynamic>{};
      });
      await Future<void>.delayed(Duration.zero);
      final reqId = (transport.sent.first as JsonRpcRequest).id;

      // Wait for timeout
      await future;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Send late response
      transport.receive(JsonRpcResponse(id: reqId, result: {}));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(warnings, hasLength(1));
      expect(warnings.first, isA<LateResponseWarning>());

      await conn.close();
    });
  });
}
