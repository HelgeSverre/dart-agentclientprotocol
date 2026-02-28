/// A working ACP client + agent example using in-memory transports.
///
/// Run with: `dart run example/basic_client.dart`
///
/// Shows the complete flow: initialize → new session → prompt → updates → close.
library;

import 'dart:async';

import 'package:acp/agent.dart';
import 'package:acp/client.dart';
import 'package:acp/schema.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/transport.dart';

// -- In-memory linked transports --

(AcpTransport, AcpTransport) _createLinkedTransports() {
  // ignore: close_sinks
  final aToB = StreamController<JsonRpcMessage>();
  // ignore: close_sinks
  final bToA = StreamController<JsonRpcMessage>();
  final transportA = _LinkedTransport(inbound: bToA.stream, outboundSink: aToB);
  final transportB = _LinkedTransport(inbound: aToB.stream, outboundSink: bToA);
  return (transportA, transportB);
}

class _LinkedTransport implements AcpTransport {
  final Stream<JsonRpcMessage> _inbound;
  final StreamController<JsonRpcMessage> _outboundSink;
  bool _closed = false;

  _LinkedTransport({
    required Stream<JsonRpcMessage> inbound,
    required StreamController<JsonRpcMessage> outboundSink,
  }) : _inbound = inbound,
       _outboundSink = outboundSink;

  @override
  Stream<JsonRpcMessage> get messages => _inbound;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) throw StateError('Transport is closed');
    _outboundSink.add(message);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _outboundSink.close();
  }
}

// -- A simple echo agent for the demo --

class _EchoAgentHandler extends AgentHandler {
  final AgentSideConnection _conn;
  _EchoAgentHandler(this._conn);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const NewSessionResponse(sessionId: 'session-1');

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
      AgentMessageChunk(content: {'type': 'text', 'text': 'Echo: $text'}),
    );
    return const PromptResponse(stopReason: 'end_turn');
  }
}

// -- A simple client handler that prints session updates --

class _PrintingClientHandler extends ClientHandler {
  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    switch (update) {
      case AgentMessageChunk(:final content):
        // ignore: avoid_print
        print('   [session/$sessionId] Agent says: ${content['text']}');
      default:
        // ignore: avoid_print
        print('   [session/$sessionId] Update: ${update.runtimeType}');
    }
  }
}

// -- Main --

Future<void> main() async {
  // ignore: avoid_print
  print('=== ACP Client Example ===\n');

  // Create linked in-memory transports
  final (agentTransport, clientTransport) = _createLinkedTransports();

  // Create agent side
  // ignore: unused_local_variable
  final agent = AgentSideConnection(
    agentTransport,
    handlerFactory: (conn) => _EchoAgentHandler(conn),
    capabilityEnforcement: CapabilityEnforcement.permissive,
  );

  // Create client side
  final clientHandler = _PrintingClientHandler();
  final client = ClientSideConnection(
    clientTransport,
    handler: clientHandler,
    clientCapabilities: const ClientCapabilities(
      fs: FileSystemCapability(readTextFile: true),
    ),
    capabilityEnforcement: CapabilityEnforcement.permissive,
  );

  // 1. Initialize
  // ignore: avoid_print
  print('1. Initializing...');
  final initResp = await client.sendInitialize(protocolVersion: 1);
  // ignore: avoid_print
  print('   Protocol version: ${initResp.protocolVersion}');

  // 2. Create session
  // ignore: avoid_print
  print('\n2. Creating session...');
  final sessionResp = await client.sendNewSession(cwd: '/home');
  // ignore: avoid_print
  print('   Session ID: ${sessionResp.sessionId}');

  // 3. Send prompt (the agent echoes it back as a session update)
  // ignore: avoid_print
  print('\n3. Sending prompt...');
  final promptResp = await client.sendPrompt(
    sessionId: sessionResp.sessionId,
    prompt: [const TextContent(text: 'Hello, agent!')],
  );
  // ignore: avoid_print
  print('   Stop reason: ${promptResp.stopReason}');

  // Give time for any remaining session updates to arrive
  await Future<void>.delayed(const Duration(milliseconds: 100));

  // 4. Clean up
  // ignore: avoid_print
  print('\n4. Closing...');
  await client.close();
  await agent.close();
  // ignore: avoid_print
  print('   Done!');
}
