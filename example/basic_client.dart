/// A minimal ACP client demonstrating the client-side API.
///
/// This example uses in-memory linked transports to simulate a
/// client ↔ agent connection without spawning a subprocess.
///
/// In production, you would use [StdioProcessTransport.start] to
/// spawn an agent process:
///
/// ```dart
/// final transport = await StdioProcessTransport.start(
///   'dart', ['run', 'example/basic_agent.dart'],
/// );
/// ```
library;

import 'dart:async';

import 'package:acp/agent.dart';
import 'package:acp/client.dart';
import 'package:acp/schema.dart';
import 'package:acp/transport.dart';

// -- A simple echo agent for the demo --

class _EchoAgentHandler extends AgentHandler {
  final AgentSideConnection _conn;
  _EchoAgentHandler(this._conn);

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
      const NewSessionResponse(sessionId: 'session-1');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final text = request.prompt
        .whereType<TextContent>()
        .map((c) => c.text)
        .join('\n');

    await _conn.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(
        content: {'type': 'text', 'text': 'Echo: $text'},
      ),
    );
    return const PromptResponse(stopReason: 'end_turn');
  }
}

// -- A simple client handler --

class _PrintingClientHandler extends ClientHandler {
  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    switch (update) {
      case AgentMessageChunk(:final content):
        // ignore: avoid_print
        print('[session/$sessionId] Agent: ${content['text']}');
      default:
        // ignore: avoid_print
        print('[session/$sessionId] Update: ${update.runtimeType}');
    }
  }
}

Future<void> main() async {
  // Reference the types to show they compile against the real API.
  // In production, you'd pass these to actual connections.
  // ignore: avoid_print
  print('Handler type: $_PrintingClientHandler');
  // ignore: avoid_print
  print('Agent handler factory: $_EchoAgentHandler\n');

  // ignore: avoid_print
  print('=== ACP Client Example ===\n');
  // ignore: avoid_print
  print('In production, create a client like this:\n');
  // ignore: avoid_print
  print('''
  // Spawn the agent process
  final transport = await StdioProcessTransport.start(
    'dart', ['run', 'example/basic_agent.dart'],
  );

  // Create the client connection
  final client = ClientSideConnection(
    transport,
    handler: MyClientHandler(),
    clientCapabilities: ClientCapabilities(
      fs: FileSystemCapability(readTextFile: true),
      terminal: true,
    ),
  );

  // Initialize
  await client.sendInitialize(protocolVersion: 1);

  // Create a session
  final session = await client.sendNewSession(cwd: '/home/user');

  // Send a prompt
  final response = await client.sendPrompt(
    sessionId: session.sessionId,
    prompt: [TextContent(text: 'Hello, agent!')],
  );
  print('Stop reason: \${response.stopReason}');

  // Listen for streaming updates
  client.sessionUpdates.listen((event) {
    print('Update for \${event.sessionId}: \${event.update}');
  });

  // Clean up
  await client.close();
''');
}
