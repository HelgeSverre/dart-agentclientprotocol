# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
