/// A minimal ACP agent that echoes prompts over stdio.
///
/// This is the "hello world" of the Agent Client Protocol. It's the smallest
/// thing that can legitimately call itself an agent: it accepts the ACP
/// handshake, creates a session on demand, and replies to prompts by echoing
/// them back.
///
/// ## Running it
///
/// Standalone (it will sit and wait for JSON-RPC messages on stdin):
///
/// ```
/// dart run example/basic_agent.dart
/// ```
///
/// Normally you don't run an agent by hand. You run it through a *client*
/// that spawns it as a subprocess — that's exactly what editors like Zed and
/// JetBrains IDEs do. See `subprocess_client.dart` in this folder for a
/// self-contained end-to-end demo that spawns this file and talks to it.
///
/// ## What the three methods must do
///
/// Every ACP agent has to implement three methods. Everything else is
/// optional. The comments on each override below explain what the peer (the
/// client) sends, and what the agent must return.
library;

import 'dart:async';

import 'package:acp/agent.dart';
import 'package:acp/schema.dart';
import 'package:acp/transport.dart';

/// The handler that implements the agent's behavior.
///
/// Extending `AgentHandler` gives you sensible defaults for every optional
/// method (they return `methodNotFound`). You only override what your agent
/// actually supports.
class EchoAgentHandler extends AgentHandler {
  /// We hold onto the connection so we can send *notifications* back to the
  /// client during a prompt turn — things like streaming message chunks.
  final AgentSideConnection _connection;

  EchoAgentHandler(this._connection);

  /// Handshake. The client sends its protocol version and capabilities; we
  /// reply with ours. After this returns, the connection is considered open
  /// and both sides know what the other supports.
  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return const InitializeResponse(
      protocolVersion: 1,
      agentInfo: ImplementationInfo(
        name: 'echo-agent',
        title: 'Echo Agent',
        version: '0.1.0',
      ),
    );
  }

  /// The client asks for a new session, passing the working directory it
  /// wants the agent to operate in. A real agent would create internal state
  /// keyed by `sessionId` here; we just return a hardcoded id.
  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return const NewSessionResponse(sessionId: 'session-1');
  }

  /// The client sends a prompt. While we work, we may push *session updates*
  /// back to the client as notifications (no reply expected) — these are
  /// what lets an editor render streaming output. When we're done, we return
  /// a `PromptResponse` with a `stopReason`.
  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    // A prompt is a list of typed content blocks — text, images, embedded
    // resources, etc. Pull out plain text for this minimal demo.
    final promptText = request.prompt
        .whereType<TextContent>()
        .map((c) => c.text)
        .join('\n');

    // Stream a single agent message chunk back. In a real agent this would
    // fire repeatedly as tokens arrive from an LLM.
    await _connection.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(content: TextContent(text: 'Echo: $promptText')),
    );

    // Signal that the turn is over. See [StopReason] for the full list.
    return const PromptResponse(stopReason: StopReason.endTurn);
  }
}

void main() {
  // StdioTransport reads JSON-RPC messages from stdin (one per line) and
  // writes responses to stdout. It auto-starts on first subscription, so
  // just handing it to AgentSideConnection is enough.
  final transport = StdioTransport();

  // `handlerFactory` is called once with this connection so the handler can
  // reach back into the connection to send notifications. Nothing else is
  // required to keep the agent alive — the event loop stays busy as long
  // as the transport is open.
  // ignore: unused_local_variable
  final connection = AgentSideConnection(
    transport,
    handlerFactory: EchoAgentHandler.new,
  );
}
