# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- ACP v0.12.0 compliance: new unstable methods (`providers/*`, `logout`, `session/resume`, `session/close`, `session/set_model`, `nes/*`, `document/*`), elicitation, and additional schema types.
- `_meta` is now universally round-tripped on every sealed variant (including variants without explicitly-declared meta in the schema). This widens the public API of generated sealed variants — all now expose a `meta` field and accept it in their constructor.
- `StdioTransport` auto-starts on first subscription to `messages`. Calling `start()` explicitly is still supported; double-start continues to throw `StateError`.

### Changed

- `AgentHandler`/`ClientHandler`: `@experimental` methods moved to new `UnstableAgentHandler`/`UnstableClientHandler` mixins. Mix them in (`with UnstableAgentHandler`) to opt into unstable request/notification handling. Stable handler surface is now significantly smaller.
- `ProtocolValidationException` from `validateAbsolutePath` now includes the offending path value in the error message.
- Cross-platform absolute-path validation accepts POSIX, UNC, and Windows drive-letter forms regardless of host OS; documented via code comment.
- `StdioTransport` now logs and skips JSON-RPC batch arrays instead of crashing with a `TypeError`. Batches remain unsupported over NDJSON.

### Fixed

- Unstable notification handlers (`document/did*`, `nes/accept|reject`, `elicitation/complete`) now silently ignore incoming messages when unstable protocol is disabled, per JSON-RPC 2.0 semantics for unknown notifications. Previously threw `RpcErrorException.methodNotFound`, producing a severe log with no spec basis.

## [0.1.0] - 2026-02-28

### Added

- Core JSON-RPC 2.0 message types (`JsonRpcRequest`, `JsonRpcResponse`, `JsonRpcNotification`)
- Batch parsing via `JsonRpcMessage.parseBatch()`
- `Connection` class with request correlation, timeouts, cancellation, and write serialization
- `AgentSideConnection` for agent implementers with typed dispatch
- `ClientSideConnection` for client implementers with typed dispatch
- `AgentHandler` and `ClientHandler` abstract interfaces
- Capability enforcement (strict/permissive modes)
- Five transport implementations:
  - `StdioTransport` — NDJSON over stdin/stdout
  - `StdioProcessTransport` — spawns agent as subprocess
  - `HttpSseTransport` — HTTP POST + Server-Sent Events
  - `WebSocketTransport` — WebSocket text frames
  - `ReconnectingTransport` — auto-reconnect wrapper with exponential backoff
- Connection keepalive via `$/ping`/`$/pong` notifications
- Full ACP schema models (initialize, session, content blocks, capabilities, etc.)
- Extension method/notification support for vendor-specific protocols
- Cancellation token system (`AcpCancellationSource`/`AcpCancellationToken`)
- Terminal handle for ergonomic terminal lifecycle management
- Comprehensive exception hierarchy (`AcpException` and subtypes)
- Protocol warnings stream for non-fatal issues
- Tracing hooks (`onSend`/`onReceive`) for observability
- Unstable method support (`session/list`, `session/fork`) behind opt-in flag
- 325+ tests (unit, integration, compliance, golden)
- Architecture documentation in `doc/`
- GitHub Actions CI for analysis, formatting, and testing
