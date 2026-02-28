import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/capability_enforcement.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/client_side_connection.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

import '../helpers/mock_transport.dart';

/// Minimal handler that records calls.
class _TestHandler extends ClientHandler {
  final List<String> calls = [];

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    calls.add('sessionUpdate:$sessionId');
  }
}

/// Handler that implements readTextFile.
class _FsHandler extends ClientHandler {
  final List<String> calls = [];

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    calls.add('sessionUpdate:$sessionId');
  }

  @override
  Future<ReadTextFileResponse> readTextFile(
    ReadTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('readTextFile:${request.path}');
    return const ReadTextFileResponse(content: 'file data');
  }
}

/// Sends an initialize request from the agent side (simulated) and returns
/// the response future.
Future<void> _performInitialize(
  MockTransport transport,
  ClientSideConnection conn, {
  bool loadSession = false,
}) async {
  final future = conn.sendInitialize(protocolVersion: 1);

  await Future<void>.delayed(const Duration(milliseconds: 20));

  // Find the outgoing initialize request
  final req = transport.sent.whereType<JsonRpcRequest>().first;

  // Simulate agent response
  transport.receive(JsonRpcResponse(
    id: req.id,
    result: <String, dynamic>{
      'protocolVersion': 1,
      'agentCapabilities': <String, dynamic>{
        'loadSession': loadSession,
        'promptCapabilities': <String, dynamic>{},
        'mcpCapabilities': <String, dynamic>{},
        'sessionCapabilities': <String, dynamic>{},
      },
      'authMethods': <dynamic>[],
    },
  ));

  await future;
}

