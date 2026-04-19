# ACP for Dart

[![Pub Version](https://img.shields.io/pub/v/acp.svg)](https://pub.dev/packages/acp)
[![Pub Points](https://img.shields.io/pub/points/acp.svg)](https://pub.dev/packages/acp/score)
[![CI](https://img.shields.io/github/actions/workflow/status/HelgeSverre/dart-agentclientprotocol/ci.yml?branch=main&label=CI)](https://github.com/HelgeSverre/dart-agentclientprotocol/actions/workflows/ci.yml)

Dart SDK for the [Agent Client Protocol (ACP)](https://agentclientprotocol.com/).

This package targets the official [ACP v0.12.0](https://github.com/agentclientprotocol/agent-client-protocol/releases/tag/v0.12.0) schema. It provides generated typed schema models, JSON-RPC connection management, capability enforcement, request cancellation, and transports for building ACP agents and clients.

## Installation

```yaml
dependencies:
  acp: ^0.1.0
```

```bash
dart pub get
```

## Quick Start

### Agent

```dart
import 'package:acp/agent.dart';
import 'package:acp/schema.dart';
import 'package:acp/transport.dart';

final class MyAgent extends AgentHandler {
  final AgentSideConnection _connection;

  MyAgent(this._connection);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return const InitializeResponse(
      protocolVersion: 1,
      agentCapabilities: AgentCapabilities(
        sessionCapabilities: SessionCapabilities(list: <String, dynamic>{}),
      ),
    );
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
    await _connection.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(
        content: const TextContent(text: 'Hello from the agent').toJson(),
      ),
    );
    return const PromptResponse(stopReason: 'end_turn');
  }
}

void main() {
  final transport = StdioTransport()..start();
  AgentSideConnection(
    transport,
    handlerFactory: (connection) => MyAgent(connection),
  );
}
```

### Client

```dart
import 'dart:io';

import 'package:acp/client.dart';
import 'package:acp/schema.dart';
import 'package:acp/transport.dart';

final class MyClientHandler extends ClientHandler {
  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    if (update case AgentMessageChunk(:final content)) {
      stdout.writeln('[session/$sessionId] ${content['text']}');
    }
  }
}

Future<void> main() async {
  final transport = await StdioProcessTransport.start(
    'dart',
    ['run', 'example/basic_agent.dart'],
  );

  final client = ClientSideConnection(
    transport,
    handler: MyClientHandler(),
    clientCapabilities: const ClientCapabilities(
      fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
      terminal: true,
    ),
  );

  await client.sendInitialize(protocolVersion: 1);
  final session = await client.sendNewSession(cwd: Directory.current.path);
  final response = await client.sendPrompt(
    sessionId: session.sessionId,
    prompt: const [TextContent(text: 'Hello, agent!')],
  );

  stdout.writeln('Stop reason: ${response.stopReason}');
  await client.close();
}
```

## Example

Run the project assistant example for a fuller in-process scenario:

```bash
dart run example/project_assistant.dart
```

It demonstrates initialization with implementation metadata, client filesystem and terminal capabilities, stable `session/list`, `session/new`, `session/prompt`, permission requests, file reads, terminal execution, plan updates, available commands, session info updates, and streamed agent message chunks.

## Transports

| Transport                   | Use case                                       |
| --------------------------- | ---------------------------------------------- |
| `StdioTransport`            | Agent-side NDJSON over stdin/stdout            |
| `StdioProcessTransport`     | Client-side subprocess spawning                |
| `HttpSseTransport`          | HTTP POST plus Server-Sent Events              |
| `StreamableHttpTransport`   | Streamable HTTP transport                      |
| `WebSocketTransport`        | VM WebSocket text frames                       |
| `BrowserWebSocketTransport` | Browser WebSocket text frames                  |
| `ReconnectingTransport`     | Reconnect wrapper for reconnectable transports |
| `AcpTransport`              | Interface for custom transports                |

## Protocol Features

- Typed models generated from the checked-in ACP v0.12.0 schema.
- JSON-RPC 2.0 requests, responses, notifications, and batch parsing.
- Stable `session/list` support guarded by `sessionCapabilities.list`.
- Unstable `session/fork` gated by `useUnstableProtocol`.
- Cooperative request cancellation via `$/cancel_request` and `AcpCancellationToken`.
- Client-to-agent and agent-to-client extension methods with `_` prefixes.
- Strict capability enforcement by default, with a permissive mode for integration work.
- Unknown-field round trips through `extensionData` and `_meta`.
- Unknown union fallback models for forward compatibility.
- Terminal lifecycle helper through `TerminalHandle`.

## Development

```bash
dart analyze
dart test
dart run example/project_assistant.dart
```

Schema sync and generation:

```bash
dart run tool/schema_sync/sync.dart
dart run tool/generate/generate.dart
dart format .
dart analyze && dart test
```

The schema files live under `tool/upstream/schema/`. Official reference material fetched for the current review is stored under `docs/references/agent-client-protocol-v0.12.0/`.

## Project Structure

```text
lib/
  acp.dart
  agent.dart
  client.dart
  schema.dart
  transport.dart
  src/
    protocol/
    schema/
    transport/
test/
  unit/
  integration/
  compliance/
  golden/
  helpers/
example/
  basic_agent.dart
  basic_client.dart
  project_assistant.dart
tool/
  generate/
  schema_sync/
  upstream/schema/
docs/references/
  agent-client-protocol-v0.12.0/
```
