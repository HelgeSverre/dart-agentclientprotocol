/// A streaming agent that shows how a real LLM-backed agent progresses
/// through a prompt turn.
///
/// Real agents don't reply with a single blob of text — they stream output
/// as it's generated, interleaving several kinds of updates:
///
///   1. **Thought chunks**: internal reasoning the editor can optionally hide.
///   2. **Plan updates**: the agent's TODO list, refined as it works.
///   3. **Message chunks**: the user-visible answer, streamed token-by-token.
///   4. **Tool calls** (not shown here — see `project_assistant.dart`).
///
/// This file wires an agent and client together in-process over an in-memory
/// transport so the streaming is easy to follow. In production you'd use
/// `StdioProcessTransport` (see `subprocess_client.dart`) or `WebSocketTransport`.
///
/// ## Running it
///
/// ```
/// dart run example/streaming_agent.dart
/// ```
///
/// ## What you'll see
///
/// The client prints each session update as it arrives, with elapsed time
/// from the prompt, so you can watch the turn unfold.
library;

import 'dart:io';

import 'package:acp/acp.dart';

import 'in_memory_transport.dart';

Future<void> main() async {
  final (agentTransport, clientTransport) = createInMemoryTransports();

  final agent = AgentSideConnection(
    agentTransport,
    handlerFactory: _StreamingAgent.new,
  );

  final client = ClientSideConnection(
    clientTransport,
    handler: _NarratingClient(),
  );

  await client.sendInitialize(protocolVersion: 1);
  final session = await client.sendNewSession(cwd: '/tmp');

  stdout.writeln('--- prompt turn starts ---');
  final stopwatch = Stopwatch()..start();

  // Subscribe to the broadcast stream so we can tag each update with a
  // timestamp relative to when the prompt started.
  final updates = client.sessionUpdates.listen((event) {
    final ms = stopwatch.elapsedMilliseconds.toString().padLeft(4);
    _describe(event.update, elapsedMs: ms);
  });

  final response = await client.sendPrompt(
    sessionId: session.sessionId,
    prompt: const [TextContent(text: 'Summarize the history of the internet.')],
  );

  stdout.writeln(
    '--- prompt turn ended after ${stopwatch.elapsedMilliseconds}ms ---',
  );
  stdout.writeln('stop reason: ${response.stopReason}');

  await updates.cancel();
  await client.close();
  await agent.close();
}

// --------------------------------------------------------------------------
// Agent: streams thoughts, a plan, and a multi-chunk message.
// --------------------------------------------------------------------------

class _StreamingAgent extends AgentHandler {
  final AgentSideConnection _connection;
  _StreamingAgent(this._connection);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const NewSessionResponse(sessionId: 'stream-1');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final sessionId = request.sessionId;

    // 1. A thought chunk: the agent's internal reasoning. Editors typically
    //    surface these under a "thinking" disclosure or hide them by default.
    await _send(
      sessionId,
      const AgentThoughtChunk(
        content: TextContent(text: 'Thinking about the request…'),
      ),
    );
    await _tick();

    // 2. A plan update: the agent declares its TODO list. Editors can render
    //    this as a live-updating checklist.
    await _send(
      sessionId,
      const PlanUpdate(
        entries: [
          {
            'content': 'Gather key milestones',
            'status': 'in_progress',
            'priority': 'high',
          },
          {
            'content': 'Write the summary',
            'status': 'pending',
            'priority': 'high',
          },
        ],
      ),
    );
    await _tick();

    // 3. Message chunks: the user-visible answer, streamed a few words at a
    //    time so the client can display tokens as they arrive.
    const tokens = [
      'The internet ',
      'grew out of ARPANET in the 1960s, ',
      'gained TCP/IP in the 1980s, ',
      'and reached households ',
      'after the World Wide Web launched in 1991.',
    ];
    for (final token in tokens) {
      await _send(
        sessionId,
        AgentMessageChunk(content: TextContent(text: token)),
      );
      await _tick();
    }

    // 4. Mark the plan complete before finishing the turn.
    await _send(
      sessionId,
      const PlanUpdate(
        entries: [
          {
            'content': 'Gather key milestones',
            'status': 'completed',
            'priority': 'high',
          },
          {
            'content': 'Write the summary',
            'status': 'completed',
            'priority': 'high',
          },
        ],
      ),
    );

    return const PromptResponse(stopReason: StopReason.endTurn);
  }

  Future<void> _send(String sessionId, SessionUpdate update) =>
      _connection.notifySessionUpdate(sessionId, update);

  /// Simulated token latency. Real LLM streaming is bursty; this is just to
  /// make the ordering visible.
  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 80));
}

// --------------------------------------------------------------------------
// Client: minimal handler. The `_describe` function in main does the
// narration so we can include elapsed time per update.
// --------------------------------------------------------------------------

class _NarratingClient extends ClientHandler {
  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    // Handler ignores the update because `main()` subscribes to the
    // broadcast `sessionUpdates` stream instead — that's how we attach
    // elapsed timing. Either path works; real code usually picks one.
  }
}

void _describe(SessionUpdate update, {required String elapsedMs}) {
  final tag = '[+${elapsedMs}ms]';
  switch (update) {
    case AgentThoughtChunk(content: final TextContent text):
      stdout.writeln('$tag thought: ${text.text}');
    case PlanUpdate(:final entries):
      stdout.writeln('$tag plan:');
      for (final entry in entries) {
        stdout.writeln('         - [${entry['status']}] ${entry['content']}');
      }
    case AgentMessageChunk(content: final TextContent text):
      stdout.writeln('$tag message chunk: ${text.text}');
    default:
      stdout.writeln('$tag ${update.runtimeType}');
  }
}

// In-memory transport plumbing lives in `in_memory_transport.dart`,
// imported above, and is shared with `project_assistant.dart`.
