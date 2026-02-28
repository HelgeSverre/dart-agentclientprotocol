/// A minimal ACP agent that echoes prompts.
///
/// Run with: `dart run example/basic_agent.dart`
///
/// This agent:
/// 1. Accepts an `initialize` handshake.
/// 2. Creates a session on `session/new`.
/// 3. On `session/prompt`, echoes the prompt text back as an
///    `AgentMessageChunk` session update, then ends the turn.
library;

import 'dart:async';

import 'package:acp/agent.dart';
import 'package:acp/schema.dart';
import 'package:acp/transport.dart';

class EchoAgentHandler extends AgentHandler {
  final AgentSideConnection _conn;

  EchoAgentHandler(this._conn);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return const InitializeResponse(protocolVersion: 1);
  }

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return const NewSessionResponse(sessionId: 'session-1');
  }

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    // Extract text from the first content block, if any.
    final promptText = request.prompt
        .whereType<TextContent>()
        .map((c) => c.text)
        .join('\n');

    // Stream an agent message chunk back to the client.
    await _conn.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(
        content: {'type': 'text', 'text': 'Echo: $promptText'},
      ),
    );

    return const PromptResponse(stopReason: 'end_turn');
  }
}

void main() {
  final transport = StdioTransport();
  transport.start();

  // The connection starts listening immediately.
  // ignore: unused_local_variable
  final connection = AgentSideConnection(
    transport,
    handlerFactory: (conn) => EchoAgentHandler(conn),
  );
}