void main() {
  group('ClientSideConnection', () {
    test('sendInitialize sends request and stores remote capabilities',
        () async {
      final transport = MockTransport();
      final conn = ClientSideConnection(
        transport,
        handler: _TestHandler(),
      );

      expect(conn.remoteCapabilities, isNull);

      await _performInitialize(transport, conn, loadSession: true);

      expect(conn.remoteCapabilities, isNotNull);
      expect(conn.remoteCapabilities!.loadSession, isTrue);

      await conn.close();
    });

    test('sendInitialize transitions to open', () async {
      final transport = MockTransport();
      final conn = ClientSideConnection(
        transport,
        handler: _TestHandler(),
      );

      expect(conn.state, ConnectionState.opening);

      await _performInitialize(transport, conn);

      expect(conn.state, ConnectionState.open);

      await conn.close();
    });

    test('sendNewSession sends session/new request, returns typed response',
        () async {
      final transport = MockTransport();
      final conn = ClientSideConnection(
        transport,
        handler: _TestHandler(),
      );

      await _performInitialize(transport, conn);
      transport.sent.clear();

      final future = conn.sendNewSession(cwd: '/tmp');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(transport.sent, hasLength(1));
      final req = transport.sent.first as JsonRpcRequest;
      expect(req.method, 'session/new');
      expect(req.params!['cwd'], '/tmp');

      transport.receive(JsonRpcResponse(
        id: req.id,
        result: const <String, dynamic>{'sessionId': 's1'},
      ));

      final response = await future;
      expect(response.sessionId, 's1');

      await conn.close();
    });

    test('sendPrompt sends session/prompt request', () async {
      final transport = MockTransport();
      final conn = ClientSideConnection(
        transport,
        handler: _TestHandler(),
      );

      await _performInitialize(transport, conn);
      transport.sent.clear();

      final future = conn.sendPrompt(
        sessionId: 's1',
        prompt: [const TextContent(text: 'hello')],
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(transport.sent, hasLength(1));
      final req = transport.sent.first as JsonRpcRequest;
      expect(req.method, 'session/prompt');
      expect(req.params!['sessionId'], 's1');
      final prompt = req.params!['prompt'] as List<dynamic>;
      expect(prompt, hasLength(1));

      transport.receive(JsonRpcResponse(
        id: req.id,
        result: const <String, dynamic>{'stopReason': 'end_turn'},
      ));

      final response = await future;
      expect(response.stopReason, 'end_turn');

      await conn.close();
    });

    test('sendCancel sends session/cancel notification (not a request)',
        () async {
      final transport = MockTransport();
      final conn = ClientSideConnection(
        transport,
        handler: _TestHandler(),
      );

      await _performInitialize(transport, conn);
      transport.sent.clear();

      await conn.sendCancel(sessionId: 's1');

      expect(transport.sent, hasLength(1));
      final msg = transport.sent.first;
      expect(msg, isA<JsonRpcNotification>());
      final notif = msg as JsonRpcNotification;
      expect(notif.method, 'session/cancel');
      expect(notif.params!['sessionId'], 's1');

      await conn.close();
    });

    test('session/update notification dispatches to handler onSessionUpdate',
        () async {
      final transport = MockTransport();
      final handler = _TestHandler();
      final conn = ClientSideConnection(
        transport,
        handler: handler,
      );

      await _performInitialize(transport, conn);

      transport.receive(const JsonRpcNotification(
        method: 'session/update',
        params: {
          'sessionId': 's1',
          'update': {
            'sessionUpdate': 'agent_message_chunk',
            'content': {'type': 'text', 'text': 'hi'},
          },
        },
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.calls, contains('sessionUpdate:s1'));

      await conn.close();
    });

    test('sessionUpdates stream emits parsed SessionUpdateEvent', () async {
      final transport = MockTransport();
      final conn = ClientSideConnection(
        transport,
        handler: _TestHandler(),
      );

      await _performInitialize(transport, conn);

      final events = <SessionUpdateEvent>[];
      final sub = conn.sessionUpdates.listen(events.add);

      transport.receive(const JsonRpcNotification(
        method: 'session/update',
        params: {
          'sessionId': 's2',
          'update': {
            'sessionUpdate': 'agent_message_chunk',
            'content': {'type': 'text', 'text': 'hello'},
          },
        },
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events, hasLength(1));
      expect(events.first.sessionId, 's2');
      expect(events.first.update, isA<AgentMessageChunk>());

      await sub.cancel();
      await conn.close();
    });

    test('incoming fs/read_text_file dispatches to handler', () async {
      final transport = MockTransport();
      final handler = _FsHandler();
      final conn = ClientSideConnection(
        transport,
        handler: handler,
      );

      await _performInitialize(transport, conn);
      transport.sent.clear();

      transport.receive(JsonRpcRequest(
        id: 'read-1',
        method: 'fs/read_text_file',
        params: const ReadTextFileRequest(
          sessionId: 's1',
          path: '/tmp/test.txt',
        ).toJson(),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.calls, contains('readTextFile:/tmp/test.txt'));

      final response = transport.sent.first as JsonRpcResponse;
      expect(response.id, 'read-1');
      expect(response.isSuccess, isTrue);
      final result = response.result! as Map<String, dynamic>;
      expect(result['content'], 'file data');

      await conn.close();
    });

    test('unimplemented terminal/create returns METHOD_NOT_FOUND', () async {
      final transport = MockTransport();
      final conn = ClientSideConnection(
        transport,
        handler: _TestHandler(),
      );

      await _performInitialize(transport, conn);
      transport.sent.clear();

      transport.receive(JsonRpcRequest(
        id: 'term-1',
        method: 'terminal/create',
        params: const CreateTerminalRequest(
          sessionId: 's1',
          command: 'ls',
        ).toJson(),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final response = transport.sent.first as JsonRpcResponse;
      expect(response.id, 'term-1');
      expect(response.isError, isTrue);
      expect(response.error!.code, -32601);

      await conn.close();
    });

    test(
        'strict capability enforcement blocks sendLoadSession '
        'when loadSession is false', () async {
      final transport = MockTransport();
      final conn = ClientSideConnection(
        transport,
        handler: _TestHandler(),
        capabilityEnforcement: CapabilityEnforcement.strict,
      );

      await _performInitialize(transport, conn, loadSession: false);

      expect(
        () => conn.sendLoadSession(sessionId: 's1', cwd: '/tmp'),
        throwsA(isA<CapabilityException>()),
      );

      await conn.close();
    });
  });
}
