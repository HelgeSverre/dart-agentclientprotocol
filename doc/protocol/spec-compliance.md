# ACP Spec Compliance Matrix

**Target ACP version:** v0.12.0
**Library version:** 0.1.0
**Last verified:** 2026-04-19

## Agent-Side Methods (Client → Agent)

| RPC Method                  | Status         | Schema Types                                                      | Implementation               | Tests                                                                |
| --------------------------- | -------------- | ----------------------------------------------------------------- | ---------------------------- | -------------------------------------------------------------------- |
| `initialize`                | ✅ implemented | `InitializeRequest`, `InitializeResponse`                         | `agent_side_connection.dart` | `agent_side_connection_test.dart`, `client_agent_exchange_test.dart` |
| `authenticate`              | ✅ implemented | `AuthenticateRequest`, `AuthenticateResponse`                     | `agent_side_connection.dart` | `agent_side_connection_test.dart`                                    |
| `session/new`               | ✅ implemented | `NewSessionRequest`, `NewSessionResponse`                         | `agent_side_connection.dart` | `agent_side_connection_test.dart`, `client_agent_exchange_test.dart` |
| `session/load`              | ✅ implemented | `LoadSessionRequest`, `LoadSessionResponse`                       | `agent_side_connection.dart` | `agent_side_connection_test.dart`                                    |
| `session/prompt`            | ✅ implemented | `PromptRequest`, `PromptResponse`                                 | `agent_side_connection.dart` | `agent_side_connection_test.dart`, `client_agent_exchange_test.dart` |
| `session/set_mode`          | ✅ implemented | `SetSessionModeRequest`, `SetSessionModeResponse`                 | `agent_side_connection.dart` | `agent_side_connection_test.dart`                                    |
| `session/set_config_option` | ✅ implemented | `SetSessionConfigOptionRequest`, `SetSessionConfigOptionResponse` | `agent_side_connection.dart` | `agent_side_connection_test.dart`                                    |
| `session/list`              | ✅ implemented | `ListSessionsRequest`, `ListSessionsResponse`, `SessionInfo`      | `agent_side_connection.dart` | `unstable_methods_test.dart`                                         |

## Agent-Side Notifications (Client → Agent)

| RPC Method       | Status         | Schema Types         | Implementation               | Tests                                                                |
| ---------------- | -------------- | -------------------- | ---------------------------- | -------------------------------------------------------------------- |
| `session/cancel` | ✅ implemented | `CancelNotification` | `agent_side_connection.dart` | `agent_side_connection_test.dart`, `client_agent_exchange_test.dart` |

## Client-Side Methods (Agent → Client)

| RPC Method                   | Status         | Schema Types                                                | Implementation                | Tests                                                                 |
| ---------------------------- | -------------- | ----------------------------------------------------------- | ----------------------------- | --------------------------------------------------------------------- |
| `session/request_permission` | ✅ implemented | `RequestPermissionRequest`, `RequestPermissionResponse`     | `client_side_connection.dart` | `client_side_connection_test.dart`                                    |
| `fs/read_text_file`          | ✅ implemented | `ReadTextFileRequest`, `ReadTextFileResponse`               | `client_side_connection.dart` | `client_side_connection_test.dart`, `client_agent_exchange_test.dart` |
| `fs/write_text_file`         | ✅ implemented | `WriteTextFileRequest`, `WriteTextFileResponse`             | `client_side_connection.dart` | `client_side_connection_test.dart`                                    |
| `terminal/create`            | ✅ implemented | `CreateTerminalRequest`, `CreateTerminalResponse`           | `client_side_connection.dart` | `client_side_connection_test.dart`                                    |
| `terminal/output`            | ✅ implemented | `TerminalOutputRequest`, `TerminalOutputResponse`           | `client_side_connection.dart` | `client_side_connection_test.dart`                                    |
| `terminal/release`           | ✅ implemented | `ReleaseTerminalRequest`, `ReleaseTerminalResponse`         | `client_side_connection.dart` | `client_side_connection_test.dart`                                    |
| `terminal/wait_for_exit`     | ✅ implemented | `WaitForTerminalExitRequest`, `WaitForTerminalExitResponse` | `client_side_connection.dart` | `client_side_connection_test.dart`                                    |
| `terminal/kill`              | ✅ implemented | `KillTerminalCommandRequest`, `KillTerminalCommandResponse` | `client_side_connection.dart` | `client_side_connection_test.dart`                                    |

## Client-Side Notifications (Agent → Client)

| RPC Method       | Status         | Schema Types                                    | Implementation                | Tests                                                                 |
| ---------------- | -------------- | ----------------------------------------------- | ----------------------------- | --------------------------------------------------------------------- |
| `session/update` | ✅ implemented | `SessionNotification`, `SessionUpdate` (sealed) | `client_side_connection.dart` | `client_side_connection_test.dart`, `client_agent_exchange_test.dart` |

## Unstable Methods (Gated by `useUnstableProtocol`)

