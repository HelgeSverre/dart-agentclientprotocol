# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
