# Runtime Architecture Overview

The `acp` package is structured as two layers: a **Transport Layer** for raw
framed I/O and a **Protocol Layer** for JSON-RPC dispatch, typed ACP semantics,
and connection lifecycle management.

## Two-Layer Design

### Transport Layer (`lib/src/transport/`)

Handles NDJSON framing and byte-level I/O. Knows nothing about ACP methods,
request correlation, or session semantics. The boundary is the `AcpTransport`
interface — any implementation that can send/receive `JsonRpcMessage` objects
qualifies.

See [transport-layer.md](transport-layer.md) for details.

### Protocol Layer (`lib/src/protocol/`)

Everything above transport: JSON-RPC request/response correlation, typed ACP
method dispatch, connection lifecycle, timeouts, cancellation, and capability
enforcement. This layer contains:

- `Connection` — core state machine and write serialization
- `AgentSideConnection` / `ClientSideConnection` — typed facades
- `AgentHandler` / `ClientHandler` — abstract handler interfaces
- Schema models (`lib/src/schema/`) — request/response/notification types

## Key Components

| Component | File | Role |
|-----------|------|------|
| `AcpTransport` | `transport/acp_transport.dart` | Abstract send/receive boundary |
| `StdioTransport` | `transport/stdio_transport.dart` | NDJSON over existing stdin/stdout |
| `StdioProcessTransport` | `transport/stdio_process_transport.dart` | Spawns subprocess, NDJSON over its stdio |
| `Connection` | `protocol/connection.dart` | JSON-RPC state machine, request correlation, write queue |
| `AgentSideConnection` | `protocol/agent_side_connection.dart` | Typed dispatch for agent implementers |
| `ClientSideConnection` | `protocol/client_side_connection.dart` | Typed dispatch for client implementers |
| `AgentHandler` | `protocol/agent_handler.dart` | Abstract interface for agent business logic |
| `ClientHandler` | `protocol/client_handler.dart` | Abstract interface for client business logic |
| `AcpMethods` | `protocol/acp_methods.dart` | Wire-format method name constants |
| `JsonRpcMessage` | `protocol/json_rpc_message.dart` | Sealed class: Request, Response, Notification |

## Connection State Machine

Every `Connection` follows a strict lifecycle:

```
idle → opening → open → closing → closed
```

| State | Description |
|-------|-------------|
| `idle` | Constructed but not started. No read/write activity. |
| `opening` | Transport subscription active. Initialize handshake in progress. |
| `open` | Normal operation. Requests and notifications flow freely. |
| `closing` | `close()` called. Write queue draining (up to `flushTimeout`). New sends rejected. |
| `closed` | Terminal. All streams completed. All pending requests failed with `ConnectionClosedException`. |

### Transition triggers

- `start()` → `idle` to `opening`
- `markOpen()` → `opening` to `open` (called after initialize handshake completes)
- `close()` → any non-terminal state to `closing`, then `closed`
- Transport read error or remote EOF → immediate transition to `closed`
- Transport write error → immediate transition to `closed`; all pending requests fail with `TransportException`

State changes are observable via `Connection.onStateChange` (broadcast stream).
Connections are **single-use** — reconnection requires a new instance.

## Concurrency Model

### Single serial write queue

All outgoing messages pass through an internal FIFO queue drained by a single
async loop. This prevents interleaved writes even when multiple `sendRequest()`
or `notify()` calls are concurrent. Each write completes only after the
transport's `send()` future resolves.

### Async handler dispatch

Incoming requests are dispatched to registered handlers asynchronously. Each
handler receives an `AcpCancellationToken` for cooperative cancellation.
Handler errors are caught and returned as JSON-RPC error responses
(`-32603 Internal error`). Unknown methods return `-32601 Method not found`.

### Request correlation and timeouts

Each outgoing request is tracked in a pending map keyed by request ID. A
per-request `Timer` enforces the configurable timeout (default: 60s). On
timeout, the pending future completes with `RequestTimeoutException`. Late
responses (arriving after timeout/cancellation) are discarded and emit a
`ProtocolWarning.lateResponse`.

## Exception Hierarchy

All library exceptions extend `AcpException`:

```
AcpException
├── ProtocolValidationException  — malformed inbound message
├── RpcErrorException            — JSON-RPC error response (with code/data)
├── AuthenticationException      — auth handshake failure
├── TransportException           — transport-level I/O failure
├── RequestTimeoutException      — request deadline exceeded
├── RequestCanceledException     — request canceled via token
├── ConnectionClosedException    — operation on closed connection
└── CapabilityException          — peer lacks required capability (strict mode)
```

Non-fatal issues are surfaced as `ProtocolWarning` (sealed class) via the
`Connection.warnings` stream rather than exceptions.

## Extension Points

### Extension method dispatch

Methods starting with `_` are routed to fallback extension handlers registered
via `setExtensionRequestHandler()` / `setExtensionNotificationHandler()` on
`Connection`. Both `AgentSideConnection` and `ClientSideConnection` expose
`extMethod()` and `extNotification()` for sending extension messages, and
delegate incoming extensions to `AgentHandler.onExtMethod()` /
`ClientHandler.onExtMethod()`.

### Tracing hooks

`Connection.onSend` and `Connection.onReceive` are optional callbacks invoked
with the raw `Map<String, dynamic>` JSON of each outgoing/incoming message.
Exposed on the typed connections via setter properties.

### Capability enforcement

Controlled by `CapabilityEnforcement` enum:

- **`strict`** (default) — outgoing requests are checked against
  peer-advertised capabilities. Throws `CapabilityException` if the capability
  is missing.
- **`permissive`** — sends regardless of peer capabilities.

### Cancellation

`AcpCancellationSource` / `AcpCancellationToken` provide cooperative
cancellation. Tokens are passed to handlers and can be attached to outgoing
requests. Cancellation completes the pending future with
`RequestCanceledException`.
