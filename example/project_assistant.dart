/// The full ACP experience in one file: a project assistant agent paired
/// with a client that behaves like a small code editor.
///
/// If `basic_agent.dart` is ACP's "hello world" and `subprocess_client.dart`
/// shows the real spawning pattern, this file shows you *every* non-trivial
/// flow you'd want in a coding assistant:
///
///   1. **Initialize & capabilities**: the client advertises filesystem and
///      terminal support; the agent advertises session listing and prompt
///      features it can handle.
///   2. **Session listing**: the client asks for previous sessions before
///      starting a new one — the pattern a "history sidebar" uses.
///   3. **Session creation**: the agent returns session-level config options
///      (e.g. review depth) and modes (review / edit).
///   4. **Plan updates**: the agent streams its checklist so the editor can
///      render a live TODO.
///   5. **Permission prompt**: before reading a file, the agent asks the
///      user for permission via `session/request_permission`. The client
///      responds with the chosen option.
///   6. **Filesystem access**: after permission is granted, the agent calls
///      back into the client with `fs/read_text_file`.
///   7. **Terminal use**: the agent spawns a short command through the
///      client (`terminal/create` + `terminal/wait_for_exit`).
///   8. **Final message**: the agent summarises what it learned and returns
///      a `PromptResponse` with a stop reason.
///
/// For this demo both peers live in-process and talk over linked in-memory
/// transports so you don't need a subprocess. The same handler code works
/// unchanged over stdio or WebSocket.
///
/// ## Running it
///
/// ```
/// dart run example/project_assistant.dart
/// ```
///
/// ## Real-world parallels
///
/// This mirrors what Zed does when a user chats with Claude Agent or Codex,
/// and what JetBrains IDEs do when a user picks an agent from the ACP
/// Registry. The editor is the client; the LLM-backed tool is the agent.
library;

import 'dart:async';
import 'dart:io';

import 'package:acp/acp.dart';

Future<void> main() async {
  final (agentTransport, clientTransport) = _createLinkedTransports();

  final agent = AgentSideConnection(
    agentTransport,
    handlerFactory: (connection) => _ProjectAssistantAgent(connection),
  );

  final client = ClientSideConnection(
    clientTransport,
    handler: _ProjectClient(),
    clientInfo: const ImplementationInfo(
      name: 'dart-example-client',
      title: 'Dart Example Client',
      version: '0.1.0',
    ),
    clientCapabilities: const ClientCapabilities(
      fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
      terminal: true,
    ),
  );

  stdout.writeln('Initializing ACP conversation');
  final initialize = await client.sendInitialize(protocolVersion: 1);
  stdout.writeln(
    'Agent: ${initialize.agentInfo?.title ?? initialize.agentInfo?.name}',
  );

  stdout.writeln('\nDiscovering previous sessions');
  final sessions = await client.sendListSessions(cwd: Directory.current.path);
  for (final session in sessions.sessions) {
    stdout.writeln(' - ${session.sessionId}: ${session.title}');
  }

  stdout.writeln('\nCreating project review session');
  final newSession = await client.sendNewSession(cwd: Directory.current.path);

  final updates = client.sessionUpdates.listen((event) {
    _printUpdate(event.sessionId, event.update);
  });

  stdout.writeln('\nSending prompt');
  final prompt = await client.sendPrompt(
    sessionId: newSession.sessionId,
    prompt: const [
      TextContent(
        text: 'Review this Dart package and summarize its project shape.',
      ),
    ],
  );
  stdout.writeln('\nTurn finished: ${prompt.stopReason}');

  await updates.cancel();
  await client.close();
  await agent.close();
}

(AcpTransport, AcpTransport) _createLinkedTransports() {
  // ignore: close_sinks
  final leftToRight = StreamController<JsonRpcMessage>();
  // ignore: close_sinks
  final rightToLeft = StreamController<JsonRpcMessage>();

  return (
    _LinkedTransport(inbound: rightToLeft.stream, outbound: leftToRight),
    _LinkedTransport(inbound: leftToRight.stream, outbound: rightToLeft),
  );
}

final class _LinkedTransport implements AcpTransport {
  final Stream<JsonRpcMessage> _inbound;
  final StreamController<JsonRpcMessage> _outbound;
  bool _closed = false;

  _LinkedTransport({
    required Stream<JsonRpcMessage> inbound,
    required StreamController<JsonRpcMessage> outbound,
  }) : _inbound = inbound,
       _outbound = outbound;

  @override
  Stream<JsonRpcMessage> get messages => _inbound;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) {
      throw StateError('Transport is closed');
    }
    _outbound.add(message);
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _outbound.close();
  }
}

// ---------------------------------------------------------------------------
// The agent side: decides what to do, asks the client for help when needed.
// ---------------------------------------------------------------------------

