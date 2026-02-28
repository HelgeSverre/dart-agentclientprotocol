import 'dart:async';

import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/agent_side_connection.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/capability_enforcement.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/client_side_connection.dart';
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
// Test handlers
// ---------------------------------------------------------------------------

class _StreamingAgentHandler extends AgentHandler {
  final AgentSideConnection _conn;
  final List<String> calls = [];

  _StreamingAgentHandler(this._conn);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('initialize');
    return const InitializeResponse(protocolVersion: 1);
  }

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('newSession');
    return const NewSessionResponse(sessionId: 'sess-1');
  }

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('prompt');
    await _conn.notifySessionUpdate(
      request.sessionId,
      const AgentMessageChunk(
        content: {'type': 'text', 'text': 'response text'},
      ),
    );
    return const PromptResponse(stopReason: 'end_turn');
  }

  @override
  Future<void> cancel(CancelNotification notification) async {
    calls.add('cancel:${notification.sessionId}');
  }
}

class _FileReadingAgentHandler extends AgentHandler {
  final AgentSideConnection _conn;

  _FileReadingAgentHandler(this._conn);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const NewSessionResponse(sessionId: 'sess-1');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final fileResponse = await _conn.sendReadTextFile(
      sessionId: request.sessionId,
      path: '/etc/hello.txt',
    );
    await _conn.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(
        content: {'type': 'text', 'text': fileResponse.content},
      ),
    );
    return const PromptResponse(stopReason: 'end_turn');
  }
}

class _BasicClientHandler extends ClientHandler {
  final List<SessionUpdateEvent> receivedUpdates = [];

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    receivedUpdates.add(
      SessionUpdateEvent(sessionId: sessionId, update: update),
    );
  }
}

class _FileServingClientHandler extends ClientHandler {
  final List<SessionUpdateEvent> receivedUpdates = [];

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    receivedUpdates.add(
      SessionUpdateEvent(sessionId: sessionId, update: update),
    );
  }

  @override
  Future<ReadTextFileResponse> readTextFile(
    ReadTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return ReadTextFileResponse(content: 'Hello from ${request.path}');
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Client ↔ Agent integration', () {
    test('full flow: initialize → session/new → prompt with streaming → cancel',
        () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      late final _StreamingAgentHandler agentHandler;
      final agentConn = AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) {
          agentHandler = _StreamingAgentHandler(conn);
          return agentHandler;
        },
      );

      final clientHandler = _BasicClientHandler();
      final clientConn = ClientSideConnection(
        clientTransport,
        handler: clientHandler,
      );

      // Listen for session updates on the stream.
      final streamUpdates = <SessionUpdateEvent>[];
      final updateSub = clientConn.sessionUpdates.listen(streamUpdates.add);

      // 1. Initialize
      final initResponse = await clientConn.sendInitialize(protocolVersion: 1);
      expect(initResponse.protocolVersion, 1);

      // 2. New session
      final sessionResponse = await clientConn.sendNewSession(cwd: '/home');
      expect(sessionResponse.sessionId, 'sess-1');

      // 3. Prompt (agent streams an update before responding)
      final promptResponse = await clientConn.sendPrompt(
        sessionId: 'sess-1',
        prompt: [const TextContent(text: 'Hello agent')],
      );
      expect(promptResponse.stopReason, 'end_turn');

      // Give notifications time to arrive.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify session updates arrived via both handler and stream.
      expect(clientHandler.receivedUpdates, hasLength(1));
      expect(clientHandler.receivedUpdates.first.sessionId, 'sess-1');
      expect(clientHandler.receivedUpdates.first.update,
          isA<AgentMessageChunk>());

      expect(streamUpdates, hasLength(1));
      expect(streamUpdates.first.sessionId, 'sess-1');

      // 4. Cancel
      await clientConn.sendCancel(sessionId: 'sess-1');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(agentHandler.calls, contains('cancel:sess-1'));

      // 5. Verify handler call sequence.
      expect(agentHandler.calls,
          ['initialize', 'newSession', 'prompt', 'cancel:sess-1']);

      // Cleanup
      await updateSub.cancel();
      await clientConn.close();
      await agentConn.close();
    });

    test('agent reads file from client via fs/read_text_file', () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      final agentConn = AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _FileReadingAgentHandler(conn),
        capabilityEnforcement: CapabilityEnforcement.permissive,
      );

      final clientHandler = _FileServingClientHandler();
      final clientConn = ClientSideConnection(
        clientTransport,
        handler: clientHandler,
        clientCapabilities: const ClientCapabilities(
          fs: FileSystemCapability(readTextFile: true),
        ),
      );

      // Initialize + create session
      await clientConn.sendInitialize(protocolVersion: 1);
      await clientConn.sendNewSession(cwd: '/home');

      // Prompt → agent reads file from client → streams content back
      final streamUpdates = <SessionUpdateEvent>[];
      final updateSub = clientConn.sessionUpdates.listen(streamUpdates.add);

      final promptResponse = await clientConn.sendPrompt(
        sessionId: 'sess-1',
        prompt: [const TextContent(text: 'Read a file')],
      );
      expect(promptResponse.stopReason, 'end_turn');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify the agent read the file and streamed the content back.
      expect(streamUpdates, hasLength(1));
      final chunk = streamUpdates.first.update as AgentMessageChunk;
      expect(chunk.content['text'], 'Hello from /etc/hello.txt');

      await updateSub.cancel();
      await clientConn.close();
      await agentConn.close();
    });

    test('capability negotiation — client advertises fs capabilities',
        () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      final agentConn = AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _FileReadingAgentHandler(conn),
        capabilityEnforcement: CapabilityEnforcement.strict,
      );

      final clientConn = ClientSideConnection(
        clientTransport,
        handler: _BasicClientHandler(),
        clientCapabilities: const ClientCapabilities(
          fs: FileSystemCapability(
            readTextFile: true,
            writeTextFile: false,
          ),
        ),
      );

      await clientConn.sendInitialize(protocolVersion: 1);
      await clientConn.sendNewSession(cwd: '/home');

      // Agent sees client capabilities after initialize.
      expect(agentConn.remoteCapabilities, isNotNull);
      expect(agentConn.remoteCapabilities!.fs.readTextFile, isTrue);
      expect(agentConn.remoteCapabilities!.fs.writeTextFile, isFalse);

      // Agent cannot call sendWriteTextFile in strict mode.
      expect(
        () => agentConn.sendWriteTextFile(
          sessionId: 'sess-1',
          path: '/tmp/out.txt',
          content: 'data',
        ),
        throwsA(isA<CapabilityException>()),
      );

      await clientConn.close();
      await agentConn.close();
    });
  });
}
