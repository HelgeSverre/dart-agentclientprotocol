# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-rc.3] - 2026-04-20

Pub package layout polish. No code changes; only file moves and publish
metadata.

### Changed

- `SPEC.md` moved to `doc/spec.md` (root reserved for README/CHANGELOG/LICENSE).
- `example/basic_agent.dart` renamed to `example/main.dart` so pub.dev's
  Example tab links to a runnable file directly.
- `.pubignore` now excludes all of `doc/` and `justfile` from the published
  package — internal architecture/decision/protocol/spec docs and the dev
  task runner are not useful to consumers; the homepage links to the
  rendered versions.

### Removed

- 13 stale `.gitkeep` files across `example/`, `test/*/`, `tool/*/`,
  `doc/*/` (those directories now have real content).

### Tooling

- `actions/checkout` bumped from v4 to v5 in CI workflows.

## [0.1.0-rc.2] - 2026-04-20

Pre-release code review pass. Fixes two crashes in normal lifecycle code,
threads typed enums and discriminated unions through the schema generator,
adds resource bounds to streaming transports, and tightens dev tooling.

### Fixed

- **CRITICAL** `Connection._cleanup` was not re-entrant; a transport error
  fired during graceful close drain would re-enter the body and throw
  `StateError` from `_stateController.close()`. Re-entry is now guarded.
- **CRITICAL** `BrowserWebSocketTransport` did not cancel its event listeners
  on close; a message arriving after `_controller.close()` threw
  `StateError: Cannot add event after closing`. Listeners are now cancelled
  and the `onMessage` handler short-circuits when closed.
- `Connection.sendRequest` leaked `cancelToken.whenCanceled` listeners on
  every successful request; long-lived session-scoped cancel tokens
  accumulated `O(n)` closures across prompts. Each request now uses a
  per-request `AcpCancellationSource` that is released on completion.
- `Connection` no longer leaks raw exception `toString()` to the peer in
  `internalError` responses (could disclose paths, query fragments, internal
  state to untrusted clients). The peer now receives a generic message; the
  full error stays in the local log.
- `Connection` previously coerced a non-object response result to `{}`,
  silently producing zero-valued typed responses. Surfaces the protocol
  violation as an error instead.
- `JsonRpcResponse.fromJson` now rejects success responses with `id: null`
  per JSON-RPC 2.0 §5; previously these silently never matched a pending
  request and the caller timed out.
- `Connection._waitForWriteQueueDrain` no longer busy-polls every 10ms;
  blocks on a completer signaled from the drain loop.
- `ClientSideConnection._sessionUpdateController` is now closed on
  transport-initiated disconnect (not only on explicit `close()`); fixes a
  resource leak when the remote drops the connection.
- `StdioProcessTransport.close()` could deadlock waiting for `_stderrDone`
  to complete via `cancel()` (which never fires `onDone`). Capped at 2s.
- `StdioProcessTransport._handleLine` now validates JSON object type
  explicitly, mirroring `StdioTransport`, instead of letting a `TypeError`
  escape on non-object payloads.
- `StdioTransport.send()` now closes the transport on flush failure so
  subsequent sends fail fast instead of silently buffering into a dead sink.
- `ReconnectingTransport` now uses a single-subscription stream for
  `messages`, matching the documented delivery contract; a broadcast
  controller silently dropped messages emitted before/between subscribers.
- `HttpSseTransport` and `StreamableHttpTransport` cap each SSE event's
  `data:` accumulation at 16 MB (configurable via `maxMessageBytes`).
  Previously a server that streamed `data:` lines without ever terminating
  could OOM the process.
- `StreamableHttpTransport.send()` calls are now serialized; concurrent
  sends could race on `_sessionId` and cause the server to fork the session.
- `HttpSseTransport.send()` includes the server's response body in
  `HttpException` for failed requests instead of draining it before checking
  status.

### Changed

- **BREAKING (schema):** Schema generator now emits typed enums and
  discriminated unions instead of raw `String` / `Map<String, dynamic>`
  for fields whose JSON Schema references a known type. Notably:
  - `PromptResponse.stopReason` is now `StopReason?` (was `String`).
    Unknown wire values decode to `null` for forward compatibility.
  - `AgentMessageChunk.content`, `UserMessageChunk.content`, and
    `AgentThoughtChunk.content` are now `ContentBlock` (was `Map`).
  - `SessionNotification.update` is now `SessionUpdate` (was `Map`);
    `SessionUpdate.fromJson` / `UnknownSessionUpdate` forward-compat are
    now invoked on the live notification path.
  - `InitializeResponse.authMethods` is now `List<AuthMethod>` (was
    `List<Map<String, dynamic>>`).
  - All other enum-typed and known-ref fields across the unstable surface
    are similarly upgraded.
  Migration: pass typed values (e.g. `StopReason.endTurn` instead of
  `'end_turn'`) and pattern-match on typed content blocks.