final class _ProjectAssistantAgent extends AgentHandler {
  final AgentSideConnection _connection;
  final Map<String, SessionInfo> _sessions = <String, SessionInfo>{};

  _ProjectAssistantAgent(this._connection);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return const InitializeResponse(
      protocolVersion: 1,
      agentInfo: ImplementationInfo(
        name: 'project-assistant-agent',
        title: 'Project Assistant Agent',
        version: '0.1.0',
      ),
      agentCapabilities: AgentCapabilities(
        promptCapabilities: PromptCapabilities(embeddedContext: true),
        sessionCapabilities: SessionCapabilities(list: <String, dynamic>{}),
      ),
    );
  }

  @override
  Future<ListSessionsResponse> listSessions(
    ListSessionsRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final sessions =
        _sessions.values.where((session) {
          return request.cwd == null || session.cwd == request.cwd;
        }).toList();
    return ListSessionsResponse(sessions: sessions);
  }

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final sessionId = 'project-${_sessions.length + 1}';
    final now = DateTime.now().toUtc().toIso8601String();
    _sessions[sessionId] = SessionInfo(
      cwd: request.cwd,
      sessionId: sessionId,
      title: 'Project review',
      updatedAt: now,
    );

    return NewSessionResponse(
      sessionId: sessionId,
      configOptions: const [
        {
          'id': 'depth',
          'title': 'Review depth',
          'type': 'select',
          'values': ['quick', 'standard', 'deep'],
          'value': 'standard',
        },
      ],
      modes: const {
        'currentModeId': 'review',
        'availableModes': [
          {'id': 'review', 'name': 'Review'},
          {'id': 'edit', 'name': 'Edit'},
        ],
      },
    );
  }

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final session = _sessions[request.sessionId];
    if (session == null) {
      throw RpcErrorException.invalidParams('Unknown session');
    }

    await _connection.notifySessionUpdate(
      request.sessionId,
      SessionInfoUpdate(
        title: 'Reviewing ${_basename(session.cwd)}',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );

    await _connection.notifySessionUpdate(
      request.sessionId,
      const AvailableCommandsSessionUpdate(
        availableCommands: [
          {
            'name': 'summarize',
            'description': 'Summarize the current project structure.',
          },
          {
            'name': 'test',
            'description': 'Run the package test command through the client.',
          },
        ],
      ),
    );

    await _connection.notifySessionUpdate(
      request.sessionId,
      const PlanUpdate(
        entries: [
          {
            'content': 'Read package metadata',
            'priority': 'high',
            'status': 'in_progress',
          },
          {
            'content': 'Check local Dart toolchain',
            'priority': 'medium',
            'status': 'pending',
          },
          {
            'content': 'Summarize findings',
            'priority': 'high',
            'status': 'pending',
          },
        ],
      ),
    );

    // Ask the user (via the editor/client) for permission before touching
    // the filesystem. This is the central safety feature of ACP: the agent
    // can request capabilities at a specific moment, and the client decides
    // how (and whether) to surface that to the user.
    final permission = await _connection.sendRequestPermission(
      sessionId: request.sessionId,
      toolCall: const {
        'title': 'Read pubspec.yaml',
        'kind': 'read',
        'path': 'pubspec.yaml',
      },
      options: const [
        {'optionId': 'allow_once', 'name': 'Allow once', 'kind': 'allow_once'},
        {'optionId': 'reject_once', 'name': 'Reject', 'kind': 'reject_once'},
      ],
    );

    var packageName = 'unknown package';
    if (permission.outcome['outcome'] == 'selected' &&
        permission.outcome['optionId'] == 'allow_once') {
      // Now we can call back into the client to read the file. The client's
      // `readTextFile` handler runs with whatever permissions it has.
      final pubspec = await _connection.sendReadTextFile(
        sessionId: request.sessionId,
        path: '${session.cwd}/pubspec.yaml',
      );
      packageName = _extractPackageName(pubspec.content);
    }

    // Spawn a short command through the client. `TerminalHandle` wraps the
    // raw `terminal/*` RPC calls so you can treat it almost like a Process.
    final terminal = await _connection.createTerminalHandle(
      sessionId: request.sessionId,
      command: Platform.resolvedExecutable,
      args: const ['--version'],
      cwd: session.cwd,
      outputByteLimit: 4096,
    );
    final output = await terminal.output();
    await terminal.waitForExit();
    await terminal.dispose();

    await _connection.notifySessionUpdate(
      request.sessionId,
      const PlanUpdate(
        entries: [
          {
            'content': 'Read package metadata',
            'priority': 'high',
            'status': 'completed',
          },
          {
            'content': 'Check local Dart toolchain',
            'priority': 'medium',
            'status': 'completed',
          },
          {
            'content': 'Summarize findings',
            'priority': 'high',
            'status': 'completed',
          },
        ],
      ),
    );

    await _connection.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(
        content:
            TextContent(
              text:
                  'Package `$packageName` is available in `${session.cwd}`. '
                  'The client exposed filesystem and terminal capabilities; '
                  'Dart reported `${output.output.trim()}`.',
            ).toJson(),
      ),
    );

    return const PromptResponse(stopReason: 'end_turn');
  }
}

