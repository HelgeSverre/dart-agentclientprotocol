# acp

[![pub package](https://img.shields.io/pub/v/acp.svg)](https://pub.dev/packages/acp)
[![CI](https://github.com/HelgeSverre/dart-agentclientprotocol/actions/workflows/ci.yml/badge.svg)](https://github.com/HelgeSverre/dart-agentclientprotocol/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Dart SDK for the [Agent Client Protocol (ACP)](https://agentclientprotocol.com/) — connect any editor to any coding agent.

Implements [ACP v0.10.8](https://agentclientprotocol.com/protocol/overview) with typed schema models, pluggable transports, and connection management for both agent and client sides.

## Installation

Add `acp` to your `pubspec.yaml`:

```yaml
dependencies:
  acp: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Usage

### Building an Agent

Implement `AgentHandler` and connect it to a transport:

```dart
import 'package:acp/agent.dart';
import 'package:acp/schema.dart';
import 'package:acp/transport.dart';

class MyAgent extends AgentHandler {
  final AgentSideConnection _conn;
  MyAgent(this._conn);

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
    final text = request.prompt
        .whereType<TextContent>()
        .map((c) => c.text)
        .join('\n');

    // Stream a response back to the client.
    await _conn.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(
        content: {'type': 'text', 'text': 'You said: $text'},
      ),
    );

    return const PromptResponse(stopReason: 'end_turn');
  }
}

void main() {
  final transport = StdioTransport();
  transport.start();

  AgentSideConnection(
    transport,
    handlerFactory: (conn) => MyAgent(conn),
  );
}
```

### Building a Client

Implement `ClientHandler` and spawn an agent process:

```dart
import 'package:acp/client.dart';
import 'package:acp/schema.dart';
import 'package:acp/transport.dart';

class MyClientHandler extends ClientHandler {
  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    switch (update) {
      case AgentMessageChunk(:final content):
        print('[session/$sessionId] Agent: ${content['text']}');
      default:
        print('[session/$sessionId] ${update.runtimeType}');
    }
  }
}

Future<void> main() async {
  // Spawn the agent as a subprocess.
  final transport = await StdioProcessTransport.start(
    'dart', ['run', 'example/basic_agent.dart'],
  );

  final client = ClientSideConnection(
    transport,
    handler: MyClientHandler(),
    clientCapabilities: ClientCapabilities(
      fs: FileSystemCapability(readTextFile: true),
      terminal: true,
    ),
  );

  // Handshake.
  await client.sendInitialize(protocolVersion: 1);

  // Create a session and send a prompt.
  final session = await client.sendNewSession(cwd: '/home/user');
  final response = await client.sendPrompt(
    sessionId: session.sessionId,
    prompt: [TextContent(text: 'Hello, agent!')],
  );
  print('Stop reason: ${response.stopReason}');

  await client.close();
}
```

### Transports

| Transport               | Use case                                              |
| ----------------------- | ----------------------------------------------------- |
| `StdioTransport`        | Agent-side: communicate over stdin/stdout via NDJSON  |
| `StdioProcessTransport` | Client-side: spawn an agent subprocess                |
| `HttpSseTransport`      | HTTP POST + Server-Sent Events                        |
| `WebSocketTransport`    | WebSocket text frames                                 |
| `ReconnectingTransport` | Auto-reconnect wrapper with exponential backoff       |
| `AcpTransport`          | Interface for implementing custom transports          |

### Key Concepts

- **Connection state machine** — idle, opening, open, closing, closed — with `onStateChange` stream.
- **Capability negotiation** — both sides advertise capabilities during `initialize`. Strict mode (default) rejects unsupported operations.
- **Cancellation** — every handler method receives an `AcpCancellationToken` for cooperative cancellation.
- **Extension methods** — send and receive custom `_`-prefixed methods via `extMethod()` / `onExtMethod()`.
- **Session updates** — agents stream `SessionUpdate` notifications (message chunks, tool calls, plan updates) to clients.
- **Connection keepalive** — periodic `$/ping` notifications with automatic `$/pong` responses detect dead connections. Configure via `keepaliveInterval` (ping frequency) and `keepaliveTimeout` (max wait for pong before closing):
  ```dart
  final conn = Connection(transport,
    keepaliveInterval: Duration(seconds: 30),
    keepaliveTimeout: Duration(seconds: 10),
  );
  ```
- **Message batching** — `JsonRpcMessage.parseBatch()` handles both single JSON-RPC objects and batch arrays per the JSON-RPC 2.0 spec. `WebSocketTransport` uses this automatically:
  ```dart
  final messages = JsonRpcMessage.parseBatch(jsonDecode(rawData));
  ```

## Real-World Examples

### Editor Integration

A client that launches an ACP-compatible coding agent and pipes prompts from an editor:

```dart
final transport = await StdioProcessTransport.start(
  'my-coding-agent', ['--stdio'],
);

final client = ClientSideConnection(
  transport,
  handler: EditorClientHandler(editorPane),
  clientCapabilities: ClientCapabilities(
    fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
    terminal: true,
  ),
);

await client.sendInitialize(
  protocolVersion: 1,
  clientInfo: ImplementationInfo(name: 'my-editor', version: '1.0.0'),
);
```

### File Operations (Agent-to-Client)

Agents can request file access from the client:

```dart
// Inside an AgentHandler.prompt() implementation:
final fileContent = await _conn.sendReadTextFile(
  sessionId: request.sessionId,
  path: '/workspace/lib/main.dart',
);

await _conn.sendWriteTextFile(
  sessionId: request.sessionId,
  path: '/workspace/lib/main.dart',
  content: modifiedContent,
);
```

### Terminal Management

Agents can create and manage terminals on the client:

```dart
final terminal = await _conn.createTerminal(
  sessionId: request.sessionId,
  command: 'dart test',
);

// Stream output, wait for completion, then release.
final output = await terminal.output();
final exitCode = await terminal.waitForExit();
await terminal.release();
```

## Development

### Prerequisites

- Dart SDK `^3.7.0`

### Running Tests

```bash
dart test                        # All tests
dart test -t unit                # Unit tests only
dart test -t integration         # Integration tests only
dart test -t compliance          # Wire format compliance tests
```

### Code Generation

`lib/src/schema/` is generated from the official ACP JSON Schema files checked in at `tool/upstream/schema/`. To update:

```bash
# Download latest upstream schema
dart run tool/schema_sync/sync.dart

# Regenerate Dart models
dart run tool/generate/generate.dart

# Verify
dart analyze && dart test
```

CI verifies codegen freshness — if someone updates the schema but forgets to regenerate, the build fails.

### Linting & Formatting

```bash
dart analyze                     # Static analysis
dart format --set-exit-if-changed .  # Check formatting
```

### Project Structure

```
lib/
  acp.dart              # Barrel export (everything)
  agent.dart            # Agent-side: AgentHandler, AgentSideConnection
  client.dart           # Client-side: ClientHandler, ClientSideConnection
  schema.dart           # All typed request/response/notification models
  transport.dart        # AcpTransport, StdioTransport, StdioProcessTransport
  src/
    protocol/           # Connection, state machine, JSON-RPC, dispatch
    schema/             # Individual schema model files
    transport/          # Transport implementations
test/
  unit/                 # Unit tests
  integration/          # Integration tests (subprocess transports)
  compliance/           # Wire format compliance tests
  golden/               # Serialization golden tests
  fixtures/             # JSON fixtures for tests
  helpers/              # Test utilities (mock/linked transports)
example/
  basic_agent.dart      # Minimal echo agent
  basic_client.dart     # Minimal client demo
tool/
  generate/              # Schema → Dart code generator
  schema_sync/           # Downloads upstream JSON Schema files
  upstream/schema/       # Checked-in copies of official ACP schema
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Ensure all tests pass (`dart test`)
4. Ensure code passes analysis (`dart analyze`) and formatting (`dart format --set-exit-if-changed .`)
5. Open a pull request

## License

[MIT](LICENSE)
