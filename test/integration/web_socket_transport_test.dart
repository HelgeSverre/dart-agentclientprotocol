@TestOn('vm')
@Tags(['integration'])
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';
import 'dart:io';

import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/agent_side_connection.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/capability_enforcement.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/client_side_connection.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:acp/src/transport/web_socket_transport.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Test agent handler (minimal)
// ---------------------------------------------------------------------------

class _TestAgentHandler extends AgentHandler {
  final AgentSideConnection conn;

  Future<PromptResponse> Function(PromptRequest, AgentSideConnection)? onPrompt;

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
    return const PromptResponse(stopReason: StopReason.endTurn);
  }

  @override
  Future<SetSessionModeResponse> setMode(
    SetSessionModeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const SetSessionModeResponse();

  @override
  Future<SetSessionConfigOptionResponse> setConfigOption(
    SetSessionConfigOptionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => SetSessionConfigOptionResponse(
    configOptions: [
      {'id': request.configId, 'value': request.value},
    ],
  );
}

// ---------------------------------------------------------------------------
// Test client handler (minimal)
// ---------------------------------------------------------------------------

class _TestClientHandler extends ClientHandler {
  final List<SessionUpdateEvent> receivedUpdates = [];

  String? lastWrittenPath;
  String? lastWrittenContent;

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    receivedUpdates.add(
      SessionUpdateEvent(sessionId: sessionId, update: update),
    );
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
}

// ---------------------------------------------------------------------------
// WebSocket fixture
// ---------------------------------------------------------------------------

typedef _WsPair =
    ({
      HttpServer server,
      AgentSideConnection agent,
      ClientSideConnection client,
      _TestAgentHandler agentHandler,
      _TestClientHandler clientHandler,
    });

Future<_WsPair> _setupWebSocketPair() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final agentConnCompleter = Completer<AgentSideConnection>();
  final agentHandlerCompleter = Completer<_TestAgentHandler>();

  server.listen((HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocketTransformer.upgrade(request).then((serverSocket) {
        final agentTransport = WebSocketTransport(serverSocket);
        late final _TestAgentHandler agentHandler;
        final agentConn = AgentSideConnection(
          agentTransport,
          handlerFactory: (conn) {
            agentHandler = _TestAgentHandler(conn);
            return agentHandler;
          },
          capabilityEnforcement: CapabilityEnforcement.permissive,
        );
        agentHandlerCompleter.complete(agentHandler);
        agentConnCompleter.complete(agentConn);
      });
    } else {
      request.response.statusCode = HttpStatus.notFound;
      unawaited(request.response.close());
    }
  });

  final clientTransport = await WebSocketTransport.connect(
    Uri.parse('ws://localhost:${server.port}'),
  );

  final clientHandler = _TestClientHandler();
  final clientConn = ClientSideConnection(
    clientTransport,
    handler: clientHandler,
    clientCapabilities: const ClientCapabilities(
      fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
      terminal: true,
    ),
  );

  final agentConn = await agentConnCompleter.future;
  final agentHandler = await agentHandlerCompleter.future;

  // Perform handshake.
  await clientConn.sendInitialize(protocolVersion: 1);
  await clientConn.sendNewSession(cwd: '/home');

  return (
    server: server,
    agent: agentConn,
    client: clientConn,
    agentHandler: agentHandler,
    clientHandler: clientHandler,
  );
}

Future<void> _tearDown(_WsPair pair) async {
  await pair.client.close();
  await pair.agent.close();
  await pair.server.close(force: true);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WebSocket transport integration', () {
    test('initialize and prompt over WebSocket', () async {
      final pair = await _setupWebSocketPair();
      addTearDown(() => _tearDown(pair));

      final response = await pair.client.sendPrompt(
        sessionId: 'sess-1',
        prompt: [const TextContent(text: 'Hello over WebSocket')],
      );

      expect(response.stopReason, StopReason.endTurn);
    });

    test('session updates stream over WebSocket', () async {
      final pair = await _setupWebSocketPair();
      addTearDown(() => _tearDown(pair));

      final streamUpdates = <SessionUpdateEvent>[];
      final sub = pair.client.sessionUpdates.listen(streamUpdates.add);
      addTearDown(sub.cancel);

      pair.agentHandler.onPrompt = (request, conn) async {
        await conn.notifySessionUpdate(
          request.sessionId,
          const AgentMessageChunk(content: TextContent(text: 'Hello')),
        );
        await conn.notifySessionUpdate(
          request.sessionId,
          const AgentThoughtChunk(content: TextContent(text: 'thinking...')),
        );
        return const PromptResponse(stopReason: StopReason.endTurn);
      };

      await pair.client.sendPrompt(
        sessionId: 'sess-1',
        prompt: [const TextContent(text: 'Go')],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(pair.clientHandler.receivedUpdates, hasLength(2));
      expect(
        pair.clientHandler.receivedUpdates[0].update,
        isA<AgentMessageChunk>(),
      );
      expect(
        pair.clientHandler.receivedUpdates[1].update,
        isA<AgentThoughtChunk>(),
      );

      expect(streamUpdates, hasLength(2));
      expect(streamUpdates[0].sessionId, 'sess-1');
      expect(streamUpdates[1].sessionId, 'sess-1');
    });

    test('bidirectional requests over WebSocket', () async {
      final pair = await _setupWebSocketPair();
      addTearDown(() => _tearDown(pair));

      pair.agentHandler.onPrompt = (request, conn) async {
        await conn.sendWriteTextFile(
          sessionId: request.sessionId,
          path: '/tmp/ws-test.txt',
          content: 'Written via WebSocket',
        );
        return const PromptResponse(stopReason: StopReason.endTurn);
      };

      final response = await pair.client.sendPrompt(
        sessionId: 'sess-1',
        prompt: [const TextContent(text: 'write a file')],
      );

      expect(response.stopReason, StopReason.endTurn);
      expect(pair.clientHandler.lastWrittenPath, '/tmp/ws-test.txt');
      expect(pair.clientHandler.lastWrittenContent, 'Written via WebSocket');
    });
  });
}
