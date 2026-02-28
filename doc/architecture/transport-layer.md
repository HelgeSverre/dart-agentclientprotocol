# Transport Layer

The transport layer handles raw framed message I/O with no ACP-specific
semantics. All transports implement the `AcpTransport` interface.

## `AcpTransport` Interface

**File:** `lib/src/transport/acp_transport.dart`

```dart
abstract interface class AcpTransport {
  Stream<JsonRpcMessage> get messages;
  Future<void> send(JsonRpcMessage message);
  Future<void> close();
}
```

### Contract

- **Ordering:** Messages are delivered in the order `send()` is called.
- **Close semantics:**
  - After `close()`, the `messages` stream completes.
  - After `close()`, `send()` throws `StateError`.
  - Calling `close()` more than once is a no-op.
- **Remote disconnect:** If the remote side disconnects, the `messages` stream
  completes naturally.

## `StdioTransport`

**File:** `lib/src/transport/stdio_transport.dart`

NDJSON (newline-delimited JSON) over an existing stdin/stdout pair. Each
JSON-RPC message is a single JSON line followed by `\n`.

### Usage pattern

```dart
final transport = StdioTransport();
transport.start(); // Must call before messages are emitted
```

### Key details

- **`start()` is required.** The transport does not begin reading until
  `start()` is called. This allows the caller to set up listeners before any
  messages arrive. Calling `start()` more than once throws `StateError`.
- **Input/output injection:** Constructor accepts optional `input` and `output`
  parameters (default to `stdin`/`stdout`), enabling testing without real stdio.
- **Line parsing:** Input bytes are decoded as UTF-8, split by `LineSplitter`,
  empty lines are skipped. Each non-empty line is `jsonDecode`'d and parsed via
  `JsonRpcMessage.fromJson()`.
- **Write flushing:** Each `send()` call encodes the message as a JSON line,
  writes it via `IOSink.writeln()`, and awaits `flush()`.
- **Error handling:** Parse errors on incoming lines are forwarded as stream
  errors (not fatal to the transport). Read errors close the transport.

## `StdioProcessTransport`

**File:** `lib/src/transport/stdio_process_transport.dart`

Spawns an agent subprocess and communicates via NDJSON over its stdin/stdout.
This is the standard transport for clients launching local agents.

### Spawning

```dart
final transport = await StdioProcessTransport.start(
  'path/to/agent',
  ['--flag'],
  workingDirectory: '/project',
  environment: {'KEY': 'value'},
);
```

The factory method calls `Process.start()`, then immediately begins listening
on stdout/stderr. No separate `start()` call is needed (unlike `StdioTransport`).

### Lifecycle management

- **Stderr forwarding:** Subprocess stderr is decoded line-by-line and logged
  via `package:logging` at info level (`[agent stderr] ...`).
- **Process access:** The `process` getter exposes the underlying `Process` for
  advanced lifecycle control. `exitCode` is available as a future.

### Shutdown sequence

On `close()`:

1. Send `SIGTERM` to the process.
2. Wait up to **5 seconds** (`_killTimeout`) for the process to exit.
3. If the process hasn't exited, send `SIGKILL` and await exit.
4. Wait for stdout and stderr streams to finish draining.
5. Cancel stream subscriptions.
6. Close the message `StreamController` (without awaiting listener drain).

This ensures no zombie processes remain, even if the agent ignores `SIGTERM`.

### Platform availability

`StdioProcessTransport` depends on `dart:io` (`Process`, signals) and is only
available on native platforms (not web).

## `LinkedTransport` (testing)

**File:** `test/helpers/linked_transport.dart`

In-memory paired transports for testing. Messages sent by one side are received
by the other, with no serialization overhead.

```dart
final (transportA, transportB) = createLinkedTransports();
// transportA.send(msg) → appears on transportB.messages
// transportB.send(msg) → appears on transportA.messages
```

Uses two `StreamController<JsonRpcMessage>` instances wired in opposite
directions. Implements `AcpTransport` directly. This is the standard transport
used in the test suite for `Connection`, `AgentSideConnection`, and
`ClientSideConnection` tests.

## Ordering Guarantees

All transports guarantee that messages arrive on the `messages` stream in the
order they were passed to `send()`. The protocol layer's single serial write
queue (`Connection._writeQueue`) provides caller-side ordering; the transport
provides wire-side ordering.

## Close Guarantees

After `close()` returns:

- The `messages` stream has emitted a done event (or will shortly).
- Any subsequent `send()` call throws `StateError`.
- For `StdioProcessTransport`, the subprocess has exited.
- For `LinkedTransport`, the paired transport's inbound stream completes.