// ---------------------------------------------------------------------------
// The client side: acts like a small code editor. Reads files, runs
// terminal commands, and decides how to respond to permission prompts.
// ---------------------------------------------------------------------------

final class _ProjectClient extends ClientHandler {
  final Map<String, _TerminalRun> _terminals = <String, _TerminalRun>{};
  var _nextTerminalId = 0;

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {}

  @override
  Future<ReadTextFileResponse> readTextFile(
    ReadTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final file = File(request.path);
    return ReadTextFileResponse(content: await file.readAsString());
  }

  @override
  Future<CreateTerminalResponse> createTerminal(
    CreateTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final id = 'terminal-${++_nextTerminalId}';
    final result = Process.run(
      request.command,
      request.args,
      workingDirectory: request.cwd,
      runInShell: false,
    );
    _terminals[id] = _TerminalRun(result);
    return CreateTerminalResponse(terminalId: id);
  }

  @override
  Future<TerminalOutputResponse> terminalOutput(
    TerminalOutputRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final result = await _terminalResult(request.terminalId);
    return TerminalOutputResponse(
      output: _processOutput(result),
      truncated: false,
      exitStatus: <String, dynamic>{'exitCode': result.exitCode},
    );
  }

  @override
  Future<WaitForTerminalExitResponse> waitForTerminalExit(
    WaitForTerminalExitRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final result = await _terminalResult(request.terminalId);
    return WaitForTerminalExitResponse(exitCode: result.exitCode);
  }

  @override
  Future<ReleaseTerminalResponse> releaseTerminal(
    ReleaseTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    _terminals.remove(request.terminalId);
    return const ReleaseTerminalResponse();
  }

  @override
  Future<KillTerminalCommandResponse> killTerminal(
    KillTerminalCommandRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    _terminals.remove(request.terminalId);
    return const KillTerminalCommandResponse();
  }

  /// A real editor would pop a dialog here and wait for the user. For the
  /// demo we auto-select the "allow_once" option so the script runs to
  /// completion.
  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final selected = request.options.firstWhere(
      (option) => option['kind'] == 'allow_once',
      orElse: () => request.options.first,
    );
    stdout.writeln(
      'Permission requested: ${request.toolCall['title']} -> '
      '${selected['name']}',
    );
    return RequestPermissionResponse(
      outcome: <String, dynamic>{
        'outcome': 'selected',
        'optionId': selected['optionId'],
      },
    );
  }

  Future<ProcessResult> _terminalResult(String terminalId) async {
    final terminal = _terminals[terminalId];
    if (terminal == null) {
      throw RpcErrorException.invalidParams('Unknown terminal: $terminalId');
    }
    return terminal.result;
  }
}

final class _TerminalRun {
  final Future<ProcessResult> result;

  const _TerminalRun(this.result);
}

void _printUpdate(String sessionId, SessionUpdate update) {
  switch (update) {
    case SessionInfoUpdate(:final title):
      stdout.writeln('[$sessionId] title: $title');
    case AvailableCommandsSessionUpdate(:final availableCommands):
      final names = availableCommands.map((command) => command['name']);
      stdout.writeln('[$sessionId] commands: ${names.join(', ')}');
    case PlanUpdate(:final entries):
      stdout.writeln('[$sessionId] plan:');
      for (final entry in entries) {
        stdout.writeln(' - ${entry['status']}: ${entry['content']}');
      }
    case AgentMessageChunk(:final content):
      stdout.writeln('\n[$sessionId] ${content['text']}');
    default:
      stdout.writeln('[$sessionId] ${update.runtimeType}');
  }
}

String _extractPackageName(String pubspec) {
  for (final line in pubspec.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('name:')) {
      return trimmed.substring('name:'.length).trim();
    }
  }
  return 'unknown package';
}

String _processOutput(ProcessResult result) {
  final stdoutText = result.stdout is String ? result.stdout as String : '';
  final stderrText = result.stderr is String ? result.stderr as String : '';
  return [stdoutText, stderrText].where((text) => text.isNotEmpty).join('\n');
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final segments = normalized.split('/').where((segment) => segment.isNotEmpty);
  return segments.isEmpty ? path : segments.last;
}
