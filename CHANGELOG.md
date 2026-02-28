# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-28

### Added

#### Transport Layer
- `AcpTransport` interface for pluggable transports.
- `StdioTransport` for NDJSON-over-stdio communication.
- `StdioProcessTransport` for subprocess spawning with SIGTERM/SIGKILL shutdown.

#### JSON-RPC 2.0
- `JsonRpcMessage` sealed hierarchy (Request, Response, Notification).
- Request/response correlation and error objects.

#### Connection Management
- Connection state machine: idle → opening → open → closing → closed.
- `ConnectionState` enum and `onStateChange` stream.
- Write queue serialization with single-writer FIFO preventing interleaved async writes.
- Request lifecycle with configurable timeouts.
- `AcpCancellationToken`/`AcpCancellationSource` for request cancellation.
- Pending request cleanup on disconnect.
- Tracing hooks: `onSend`/`onReceive` callbacks for observability.

#### Agent-Side Connection
- `AgentSideConnection` with typed dispatch to `AgentHandler`.
- Capability enforcement (strict/permissive).

#### Client-Side Connection
- `ClientSideConnection` with typed send methods.
- `Stream<SessionUpdateEvent>` for session updates.

#### ACP v0.10.8 Methods
- `initialize`, `authenticate`.
- `session/new`, `session/load`, `session/prompt`, `session/cancel`.
- `session/set_mode`, `session/set_config_option`.
- `fs/read_text_file`, `fs/write_text_file`.
- `terminal/create`, `terminal/output`, `terminal/release`, `terminal/kill`, `terminal/wait_for_exit`.
- `session/request_permission`, `session/update`.

#### Schema Models
- Full typed models for all requests, responses, and notifications.
- `fromJson`/`toJson` serialization on all models.
- `extensionData` for unknown field preservation.
- `_meta` round-trip via `HasMeta` interface.

#### Content Blocks
- `ContentBlock` sealed class: `TextContent`, `ImageContent`, `AudioContent`, `ResourceLink`, `EmbeddedResource`, `UnknownContentBlock`.

#### Session Updates
- `SessionUpdate` sealed class with non-standard `sessionUpdate` discriminator.
- Update types: `AgentMessageChunk`, `UserMessageChunk`, `AgentThoughtChunk`, `ToolCallSessionUpdate`, `ToolCallDeltaSessionUpdate`, `PlanUpdate`, `AvailableCommandsSessionUpdate`, `CurrentModeSessionUpdate`, `ConfigOptionSessionUpdate`, `UnknownSessionUpdate`.

#### Authentication
- `AuthMethod` sealed class: `AgentAuth`, `EnvVarAuth`, `TerminalAuth`, `UnknownAuthMethod`.

#### Capabilities
- `ClientCapabilities`, `AgentCapabilities`.
- `FileSystemCapability`, `PromptCapabilities`, `McpCapabilities`, `SessionCapabilities`.

#### Extension & Unstable Protocol Support
- `_`-prefixed method routing to `onExtMethod`/`onExtNotification` handlers.
- `extMethod()`/`extNotification()` for sending extension messages.
- `session/list` and `session/fork` with `@experimental` annotations.
- `useUnstableProtocol` flag enforcement.

#### Protocol Warnings
- `ProtocolWarning` sealed class with `LateResponseWarning` and `UnknownConfigOptionWarning`.

#### Terminal
- `TerminalHandle` ergonomic wrapper with `output()`, `kill()`, `waitForExit()`, `release()`, `dispose()` pattern.

#### Exception Hierarchy
- `AcpException` base class.
- `ProtocolValidationException`, `RpcErrorException`, `AuthenticationException`.
- `TransportException`, `RequestTimeoutException`, `RequestCanceledException`.
- `ConnectionClosedException`, `CapabilityException`.
