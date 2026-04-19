/// A client that spawns an ACP agent as a subprocess and talks to it.
///
/// This is the real-world pattern. When Zed connects to Gemini CLI, Claude
/// Agent, or Codex — or when a JetBrains IDE loads an agent from its ACP
/// Registry — the editor is acting as a client that spawns the agent
/// process and communicates with it over stdio. This example shows you how
/// to do the same from your own Dart code.
///
/// Concretely:
///
/// 1. `StdioProcessTransport.start` launches `example/main.dart` as
///    a child process and pipes its stdin/stdout.
/// 2. `ClientSideConnection` wraps the transport and gives you typed
///    `sendInitialize`, `sendNewSession`, `sendPrompt` methods.
/// 3. Session updates the agent streams back flow through the handler's
///    `onSessionUpdate` callback (and the `sessionUpdates` broadcast stream).
///
/// ## Running it
///
/// ```
/// dart run example/subprocess_client.dart
/// ```
///
/// `main.dart` is resolved relative to *this script's* location
/// (via `Platform.script`), so the example works regardless of the
/// directory you run it from.
///
/// ## What you'll see
///
/// ```
/// [client] spawning agent subprocess…
/// [client] initialize → protocol 1, agent=Echo Agent
/// [client] session/new → session-1
/// [client] sending prompt: "Hello, agent!"
/// [client] <- session update (AgentMessageChunk): Echo: Hello, agent!
/// [client] prompt returned, stop reason: end_turn
/// [client] closing…
/// ```
///
/// ## Further reading
///
/// - Zed's external agents: https://zed.dev/docs/ai/external-agents
/// - JetBrains ACP: https://www.jetbrains.com/help/ai-assistant/acp.html
/// - ACP spec: https://agentclientprotocol.com/
library;

import 'dart:async';
import 'dart:io';

import 'package:acp/client.dart';
import 'package:acp/schema.dart';
import 'package:acp/transport.dart';

/// Minimal client handler. An editor's real handler would read and write
/// files on disk, run terminal commands, and show permission dialogs — see
/// `project_assistant.dart` for a fuller example. Here we only print
/// incoming session updates so you can see them arrive.
class PrintingClientHandler extends ClientHandler {
  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    switch (update) {
      case AgentMessageChunk(content: final TextContent text):
        stdout.writeln(
          '[client] <- session update (AgentMessageChunk): ${text.text}',
        );
      default:
        stdout.writeln('[client] <- session update (${update.runtimeType})');
    }
  }
}

Future<void> main() async {
  stdout.writeln('[client] spawning agent subprocess…');

  // `Platform.resolvedExecutable` is the `dart` binary currently running.
  // We launch a sibling `dart run example/main.dart` — the exact
  // same dance Zed does when it spawns Gemini CLI or Claude Agent, just
  // without needing a separately installed CLI.
  //
  // Resolve the agent script relative to *this file's* location so the
  // example works regardless of the caller's CWD.
  final agentScript =
      Uri.file(Platform.script.toFilePath()).resolve('main.dart').toFilePath();
  final transport = await StdioProcessTransport.start(
    Platform.resolvedExecutable,
    ['run', agentScript],
  );

  final client = ClientSideConnection(
    transport,
    handler: PrintingClientHandler(),
    clientInfo: const ImplementationInfo(
      name: 'subprocess-client-example',
      title: 'Subprocess Client Example',
      version: '0.1.0',
    ),
  );

  // 1. Handshake. Returns the agent's advertised capabilities.
  final init = await client.sendInitialize(protocolVersion: 1);
  final agentName =
      init.agentInfo?.title ?? init.agentInfo?.name ?? 'unknown agent';
  stdout.writeln(
    '[client] initialize → protocol ${init.protocolVersion}, agent=$agentName',
  );

  // 2. Create a session. `cwd` tells the agent which directory the user is
  //    working in. It must be absolute.
  final session = await client.sendNewSession(cwd: Directory.current.path);
  stdout.writeln('[client] session/new → ${session.sessionId}');

  // 3. Send a prompt. The agent will stream one or more session updates
  //    (via `notifySessionUpdate`) before returning here with the turn's
  //    final stop reason.
  stdout.writeln('[client] sending prompt: "Hello, agent!"');
  final response = await client.sendPrompt(
    sessionId: session.sessionId,
    prompt: const [TextContent(text: 'Hello, agent!')],
  );
  stdout.writeln(
    '[client] prompt returned, stop reason: ${response.stopReason}',
  );
  // session/update notifications are guaranteed to be delivered before
  // sendPrompt resolves — no `Future.delayed` is needed here. In a real
  // editor, updates render as they arrive over the same stream.

  // 4. Close the client. `StdioProcessTransport` sends SIGTERM to the agent
  //    subprocess on close, waits briefly, and SIGKILLs if necessary.
  stdout.writeln('[client] closing…');
  await client.close();
}
