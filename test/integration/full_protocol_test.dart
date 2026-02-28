@Tags(['integration'])
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';

import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/agent_side_connection.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/capability_enforcement.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/client_side_connection.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

import '../helpers/linked_transport.dart';

// ---------------------------------------------------------------------------
// Test agent handler
// ---------------------------------------------------------------------------

class _TestAgentHandler extends AgentHandler {
  final AgentSideConnection conn;

  Future<PromptResponse> Function(PromptRequest, AgentSideConnection)? onPrompt;
  Future<SetSessionModeResponse> Function(SetSessionModeRequest)? onSetMode;
  Future<SetSessionConfigOptionResponse> Function(
    SetSessionConfigOptionRequest,
  )?
  onSetConfigOption;

  _TestAgentHandler(this.conn);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const NewSessionResponse(sessionId: 'sess-1');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    if (onPrompt != null) return onPrompt!(request, conn);
    return const PromptResponse(stopReason: 'end_turn');
  }

  @override
  Future<SetSessionModeResponse> setMode(
    SetSessionModeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    if (onSetMode != null) return onSetMode!(request);
    return const SetSessionModeResponse();
  }

  @override
  Future<SetSessionConfigOptionResponse> setConfigOption(
    SetSessionConfigOptionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    if (onSetConfigOption != null) return onSetConfigOption!(request);
    return SetSessionConfigOptionResponse(
      configOptions: [
        {'id': request.configId, 'value': request.value},
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Test client handler
// ---------------------------------------------------------------------------

class _TestClientHandler extends ClientHandler {
  final List<SessionUpdateEvent> receivedUpdates = [];
  final List<({String method, Map<String, dynamic>? params})>
  receivedExtNotifications = [];

  Future<Map<String, dynamic>?> Function(
    String method,
    Map<String, dynamic>? params,
  )?
  extMethodHandler;

  String? lastWrittenPath;
  String? lastWrittenContent;

  final Map<String, String> terminalOutputs = {};
  final Set<String> releasedTerminals = {};
  int _terminalCounter = 0;

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    receivedUpdates.add(
      SessionUpdateEvent(sessionId: sessionId, update: update),
    );
  }

  @override
  Future<Map<String, dynamic>?> onExtMethod(
    String method,
    Map<String, dynamic>? params, {
    required AcpCancellationToken cancelToken,
  }) async {
    if (extMethodHandler != null) return extMethodHandler!(method, params);
    return null;
  }

  @override
  Future<void> onExtNotification(
    String method,
    Map<String, dynamic>? params,
  ) async {
    receivedExtNotifications.add((method: method, params: params));
  }

  @override
  Future<WriteTextFileResponse> writeTextFile(
    WriteTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    lastWrittenPath = request.path;
    lastWrittenContent = request.content;
    return const WriteTextFileResponse();
  }

  @override
  Future<CreateTerminalResponse> createTerminal(
    CreateTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final id = 'term-${++_terminalCounter}';
    terminalOutputs[id] = 'output of ${request.command}';
    return CreateTerminalResponse(terminalId: id);
  }

  @override
  Future<TerminalOutputResponse> terminalOutput(
    TerminalOutputRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return TerminalOutputResponse(
      output: terminalOutputs[request.terminalId] ?? '',
      truncated: false,
    );
  }

  @override
  Future<void> releaseTerminal(
    ReleaseTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    releasedTerminals.add(request.terminalId);
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

typedef _Pair =
    ({
      AgentSideConnection agent,
      ClientSideConnection client,
      _TestAgentHandler agentHandler,
      _TestClientHandler clientHandler,
    });

Future<_Pair> _setupPair({
  ClientCapabilities clientCapabilities = const ClientCapabilities(
    fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
    terminal: true,
  ),
  CapabilityEnforcement agentCapabilityEnforcement =
      CapabilityEnforcement.permissive,
}) async {
  final (agentTransport, clientTransport) = createLinkedTransports();

  late final _TestAgentHandler agentHandler;
  final agentConn = AgentSideConnection(
    agentTransport,
    handlerFactory: (conn) {
      agentHandler = _TestAgentHandler(conn);
      return agentHandler;
    },
    capabilityEnforcement: agentCapabilityEnforcement,
  );

  final clientHandler = _TestClientHandler();
  final clientConn = ClientSideConnection(
    clientTransport,
    handler: clientHandler,
    clientCapabilities: clientCapabilities,
  );

  await clientConn.sendInitialize(protocolVersion: 1);
  await clientConn.sendNewSession(cwd: '/home');

  return (
    agent: agentConn,
    client: clientConn,
    agentHandler: agentHandler,
    clientHandler: clientHandler,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Full protocol integration', () {
    test('extension method round-trip', () async {
      final pair = await _setupPair();
      addTearDown(() async {
        await pair.client.close();
        await pair.agent.close();
      });

      pair.clientHandler.extMethodHandler = (method, params) async {
        if (method == '_vendor/ping') {
          return {'pong': true, 'echo': params?['message']};
        }
        return null;
      };

      final result = await pair.agent.extMethod('_vendor/ping', {
        'message': 'hello',
      });

      expect(result['pong'], isTrue);
      expect(result['echo'], 'hello');
    });

    test('extension notification round-trip', () async {
      final pair = await _setupPair();
      addTearDown(() async {
        await pair.client.close();
        await pair.agent.close();
      });

      await pair.agent.extNotification('_vendor/log', {
        'level': 'info',
        'text': 'something happened',
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(pair.clientHandler.receivedExtNotifications, hasLength(1));
      final notif = pair.clientHandler.receivedExtNotifications.first;
      expect(notif.method, '_vendor/log');
      expect(notif.params?['level'], 'info');
      expect(notif.params?['text'], 'something happened');
    });

    test('multiple session updates in sequence', () async {
      final pair = await _setupPair();
      addTearDown(() async {
        await pair.client.close();
        await pair.agent.close();
      });

      final streamUpdates = <SessionUpdateEvent>[];
      final sub = pair.client.sessionUpdates.listen(streamUpdates.add);
      addTearDown(sub.cancel);

      pair.agentHandler.onPrompt = (request, conn) async {
        await conn.notifySessionUpdate(
          request.sessionId,
          const AgentMessageChunk(content: {'type': 'text', 'text': 'Hello'}),
        );
        await conn.notifySessionUpdate(
          request.sessionId,
          const AgentThoughtChunk(
            content: {'type': 'text', 'text': 'thinking...'},
          ),
        );
        await conn.notifySessionUpdate(
          request.sessionId,
          const ToolCallSessionUpdate(
            title: 'read_file',
            toolCallId: 'tc-1',
            status: 'running',
          ),
        );
        return const PromptResponse(stopReason: 'end_turn');
      };

      await pair.client.sendPrompt(
        sessionId: 'sess-1',
        prompt: [const TextContent(text: 'Go')],
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(pair.clientHandler.receivedUpdates, hasLength(3));
      expect(
        pair.clientHandler.receivedUpdates[0].update,
        isA<AgentMessageChunk>(),
      );
      expect(
        pair.clientHandler.receivedUpdates[1].update,
        isA<AgentThoughtChunk>(),
      );
      expect(
        pair.clientHandler.receivedUpdates[2].update,
        isA<ToolCallSessionUpdate>(),
      );

      expect(streamUpdates, hasLength(3));
      expect(streamUpdates[0].sessionId, 'sess-1');
      expect(streamUpdates[1].sessionId, 'sess-1');
      expect(streamUpdates[2].sessionId, 'sess-1');
    });

    test('set mode round-trip', () async {
      final pair = await _setupPair();
      addTearDown(() async {
        await pair.client.close();
        await pair.agent.close();
      });

      SetSessionModeRequest? receivedRequest;
      pair.agentHandler.onSetMode = (request) async {
        receivedRequest = request;
        return const SetSessionModeResponse();
      };

      final response = await pair.client.sendSetMode(
        sessionId: 'sess-1',
        modeId: 'fast',
      );

      expect(response, isA<SetSessionModeResponse>());
      expect(receivedRequest, isNotNull);
      expect(receivedRequest!.sessionId, 'sess-1');
      expect(receivedRequest!.modeId, 'fast');
    });

    test('set config option round-trip', () async {
      final pair = await _setupPair();
      addTearDown(() async {
        await pair.client.close();
        await pair.agent.close();
      });

      final response = await pair.client.sendSetConfigOption(
        sessionId: 'sess-1',
        configId: 'temperature',
        value: '0.5',
      );

      expect(response.configOptions, hasLength(1));
      expect(response.configOptions.first['id'], 'temperature');
      expect(response.configOptions.first['value'], '0.5');
    });

    test('agent handler error propagates as RPC error', () async {
      final pair = await _setupPair();
      addTearDown(() async {
        await pair.client.close();
        await pair.agent.close();
      });

      pair.agentHandler.onPrompt = (request, conn) async {
        throw RpcErrorException.invalidParams('bad input');
      };

      try {
        await pair.client.sendPrompt(
          sessionId: 'sess-1',
          prompt: [const TextContent(text: 'fail')],
        );
        fail('Expected RpcErrorException');
      } on RpcErrorException catch (e) {
        expect(e.code, -32602);
        expect(e.message, 'bad input');
      }
    });

    test('connection state transitions visible to both sides', () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      late final _TestAgentHandler agentHandler;
      final agentConn = AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) {
          agentHandler = _TestAgentHandler(conn);
          return agentHandler;
        },
        capabilityEnforcement: CapabilityEnforcement.permissive,
      );

      final clientHandler = _TestClientHandler();
      final clientConn = ClientSideConnection(
        clientTransport,
        handler: clientHandler,
      );

      addTearDown(() async {
        await clientConn.close();
        await agentConn.close();
      });

      // Before initialize both are in opening state (start was called
      // in constructor).
      expect(agentConn.state, ConnectionState.opening);
      expect(clientConn.state, ConnectionState.opening);

      await clientConn.sendInitialize(protocolVersion: 1);

      // After initialize, both should be open.
      expect(agentConn.state, ConnectionState.open);
      expect(clientConn.state, ConnectionState.open);

      // Now subscribe to catch the close transition.
      final clientClosedStates = <ConnectionState>[];
      final clientSub = clientConn.onStateChange.listen(clientClosedStates.add);

      await clientConn.close();
      await clientSub.cancel();

      expect(clientConn.state, ConnectionState.closed);
    });

    test('tracing hooks fire on both sides', () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      final agentSent = <Map<String, dynamic>>[];
      final agentReceived = <Map<String, dynamic>>[];
      final clientSent = <Map<String, dynamic>>[];
      final clientReceived = <Map<String, dynamic>>[];

      final agentConn = AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _TestAgentHandler(conn),
        capabilityEnforcement: CapabilityEnforcement.permissive,
      );
      agentConn.onSend = agentSent.add;
      agentConn.onReceive = agentReceived.add;

      final clientConn = ClientSideConnection(
        clientTransport,
        handler: _TestClientHandler(),
      );
      clientConn.onSend = clientSent.add;
      clientConn.onReceive = clientReceived.add;

      addTearDown(() async {
        await clientConn.close();
        await agentConn.close();
      });

      await clientConn.sendInitialize(protocolVersion: 1);

      // Client should have sent the initialize request.
      expect(clientSent, isNotEmpty);
      expect(clientSent.any((m) => m['method'] == 'initialize'), isTrue);

      // Agent should have received the initialize request.
      expect(agentReceived, isNotEmpty);
      expect(agentReceived.any((m) => m['method'] == 'initialize'), isTrue);

      // Agent should have sent the response.
      expect(agentSent, isNotEmpty);
      expect(agentSent.any((m) => m.containsKey('result')), isTrue);

      // Client should have received the response.
      expect(clientReceived, isNotEmpty);
      expect(clientReceived.any((m) => m.containsKey('result')), isTrue);
    });

    test('terminal create → output → release flow', () async {
      final pair = await _setupPair();
      addTearDown(() async {
        await pair.client.close();
        await pair.agent.close();
      });

      late String capturedTerminalId;
      pair.agentHandler.onPrompt = (request, conn) async {
        final createResp = await conn.sendCreateTerminal(
          sessionId: request.sessionId,
          command: 'echo',
          args: ['hello'],
        );
        capturedTerminalId = createResp.terminalId;

        final outputResp = await conn.sendTerminalOutput(
          sessionId: request.sessionId,
          terminalId: createResp.terminalId,
        );
        expect(outputResp.output, 'output of echo');
        expect(outputResp.truncated, isFalse);

        await conn.sendReleaseTerminal(
          sessionId: request.sessionId,
          terminalId: createResp.terminalId,
        );

        return const PromptResponse(stopReason: 'end_turn');
      };

      final response = await pair.client.sendPrompt(
        sessionId: 'sess-1',
        prompt: [const TextContent(text: 'run command')],
      );

      expect(response.stopReason, 'end_turn');
      expect(capturedTerminalId, 'term-1');
      expect(pair.clientHandler.releasedTerminals, contains('term-1'));
    });

    test('write text file round-trip', () async {
      final pair = await _setupPair();
      addTearDown(() async {
        await pair.client.close();
        await pair.agent.close();
      });

      pair.agentHandler.onPrompt = (request, conn) async {
        await conn.sendWriteTextFile(
          sessionId: request.sessionId,
          path: '/tmp/test.txt',
          content: 'Hello, world!',
        );
        return const PromptResponse(stopReason: 'end_turn');
      };

      await pair.client.sendPrompt(
        sessionId: 'sess-1',
        prompt: [const TextContent(text: 'write a file')],
      );

      expect(pair.clientHandler.lastWrittenPath, '/tmp/test.txt');
      expect(pair.clientHandler.lastWrittenContent, 'Hello, world!');
    });
  });
}
