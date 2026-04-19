import 'dart:async';

import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/agent_side_connection.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/capability_enforcement.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

import '../helpers/mock_transport.dart';

/// Minimal handler that implements the three required methods.
class _TestHandler extends AgentHandler {
  final List<String> calls = [];

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('initialize');
    return const InitializeResponse(
      protocolVersion: 1,
      agentCapabilities: AgentCapabilities(),
    );
  }

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('newSession');
    return const NewSessionResponse(sessionId: 'test-session');
  }

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('prompt');
    return const PromptResponse(stopReason: StopReason.endTurn);
  }

  @override
  Future<void> cancel(CancelNotification notification) async {
    calls.add('cancel:${notification.sessionId}');
  }
}

class _CancelablePromptHandler extends _TestHandler {
  final Completer<void> promptStarted = Completer<void>();
  final Completer<void> promptCanceled = Completer<void>();

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    promptStarted.complete();
    await cancelToken.whenCanceled;
    promptCanceled.complete();
    return const PromptResponse(stopReason: StopReason.cancelled);
  }
}

/// Sends an initialize request through the transport and waits for response.
Future<void> _initializeConnection(MockTransport transport) async {
  transport.receive(
    JsonRpcRequest(
      id: 'init-1',
      method: 'initialize',
      params:
          InitializeRequest(
            protocolVersion: 1,
            clientCapabilities: const ClientCapabilities(
              fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
              terminal: true,
            ),
          ).toJson(),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  group('AgentSideConnection', () {
    test('starts in opening state after construction', () {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );
      expect(conn.state, ConnectionState.opening);

      // Clean up
      addTearDown(() => conn.close());
    });

    test(
      'initialize request dispatches to handler and transitions to open',
      () async {
        final transport = MockTransport();
        final handler = _TestHandler();
        final conn = AgentSideConnection(
          transport,
          handlerFactory: (_) => handler,
        );

        await _initializeConnection(transport);

        expect(conn.state, ConnectionState.open);
        expect(handler.calls, contains('initialize'));

        // Check response was sent
        final response = transport.sent.first as JsonRpcResponse;
        expect(response.id, 'init-1');
        expect(response.isSuccess, isTrue);
        final result = response.result! as Map<String, dynamic>;
        expect(result['protocolVersion'], 1);

        await conn.close();
      },
    );

    test('stores remoteCapabilities after initialize', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );

      expect(conn.remoteCapabilities, isNull);

      await _initializeConnection(transport);

      expect(conn.remoteCapabilities, isNotNull);
      expect(conn.remoteCapabilities!.fs.readTextFile, isTrue);
      expect(conn.remoteCapabilities!.terminal, isTrue);

      await conn.close();
    });

    test('session/new dispatches to handler after initialize', () async {
      final transport = MockTransport();
      final handler = _TestHandler();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => handler,
      );

      await _initializeConnection(transport);
      transport.sent.clear();

      transport.receive(
        JsonRpcRequest(
          id: 'new-1',
          method: 'session/new',
          params: const NewSessionRequest(cwd: '/tmp').toJson(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.calls, contains('newSession'));
      final response = transport.sent.first as JsonRpcResponse;
      expect(response.id, 'new-1');
      expect(response.isSuccess, isTrue);
      final result = response.result! as Map<String, dynamic>;
      expect(result['sessionId'], 'test-session');

      await conn.close();
    });

    test('session/cancel notification dispatches to handler', () async {
      final transport = MockTransport();
      final handler = _TestHandler();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => handler,
      );

      await _initializeConnection(transport);

      transport.receive(
        const JsonRpcNotification(
          method: 'session/cancel',
          params: {'sessionId': 's1'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.calls, contains('cancel:s1'));

      await conn.close();
    });

    test(
      'session/cancel cancels active prompt token for that session',
      () async {
        final transport = MockTransport();
        final handler = _CancelablePromptHandler();
        final conn = AgentSideConnection(
          transport,
          handlerFactory: (_) => handler,
        );

        await _initializeConnection(transport);
        transport.sent.clear();

        transport.receive(
          JsonRpcRequest(
            id: 'prompt-1',
            method: 'session/prompt',
            params:
                const PromptRequest(
                  sessionId: 's1',
                  prompt: [TextContent(text: 'work')],
                ).toJson(),
          ),
        );

        await handler.promptStarted.future;
        transport.receive(
          const JsonRpcNotification(
            method: 'session/cancel',
            params: {'sessionId': 's1'},
          ),
        );

        await handler.promptCanceled.future;
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final response = transport.sent.first as JsonRpcResponse;
        expect(response.id, 'prompt-1');
        expect(response.isSuccess, isTrue);
        final result = response.result! as Map<String, dynamic>;
        expect(result['stopReason'], StopReason.cancelled.value);

        await conn.close();
      },
    );

    test(
      'optional methods return METHOD_NOT_FOUND with default handler',
      () async {
        final transport = MockTransport();
        final conn = AgentSideConnection(
          transport,
          handlerFactory: (_) => _TestHandler(),
        );

        await _initializeConnection(transport);
        transport.sent.clear();

        transport.receive(
          JsonRpcRequest(
            id: 'mode-1',
            method: 'session/set_mode',
            params:
                const SetSessionModeRequest(
                  sessionId: 's1',
                  modeId: 'fast',
                ).toJson(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final response = transport.sent.first as JsonRpcResponse;
        expect(response.isError, isTrue);
        expect(response.error!.code, -32601);

        await conn.close();
      },
    );

    test('notifySessionUpdate sends session/update notification', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );

      await _initializeConnection(transport);
      transport.sent.clear();

      await conn.notifySessionUpdate(
        's1',
        const AgentMessageChunk(content: TextContent(text: 'hello')),
      );

      expect(transport.sent, hasLength(1));
      final notif = transport.sent.first as JsonRpcNotification;
      expect(notif.method, 'session/update');
      expect(notif.params!['sessionId'], 's1');
      final update = notif.params!['update'] as Map<String, dynamic>;
      expect(update['sessionUpdate'], 'agent_message_chunk');

      await conn.close();
    });

    test('sendReadTextFile sends request and returns typed response', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );

      await _initializeConnection(transport);
      transport.sent.clear();

      final future = conn.sendReadTextFile(
        sessionId: 's1',
        path: '/tmp/test.txt',
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(transport.sent, hasLength(1));
      final req = transport.sent.first as JsonRpcRequest;
      expect(req.method, 'fs/read_text_file');
      expect(req.params!['sessionId'], 's1');
      expect(req.params!['path'], '/tmp/test.txt');

      // Simulate client response
      transport.receive(
        JsonRpcResponse(id: req.id, result: const {'content': 'file contents'}),
      );

      final response = await future;
      expect(response.content, 'file contents');

      await conn.close();
    });

    test('sendReadTextFile rejects relative path before sending', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );

      await _initializeConnection(transport);
      transport.sent.clear();

      expect(
        () => conn.sendReadTextFile(sessionId: 's1', path: 'relative.txt'),
        throwsA(isA<ProtocolValidationException>()),
      );
      expect(transport.sent, isEmpty);

      await conn.close();
    });

    test('sendWriteTextFile rejects relative path before sending', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );

      await _initializeConnection(transport);
      transport.sent.clear();

      expect(
        () => conn.sendWriteTextFile(
          sessionId: 's1',
          path: 'relative.txt',
          content: 'data',
        ),
        throwsA(isA<ProtocolValidationException>()),
      );
      expect(transport.sent, isEmpty);

      await conn.close();
    });

    test('sendCreateTerminal rejects relative cwd before sending', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );

      await _initializeConnection(transport);
      transport.sent.clear();

      expect(
        () => conn.sendCreateTerminal(
          sessionId: 's1',
          command: 'dart',
          cwd: 'relative/path',
        ),
        throwsA(isA<ProtocolValidationException>()),
      );
      expect(transport.sent, isEmpty);

      await conn.close();
    });

    test('strict capability enforcement blocks sendReadTextFile '
        'when fs.readTextFile is false', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );

      // Initialize with NO fs.readTextFile capability
      transport.receive(
        JsonRpcRequest(
          id: 'init-1',
          method: 'initialize',
          params:
              InitializeRequest(
                protocolVersion: 1,
                clientCapabilities: const ClientCapabilities(
                  fs: FileSystemCapability(),
                  terminal: false,
                ),
              ).toJson(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        () => conn.sendReadTextFile(sessionId: 's1', path: '/tmp/test.txt'),
        throwsA(isA<CapabilityException>()),
      );

      await conn.close();
    });

    test('permissive mode allows sendReadTextFile '
        'when fs.readTextFile is false', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
        capabilityEnforcement: CapabilityEnforcement.permissive,
      );

      // Initialize with NO fs.readTextFile capability
      transport.receive(
        JsonRpcRequest(
          id: 'init-1',
          method: 'initialize',
          params:
              InitializeRequest(
                protocolVersion: 1,
                clientCapabilities: const ClientCapabilities(
                  fs: FileSystemCapability(),
                  terminal: false,
                ),
              ).toJson(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      transport.sent.clear();

      final future = conn.sendReadTextFile(
        sessionId: 's1',
        path: '/tmp/test.txt',
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(transport.sent, hasLength(1));
      final req = transport.sent.first as JsonRpcRequest;

      // Simulate response
      transport.receive(
        JsonRpcResponse(id: req.id, result: const {'content': 'data'}),
      );

      final response = await future;
      expect(response.content, 'data');

      await conn.close();
    });

    test('extMethod sends extension request', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );

      await _initializeConnection(transport);
      transport.sent.clear();

      final future = conn.extMethod('_vendor/custom', {'key': 'value'});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(transport.sent, hasLength(1));
      final req = transport.sent.first as JsonRpcRequest;
      expect(req.method, '_vendor/custom');
      expect(req.params!['key'], 'value');

      transport.receive(
        JsonRpcResponse(id: req.id, result: const {'ok': true}),
      );

      final result = await future;
      expect(result['ok'], true);

      await conn.close();
    });

    test('extNotification sends extension notification', () async {
      final transport = MockTransport();
      final conn = AgentSideConnection(
        transport,
        handlerFactory: (_) => _TestHandler(),
      );

      await _initializeConnection(transport);
      transport.sent.clear();

      await conn.extNotification('_vendor/event', {'data': 42});

      expect(transport.sent, hasLength(1));
      final notif = transport.sent.first as JsonRpcNotification;
      expect(notif.method, '_vendor/event');
      expect(notif.params!['data'], 42);

      await conn.close();
    });
  });
}