| RPC Method     | Status         | Schema Types                                | Implementation                                              | Tests                        |
| -------------- | -------------- | ------------------------------------------- | ----------------------------------------------------------- | ---------------------------- |
| `session/fork` | ✅ implemented | `ForkSessionRequest`, `ForkSessionResponse` | `agent_side_connection.dart`, `client_side_connection.dart` | `unstable_methods_test.dart` |

## Session Update Discriminators

| `sessionUpdate` value       | Status | Dart Type                        |
| --------------------------- | ------ | -------------------------------- |
| `agent_message_chunk`       | ✅     | `AgentMessageChunk`              |
| `user_message_chunk`        | ✅     | `UserMessageChunk`               |
| `agent_thought_chunk`       | ✅     | `AgentThoughtChunk`              |
| `tool_call`                 | ✅     | `ToolCallSessionUpdate`          |
| `tool_call_update`          | ✅     | `ToolCallDeltaSessionUpdate`     |
| `plan`                      | ✅     | `PlanUpdate`                     |
| `available_commands_update` | ✅     | `AvailableCommandsSessionUpdate` |
| `current_mode_update`       | ✅     | `CurrentModeSessionUpdate`       |
| `config_option_update`      | ✅     | `ConfigOptionSessionUpdate`      |
| `session_info_update`       | ✅     | `SessionInfoUpdate`              |
| (unknown)                   | ✅     | `UnknownSessionUpdate`           |

## Content Block Discriminators

| `type` value    | Status | Dart Type             |
| --------------- | ------ | --------------------- |
| `text`          | ✅     | `TextContent`         |
| `image`         | ✅     | `ImageContent`        |
| `audio`         | ✅     | `AudioContent`        |
| `resource_link` | ✅     | `ResourceLink`        |
| `resource`      | ✅     | `EmbeddedResource`    |
| (unknown)       | ✅     | `UnknownContentBlock` |

## Auth Method Discriminators

| `type` value       | Status | Dart Type    |
| ------------------ | ------ | ------------ |
| Agent-managed auth | ✅     | `AuthMethod` |

## Capability Types

| Capability             | Status | Dart Type              |
| ---------------------- | ------ | ---------------------- |
| `ClientCapabilities`   | ✅     | `ClientCapabilities`   |
| `FileSystemCapability` | ✅     | `FileSystemCapability` |
| `AgentCapabilities`    | ✅     | `AgentCapabilities`    |
| `PromptCapabilities`   | ✅     | `PromptCapabilities`   |
| `McpCapabilities`      | ✅     | `McpCapabilities`      |
| `SessionCapabilities`  | ✅     | `SessionCapabilities`  |

## Transport Implementations

| Transport                                     | Status | File                                |
| --------------------------------------------- | ------ | ----------------------------------- |
| `AcpTransport` (interface)                    | ✅     | `acp_transport.dart`                |
| `StdioTransport` (NDJSON over existing stdio) | ✅     | `stdio_transport.dart`              |
| `StdioProcessTransport` (subprocess spawning) | ✅     | `stdio_process_transport.dart`      |
| `HttpSseTransport`                            | ✅     | `http_sse_transport.dart`           |
| `StreamableHttpTransport`                     | ✅     | `streamable_http_transport.dart`    |
| `WebSocketTransport`                          | ✅     | `web_socket_transport.dart`         |
| `BrowserWebSocketTransport`                   | ✅     | `browser_web_socket_transport.dart` |
| `ReconnectingTransport`                       | ✅     | `reconnecting_transport.dart`       |

## Protocol Features

| Feature                                    | Status | Notes                                                               |
| ------------------------------------------ | ------ | ------------------------------------------------------------------- |
| JSON-RPC 2.0 request/response correlation  | ✅     | `Connection`                                                        |
| Request timeouts                           | ✅     | Configurable per-request or default                                 |
| Cancellation tokens                        | ✅     | `AcpCancellationToken`, `AcpCancellationSource`, `$/cancel_request` |
| Connection state machine                   | ✅     | idle → opening → open → closing → closed                            |
| Write queue serialization                  | ✅     | Single-writer FIFO in `Connection`                                  |
| Capability enforcement (strict/permissive) | ✅     | `CapabilityEnforcement`                                             |
| Extension method dispatch (`_` prefix)     | ✅     | `onExtMethod` / `onExtNotification`                                 |
| Extension data round-trip                  | ✅     | `extensionData` on all schema models                                |
| `_meta` round-trip                         | ✅     | `HasMeta` interface                                                 |
| Unknown union fallback variants            | ✅     | `Unknown*` for all sealed hierarchies                               |
| Tracing hooks                              | ✅     | `onSend` / `onReceive` on `Connection`                              |
| Protocol warnings                          | ✅     | `ProtocolWarning` sealed class                                      |
| Unstable method gating                     | ✅     | `session/fork` only; `session/list` is stable in v0.12.0            |
| TerminalHandle ergonomics                  | ✅     | `TerminalHandle` with dispose pattern                               |

## External Verification Harness

No official standalone ACP verification harness was found in the upstream ACP
repository or current primary documentation during the v0.12.0 review. The
closest official-adjacent test utility found is the Kotlin SDK's
`acp-ktor-test` module, which is useful as reference material but is not a
language-neutral conformance harness.