- Examples updated to use typed `TextContent(text: ...)` for
  `AgentMessageChunk.content` (was raw map literals).
- `subprocess_client.dart` resolves `basic_agent.dart` via
  `Platform.script` so the example works regardless of CWD.
- `project_assistant.dart` builds paths via `Uri.directory(...).resolve`
  to handle Windows separators and root CWD correctly.
- `_LinkedTransport` extracted from `streaming_agent.dart` and
  `project_assistant.dart` into a shared `example/in_memory_transport.dart`.

### Added

- `EnumFieldType` in the schema generator; emits typed enum field
  declarations and wires `EnumName.fromString(...)` into `fromJson`.
- Generator emits doc comments before `@experimental` annotations so
  `dart doc` attaches the description to the symbol on pub.dev.
- `validateAbsolutePath` unit test covering POSIX, UNC, and Windows
  drive-letter paths.
- Cooperative-cancellation unit test
  (`Future.any([work, cancelToken.whenCanceled])`).
- Compliance suite now compares full JSON-RPC envelopes through round-trip
  (`expect(roundTripped, json)`) instead of single fields, so dropped or
  added top-level keys would now fail the test.
- HTTP+SSE transport test covering chunked SSE event delivery (real proxies
  routinely split frames across writes).

### Tooling

- `tool/generate/generate.dart` now exits non-zero when configured types are
  missing from the schema; previously it printed a warning and exited 0.
- `tool/generate/src/json_schema_parser.dart` escapes the strict Dart
  reserved-word set when emitting field names; previously only `const`,
  `default`, and `enum` were handled.
- `tool/schema_sync/sync.dart` exits non-zero on HTTP failure and validates
  downloaded JSON before writing.
- `unstable_methods.dart` type list is sorted explicitly so an upstream
  schema reformat can't trigger a false-positive `git diff` in CI.
- CI matrix adds `windows-latest`. `codegen-freshness` job now runs
  `dart analyze` on freshly-regenerated code.
- `.pubignore` excludes `test/` and `dart_test.yaml`.
- New `just dry-run` and `just release-check` recipes.

### Test suite

- 375 tests pass (was 357).

## [0.1.0-rc.1] - 2026-04-19

First release candidate. API is stabilizing but may still change before 0.1.0.

### Added

- Core JSON-RPC 2.0 message types (`JsonRpcRequest`, `JsonRpcResponse`, `JsonRpcNotification`) with batch parsing via `JsonRpcMessage.parseBatch()`.
- `Connection` class with request correlation, timeouts, cancellation, and write serialization.
- `AgentSideConnection` / `ClientSideConnection` typed facades over `Connection`.
- `AgentHandler` / `ClientHandler` abstract interfaces for method dispatch, plus `UnstableAgentHandler` / `UnstableClientHandler` mix-ins for opt-in unstable method handling.
- Full ACP v0.12.0 schema models (initialize, session, content blocks, capabilities, etc.), generated from the checked-in upstream schemas.
- Unstable v0.12 method surface gated by `useUnstableProtocol`: `session/fork`, `session/resume`, `session/close`, `session/set_model`, `providers/*`, `logout`, `nes/*`, `document/*`, elicitation.
- Stable `session/list` gated by `sessionCapabilities.list`.
- Capability enforcement (strict / permissive modes) for outgoing requests.
- Transport implementations:
  - `StdioTransport` — NDJSON over stdin/stdout; auto-starts on first subscription.
  - `StdioProcessTransport` — spawns agent as subprocess.
  - `HttpSseTransport` — HTTP POST + Server-Sent Events.
  - `WebSocketTransport` — WebSocket text frames.
  - `ReconnectingTransport` — auto-reconnect wrapper with exponential backoff.
- Connection keepalive via `$/ping` / `$/pong` notifications.
- Cancellation token system (`AcpCancellationSource` / `AcpCancellationToken`) with linked request+session cancellation for prompt handlers.
- Outgoing absolute-path and prompt content capability validation (errors include the offending value).
- Terminal handle for ergonomic terminal lifecycle management.
- Extension method / notification support for vendor-specific protocols (`_`-prefixed methods).
- Comprehensive exception hierarchy (`AcpException` and subtypes), protocol warnings stream, tracing hooks (`onSend` / `onReceive`).
- `_meta` round-trip fidelity on every generated sealed variant.
- 357 tests (unit, integration, compliance, golden).
- Architecture documentation in `doc/`, GitHub Actions CI for analysis, formatting, and testing.
