# Dart Agent Client Protocol Library Specification

## 0. Reference Corpus and Context

This specification should be read alongside the following canonical references.

### 0.1 ACP and Protocol References
- ACP introduction: <https://agentclientprotocol.com/get-started/introduction>
- ACP protocol index: <https://agentclientprotocol.com/protocol/overview>
- ACP initialization: <https://agentclientprotocol.com/protocol/initialization>
- ACP session setup: <https://agentclientprotocol.com/protocol/session-setup>
- ACP prompt turns: <https://agentclientprotocol.com/protocol/prompt-turn>
- ACP tool calls: <https://agentclientprotocol.com/protocol/tool-calls>
- ACP extensibility: <https://agentclientprotocol.com/protocol/extensibility>
- ACP schema reference: <https://agentclientprotocol.com/protocol/schema>

### 0.2 Serialization and RPC References
- JSON-RPC 2.0 specification: <https://www.jsonrpc.org/specification>
- NDJSON framing guidance (for stdio transport): <https://github.com/ndjson/ndjson-spec>

### 0.3 Dart Language and Package References
- Effective Dart overview: <https://dart.dev/effective-dart>
- Effective Dart style: <https://dart.dev/effective-dart/style>
- Effective Dart documentation: <https://dart.dev/effective-dart/documentation>
- Package layout conventions: <https://dart.dev/tools/pub/package-layout>
- Creating packages: <https://dart.dev/tools/pub/create-packages>
- Publishing packages: <https://dart.dev/tools/pub/publishing>

### 0.4 Analyzer, Test, and Documentation Tooling References
- Static analysis (`dart analyze`): <https://dart.dev/tools/dart-analyze>
- Analysis options file: <https://dart.dev/tools/analysis>
- Lints package: <https://pub.dev/packages/lints>
- Testing with `package:test`: <https://dart.dev/tools/testing>
- Dart API docs (`dart doc`): <https://dart.dev/tools/dart-doc>
- `dartdoc_options.yaml` guide: <https://github.com/dart-lang/dartdoc#configuring-dartdoc>

### 0.5 Dependency and Release Hygiene References
- Semantic Versioning: <https://semver.org>
- Keep a Changelog format: <https://keepachangelog.com/en/1.1.0/>
- Conventional Commits (optional): <https://www.conventionalcommits.org/en/v1.0.0/>

### 0.6 Reference Governance Rules
- Every normative claim in this document should be traceable to at least one reference above or to an ADR under `doc/decisions/`.
- Any ACP-related change PR must include a citation to the relevant ACP docs/schema section in the PR description.
- If ACP docs and schema appear to diverge, schema behavior wins for wire compatibility and the discrepancy is logged in `doc/protocol/spec-discrepancies.md`.

## 1. Purpose and Product Goals

### 1.1 Vision
Build a Dart package that feels idiomatic to Dart developers while implementing the Agent Client Protocol (ACP) with strict spec fidelity, excellent ergonomics, and production-grade reliability.

### 1.2 Non-Goals
- Re-inventing ACP semantics outside the published protocol.
- Creating a framework-specific opinionated runtime that locks users into one architecture.
- Hiding protocol details so deeply that debugging interoperability becomes difficult.

### 1.3 Target ACP Version
- Initial implementation targets **ACP schema v0.10.8** (latest stable as of 2026-02).
- Track upstream releases via `tool/schema_sync` and update `doc/protocol/version-support.md` on each sync.

### 1.4 Product Outcomes
- Full ACP coverage for requests, responses, and notifications.
- Strong compatibility with both local (stdio) and remote transports.
- Clear extension mechanisms for custom methods, capabilities, and metadata.
- Documentation that stays aligned with protocol evolution and code changes.

---

## 2. Core Design Principles

### 2.1 Dart-Native First
- Use `sealed class`, `final class`, pattern matching, and typed union modeling for protocol variants.
- Every `sealed class` hierarchy **must** include an `Unknown` variant (e.g., `UnknownSessionUpdate`, `UnknownContentBlock`, `UnknownAuthMethod`) that captures the raw `Map<String, dynamic>` JSON. This ensures forward compatibility when newer agents/clients send discriminator values unknown to an older library version.
- Use immutable value types for wire models.
- Favor `Stream<T>` for event flows and incremental updates.
- Favor `Future<T>` and cancellation primitives where long-running operations exist.
- Prefer extension methods over utility classes when adding ergonomics around core types.

### 2.2 Protocol-Fidelity First
- Protocol field names and required/optional semantics mirror ACP exactly.
- Preserve unknown fields/methods where possible to maximize forward compatibility.
- Reject malformed protocol messages with explicit, typed JSON-RPC/ACP errors.

### 2.3 Observable and Debuggable
- Structured logs around transport, routing, and errors.
- Opt-in tracing hooks at transport and protocol layers.
- Deterministic request IDs and correlation metadata for troubleshooting.

### 2.4 Safe by Default
- Timeouts, cancellation, and pending-request cleanup are explicit and well-defined.
- No silent swallowing of protocol-level failures.
- Strong validation with actionable errors.

---

## 3. High-Level Architecture

### 3.1 Layering
1. **Transport Layer**
   - Raw framed message IO (NDJSON over stdio, HTTP/WebSocket adapters).
   - No ACP semantics beyond message framing and transport errors.
   - `AcpTransport` abstract interface for pluggable transports.
2. **Protocol Layer**
   - JSON-RPC request/response correlation, notification handling, error envelopes.
   - Typed ACP method dispatch and schema model routing.
   - Agent-side and client-side connection facades.
   - Timeouts, cancellation, and pending-request lifecycle.
   - High-level ergonomics: session helpers, prompt streaming, terminal handles.

This two-layer split mirrors the architecture proven in the official SDKs (TypeScript, Python, Kotlin). The transport boundary is clean and testable; everything above it — from JSON-RPC framing to typed dispatch to ergonomic helpers — lives in the protocol layer, avoiding artificial boundaries between tightly coupled concerns.

### 3.2 Key Runtime Components
- `AcpTransport`: abstract send/receive boundary (analogous to Kotlin's `Transport` interface).
- `Connection`: JSON-RPC state machine with request correlation, timeouts, and write serialization.
- `AgentSideConnection`: wraps `Connection`, provides typed API for agent implementers to receive client requests and send notifications/requests back to the client. Constructor accepts a factory `(AgentSideConnection conn) => AgentHandler` to break circular dependencies.
- `ClientSideConnection`: wraps `Connection`, provides typed API for client implementers to send requests to the agent and receive `session/update` notifications.
- `AgentHandler` and `ClientHandler`: abstract interface classes that implementers fill in with their business logic. Optional methods (e.g., `loadSession`, `writeTextFile`) are capability-gated and throw `MethodNotFound` by default.

### 3.2.1 Connection State Machine
Every `Connection` (and by extension `AgentSideConnection` / `ClientSideConnection`) has explicit lifecycle states:

1. **`idle`** — constructed but not started; no read/write activity.
2. **`opening`** — receive loop started; `initialize` handshake may be in progress.
3. **`open`** — normal operation; requests and notifications flow.
4. **`closing`** — `close()` called; drain write queue up to a configurable `flushTimeout`; reject new sends.
5. **`closed`** — terminal; all streams completed; all pending requests failed with `ConnectionClosedException`.

Transition rules:
- After entering `closed`, `sendRequest()` / `notify()` throw `ConnectionClosedException`.
- Transport read error or remote EOF → transition to `closed`.
- Transport write error → transition to `closed` immediately; fail all pending with `TransportException`.
- Late responses (arriving after a request was timed out or canceled) are discarded and emit `ProtocolWarning.lateResponse(id)`.

### 3.2.2 Connection Lifecycle API
```dart
abstract interface class ConnectionLifecycle {
  ConnectionState get state;
  Future<void> close({Duration flushTimeout = const Duration(seconds: 5)});
  Stream<ConnectionState> get onStateChange;
}
```

`close()` performs:
1. Stop accepting new sends (transition to `closing`).
2. Flush pending writes up to `flushTimeout`.
3. Cancel in-progress handler tasks via cancellation tokens.
4. Close transport.
5. Complete all streams and fail pending requests.

Both sides may call `close()`. Transport EOF from the remote is treated as remote-initiated close. There is no ACP-level close handshake. Connection objects are **single-use** — reconnection requires creating a new `Connection`.

### 3.2.3 Process Spawning
For client-side use, provide a `StdioProcessTransport` that manages an agent subprocess:

```dart
/// Spawns an agent process and returns a transport connected to its stdio.
static Future<StdioProcessTransport> start(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
});
```

- Available only on `dart:io` platforms (via conditional imports).
- Handles stdin/stdout piping, stderr forwarding, and exit code propagation.
- `close()` sends SIGTERM, waits briefly, then SIGKILL if the process hasn't exited.
- Provides `Process get process` for advanced lifecycle control.

This mirrors Python SDK's `spawn_agent_process()` and Rust's `sacp-tokio::AcpAgent`.

### 3.3 Concurrency Model
- **Single writer queue**: messages are written in call order via an internal FIFO drained by a single async send loop. This is necessary even in Dart's single-threaded event loop because `transport.send()` is async and concurrent callers could interleave writes without serialization.
- **Max in-flight incoming requests**: configurable limit on concurrently executing handler invocations (default: unlimited). When the limit is reached, incoming requests queue until a handler completes. This prevents unbounded memory use from slow handlers.
- Max in-flight does **not** apply to outgoing requests awaiting responses (those are bounded by timeout policy).

### 3.3.1 Cancellation Model
Dart has no standard `CancellationToken`. The library defines a lightweight token/source pair:

```dart
abstract interface class AcpCancellationToken {
  bool get isCanceled;
  Future<void> get whenCanceled;
  void throwIfCanceled();
}

final class AcpCancellationSource {
  AcpCancellationToken get token;
  void cancel([Object? reason]);
}
```

Usage:
- `sendRequest(request, {AcpCancellationToken? cancelToken})` — if the token cancels before a response arrives, the pending future completes with `RequestCanceledException` and the request is removed from the pending map.
- Handler methods receive a token: `Future<PromptResponse> prompt(PromptRequest req, {required AcpCancellationToken cancelToken})`.
- When the client sends `session/cancel`, the library cancels the token associated with the active prompt turn in that session.
- Do **not** use Zones for cancellation — they don't compose across package boundaries.

---

## 4. Public API Shape (Dart-Native)

### 4.1 Package Entrypoints
- `package:acp/acp.dart` — re-exports everything for convenience.
- `package:acp/agent.dart` — `AgentSideConnection`, `AgentHandler`, agent-side types.
- `package:acp/client.dart` — `ClientSideConnection`, `ClientHandler`, client-side types.
- `package:acp/schema.dart` — all generated protocol models (requests, responses, content types).
- `package:acp/transport.dart` — `AcpTransport`, `StdioTransport`, transport utilities.

Note: the package name `acp` aligns with the official SDK naming convention (`acp-kotlin`, `acp` for Python). If `acp` is unavailable on pub.dev, fall back to `acp_dart`.

### 4.2 Type Conventions
- Use nouns for models: `InitializeRequest`, `PromptResponse`.
- Use verb phrases for operations: `sendRequest`, `notifySessionUpdate`.
- Use result wrappers only where protocol requires unions/errors.

### 4.3 Connection and Handler Interfaces
- `AgentSideConnection` / `ClientSideConnection`: connection facades (see §3.2).
- `abstract interface class AgentHandler` — implemented by agent authors.
- `abstract interface class ClientHandler` — implemented by client authors.
- Optional operations represented explicitly as capability-gated methods with clear fallback behavior.

### 4.3.1 Authentication Flow
ACP defines a first-class authentication handshake:
1. Agent advertises `authMethods: List<AuthMethod>` in `InitializeResponse`.
2. Client calls `authenticate(methodId)` before creating a session.
3. If the client attempts `session/new` without authenticating, the agent returns error code `-32000` (`auth_required`).

Model types:
- `AuthMethod` — sealed class with variants: `AgentAuth`, `EnvVarAuth`, `TerminalAuth`, `UnknownAuthMethod`.
- `AuthenticateRequest` — contains `methodId` and optional `_meta`.
- `AuthenticateResponse` — contains optional `_meta`.

Reference: <https://agentclientprotocol.com/protocol/initialization>

### 4.3.2 Content Block Types
ACP's `ContentBlock` is a sealed union discriminated by a `type` field:
- `TextContent` (`type: "text"`) — plain text or markdown.
- `ImageContent` (`type: "image"`) — base64-encoded image with MIME type.
- `AudioContent` (`type: "audio"`) — base64-encoded audio with MIME type.
- `ResourceLink` (`type: "resource_link"`) — URI reference.
- `EmbeddedResource` (`type: "embedded_resource"`) — inline resource.
- `UnknownContentBlock` — forward-compatibility fallback preserving raw JSON.

This requires a custom `fromJson` factory with explicit `switch` on the `type` discriminator, since `json_serializable` cannot auto-handle this.

### 4.3.3 SessionUpdate Types
`SessionUpdate` is a sealed union with a **non-standard discriminator**: the `sessionUpdate` key (not `type`). This requires a custom deserializer (as Kotlin's `SessionUpdateSerializer` does).

Variants include:
- `AgentMessageChunk`, `UserMessageChunk`, `ThoughtMessageChunk` — streaming text.
- `ToolCall`, `ToolCallUpdate` — tool invocation lifecycle.
- `PlanUpdate` — agent execution plan changes.
- `AvailableCommandsUpdate` — slash command availability.
- `ModeChangeUpdate` — agent mode transitions.
- `UnknownSessionUpdate` — forward-compatibility fallback preserving raw JSON.

### 4.3.4 Terminal Handle
Wrap terminal IDs in a `TerminalHandle` object providing:
- `kill()`, `waitForExit()`, `release()`, `output()` methods.
- Implements a dispose pattern to ensure terminals are released.

Reference: <https://agentclientprotocol.com/protocol/terminals>

### 4.3.5 Plan Model
ACP agents report execution plans via `PlanUpdate` in `session/update`. The data model:
- `Plan` — contains `entries: List<PlanEntry>` and optional `_meta`.
- `PlanEntry` — contains `id`, `title`, `status` (enum: `pending`, `in_progress`, `completed`, `failed`), optional `children: List<PlanEntry>` for hierarchical plans.
- `PlanUpdate` is a **full snapshot replacement** — the entire plan is sent each time, not a diff. Clients replace their local plan state on each update.

Reference: <https://agentclientprotocol.com/protocol/agent-plan>

### 4.3.6 Slash Commands
Agents advertise available commands via `AvailableCommandsUpdate` in `session/update`:
- `AvailableCommand` — contains `name`, `description`, optional `params: List<AvailableCommandInput>`.
- `AvailableCommandInput` — sealed union for input types (e.g., text hint).
- Updates are **full replacement snapshots** — the complete command list is sent each time.

The library exposes these as `Stream<List<AvailableCommand>>` on `ClientSideConnection`. Commands are **not dispatched by the library** — they are UI affordances. The client application decides how to present them and sends them as prompt text (e.g., `/command args`).

Reference: <https://agentclientprotocol.com/protocol/slash-commands>

### 4.3.7 Session Config Options
The `session/set_config_option` method allows clients to update agent configuration:
- `SessionConfigOption` — contains `id: String`, `label: String`, `type` (bool/string/enum), `value`, and `description`.
- The agent advertises available options in `InitializeResponse` or via `session/update`.
- Unknown option IDs received by the agent should emit `ProtocolWarning.unknownConfigOption(id)` rather than failing.

### 4.4 Events and Streaming
- `Stream<SessionUpdate>` for ongoing updates.
- `Stream<RpcEvent>` for low-level diagnostics.
- `Stream<ProtocolWarning>` for non-fatal compatibility events.

### 4.5 Error Taxonomy
- `AcpException` base.
- `ProtocolValidationException` — malformed message structure (used for inbound parse failures).
- `RpcErrorException` with code/message/data. Factories for all standard and ACP-specific error codes:
  - `-32700` `RpcErrorException.parseError()` — invalid JSON.
  - `-32600` `RpcErrorException.invalidRequest()` — not a valid JSON-RPC request.
  - `-32601` `RpcErrorException.methodNotFound()` — unknown method.
  - `-32602` `RpcErrorException.invalidParams()` — invalid method parameters.
  - `-32603` `RpcErrorException.internalError()` — internal JSON-RPC error.
  - `-32000` `RpcErrorException.authRequired()` — ACP authentication required.
  - Unknown error codes are preserved as-is in `RpcErrorException(code, message, data)`.
- `AuthenticationException` — raised when `authenticate` fails or `session/new` returns `auth_required`.
- `TransportException` — transport-level read/write failures.
- `RequestTimeoutException` — request deadline exceeded.
- `RequestCanceledException` — request canceled via `AcpCancellationToken`.
- `ConnectionClosedException` — operation attempted on a closed connection.
- `CapabilityException` — request requires a capability the peer did not advertise (strict mode only; see §5.5).

### 4.6 Unstable Feature Gating
ACP has unstable/experimental methods (e.g., `session/fork`, `session/list`). The library must gate these to prevent accidental use:
- Mark unstable API members with `@experimental` annotation (from `package:meta`).
- Require an opt-in flag on `AgentSideConnection` / `ClientSideConnection` constructors: `useUnstableProtocol: true`.
- If an unstable method is called without the opt-in flag, throw `UnsupportedError` with a message explaining how to enable it.
- This mirrors Python's `use_unstable_protocol` flag and Kotlin's `@UnstableApi` annotation.

### 4.7 ACP Method Surface (v0.10.8)
For compliance tracking, the full method surface to implement:

**Agent-side methods** (client → agent):
- `initialize` — version negotiation and capability exchange.
- `authenticate` — authentication handshake (if `authMethods` advertised).
- `session/new` — create a new session.
- `session/load` — resume an existing session (requires `loadSession` capability).
- `session/prompt` — send user prompt.
- `session/set_mode` — switch agent operating mode.
- `session/set_config_option` — update session configuration.

**Agent-side notifications** (client → agent):
- `session/cancel` — cancel ongoing operations.

**Client-side methods** (agent → client):
- `session/request_permission` — request user authorization for tool calls.
- `fs/read_text_file` — read file contents (requires `fs.readTextFile` capability).
- `fs/write_text_file` — write file contents (requires `fs.writeTextFile` capability).
- `terminal/create` — create a terminal (requires `terminal` capability).
- `terminal/output` — get terminal output.
- `terminal/release` — release a terminal.
- `terminal/wait_for_exit` — wait for terminal exit.
- `terminal/kill` — kill a terminal command.

**Client-side notifications** (agent → client):
- `session/update` — streaming session updates (message chunks, tool calls, plans, mode changes).

**Unstable methods** (gated by `useUnstableProtocol`, see §4.6):
- `session/list` — list existing sessions (unstable).
- `session/fork` — fork an existing session (unstable).
- Additional unstable methods per ACP schema evolution.

---

## 5. Protocol Compliance and Spec Tracking

### 5.1 Source of Truth
- ACP schema and protocol docs are canonical.
- Local copy of schema checked in under `tool/upstream/schema/`.
- Protocol implementation changes must link to the exact ACP schema/protocol section used.

### 5.1.1 Required Source Traceability Metadata
For each ACP method/notification entry in `doc/spec-compliance.md`, include:
- protocol section URL,
- schema entity URL/name,
- implementation file path,
- test file path,
- last validated date.

### 5.2 Compliance Matrix
Maintain `doc/spec-compliance.md` with:
- Every ACP method and notification.
- Every model type and field.
- Status: `implemented`, `partial`, `planned`, `deprecated`.
- Linked tests and generated docs pages.

Recommended matrix columns:
- `rpc_method`
- `category`
- `schema_type`
- `required_fields_covered`
- `unknown_field_behavior`
- `extensible`
- `implementation_ref`
- `tests_ref`
- `docs_ref`
- `source_ref`
- `last_verified_utc`

### 5.3 Forward Compatibility Rules
- Unknown method names route to extension fallback handlers.
- Unknown union discriminators map to `Unknown*` variants preserving raw JSON.
- Unknown top-level metadata retained in `_meta` and raw payload stores.

### 5.3.1 `_meta` Field Handling
Every ACP schema type that includes `_meta` gets a corresponding field on the generated Dart model:
```dart
final Map<String, Object?>? meta; // JSON key: "_meta"
```
- Provide a shared interface: `abstract interface class HasMeta { Map<String, Object?>? get meta; }`.
- `_meta` is **never dropped** during serialization — it is always re-emitted in `toJson()`.

### 5.3.2 Unknown Field Preservation Policy
When a known type (e.g., `TextContent`) is deserialized from JSON that contains fields not in the schema, the library must decide whether to preserve or drop them. This spec adopts **Option A: preserve unknown fields**:
- Every generated model type includes: `final Map<String, Object?>? extensionData;`
- `extensionData` captures JSON keys not recognized by the schema (excluding `_meta`, which has its own field).
- `toJson()` re-emits `extensionData` entries, enabling lossless round-trip for proxy/relay use cases.
- This is critical for ACP's extensibility story — extensions may add fields to known types that older libraries must pass through without dropping.

### 5.4 Versioning Policy
- Semver for package releases.
- Compatibility table documenting ACP major version support.
- Any protocol behavior change documented under `CHANGELOG.md` with migration notes.

### 5.5 Capability Negotiation and Enforcement
After `initialize`, `Connection` stores:
- `localCapabilities` — what this side supports (declared in `InitializeRequest` or `InitializeResponse`).
- `remoteCapabilities` — what the peer advertised.

The library provides a `CapabilityEnforcement` policy (default: `strict`):
- **`strict`**: if you attempt to **send** a request that requires a capability the peer did not advertise (e.g., calling `fs/read_text_file` when `remoteCapabilities.fs.readTextFile == false`), throw `CapabilityException(method, requiredCapability)` before sending.
- **`permissive`**: allow sending anyway (useful when peers support capabilities but forget to advertise them).

When **receiving** a request for an unsupported capability:
- Respond with `-32601 methodNotFound` (this is the default handler behavior).

Capability types to model:
- `ClientCapabilities` — `fs: FileSystemCapability`, `terminal: bool`.
- `AgentCapabilities` — `loadSession: bool`, `mcpCapabilities: McpCapabilities`, `promptCapabilities: PromptCapabilities`, `supportedContent: List<String>`.
- `McpCapabilities` — `http: bool`, `sse: bool`.
- Missing or unknown capability keys are treated as `false` / not supported. Unknown capability fields are preserved via `extensionData` (§5.3.2).

---

## 6. Extension Points (Well-Defined)

### 6.1 Method Extensions
- Extension methods use the **underscore `_` prefix** per ACP convention (e.g., `_myVendor/customMethod`). This is the universal convention across all official ACP SDKs.
- The router dispatches unknown methods starting with `_` to extension handlers; methods without the `_` prefix that are unrecognized return `METHOD_NOT_FOUND`.
- Provide `extMethod()` and `extNotification()` on `AgentSideConnection` / `ClientSideConnection` for sending custom requests/notifications.
- Provide an `onExtMethod` / `onExtNotification` callback on `AgentHandler` / `ClientHandler` for receiving custom requests/notifications.

Reference: <https://agentclientprotocol.com/protocol/extensibility>

Document each extension with:
  - owner,
  - stability (`experimental`, `beta`, `stable`),
  - schema contract,
  - backwards-compatibility policy,
  - deprecation policy.

### 6.2 Capability Extensions
- Custom capabilities are declared within the standard `capabilities` object in `InitializeRequest` / `InitializeResponse`, using underscore-prefixed keys (e.g., `_myVendor: { customFeature: true }`).
- `_meta` is for out-of-band protocol metadata (tracing, timing) — **not** for capability declarations.
- Require capability schema docs per extension under `doc/extensions/<name>.md`.

### 6.3 Model Extensions
- Unknown fields on known types are preserved via `extensionData: Map<String, Object?>?` on every generated model (see §5.3.2).
- Custom converter registration per method for typed extension payloads.

### 6.3.1 MCP Passthrough Scope
ACP supports MCP server passthrough via `McpCapabilities` (`http`, `sse` flags) negotiated during `initialize`. This library:
- Generates and exposes `McpCapabilities` model faithfully.
- Does **not** implement an MCP client or transport in v1. MCP integration is out of scope for the core ACP library.
- Applications may inspect `remoteCapabilities.mcpCapabilities` to decide whether to connect to an MCP server using a separate MCP client library.

### 6.4 Transport Extensions
- `AcpTransport` interface enables adding custom transport adapters without touching protocol code.
- Required guarantees documented: ordering, backpressure behavior, close semantics.

### 6.5 Tracing Hooks
Provide simple `onSend` / `onReceive` callbacks on `Connection` for observability:
- `void Function(Map<String, dynamic> message)? onSend` — called before each outgoing message is written to the transport.
- `void Function(Map<String, dynamic> message)? onReceive` — called after each incoming message is read from the transport.

These are sufficient for structured logging, metrics, and debugging. A general-purpose interceptor chain is not needed — ACP authentication is handled via the `authenticate` method (not middleware), and no official SDK implements request/response interceptors.

---

## 7. Repository Layout and File Structure

### 7.1 Top-Level Layout
```text
/
  lib/
    acp.dart
    agent.dart
    client.dart
    schema.dart
    transport.dart
    src/
      transport/
      protocol/
      schema/
      codecs/
      internal/
  test/
    unit/
    integration/
    compliance/
    golden/
    fixtures/
  example/
    basic_agent/
    basic_client/
    stdio/
    websocket/
    extensions/
  tool/
    generate/
    docs/
    schema_sync/
    lint/
  doc/
    architecture/
    protocol/
    extensions/
    decisions/
    spec-compliance.md
  analysis_options.yaml
  dart_test.yaml
  pubspec.yaml
  CHANGELOG.md
  CONTRIBUTING.md
```

### 7.2 `lib/src` Naming Guidelines
- Directories by concern, not by protocol method count.
- Files use `snake_case.dart`.
- One public type per file unless tightly coupled micro-types.
- Avoid generic names like `utils.dart`; use purpose-specific names like `request_id_allocator.dart`.

### 7.3 Exports Policy
- Public API only from top-level library files.
- `lib/src/**` is internal, no external stability guarantees.
- Re-export only stable, documented symbols.

---

## 8. Dart Naming and Style Conventions

### 8.1 Follow Effective Dart
- `UpperCamelCase` for types.
- `lowerCamelCase` for members and local variables.
- `snake_case.dart` for files.
- Avoid abbreviations unless protocol-standardized (`rpc`, `json`, `acp`).

Reference: Effective Dart style and design guidance.

### 8.2 Domain Naming Rules
- Protocol model names match ACP concept names exactly.
- Internal adapter names include role suffixes (`*Adapter`, `*Codec`, `*Registry`).
- Use Dart 3 nullable types (`SessionMode?`) idiomatically — do not use `OrNull` suffixes.

### 8.3 Documentation Comments
- Public APIs must use dartdoc comments.
- First sentence short and declarative.
- Include protocol method names and links where relevant.
- Document capability requirements and failure modes.

---

## 9. Documentation System and Anti-Drift Procedures

### 9.1 Documentation Stack
- `dart doc` for API reference generation.
- `dartdoc_options.yaml` for category, link, and include configuration.
- Hand-written docs in `doc/` for architecture, workflows, and migration guides.
- Example-driven docs tested via snippet integration tests.

Recommended documentation tree:
```text
doc/
  architecture/
    runtime-overview.md
    transport-layer.md
    rpc-core.md
  protocol/
    spec-compliance.md
    spec-discrepancies.md
    version-support.md
  extensions/
    extension-index.md
    <extension-name>.md
  operations/
    release-process.md
    docs-maintenance.md
  decisions/
    ADR-*.md
```

### 9.2 Docs-as-Code Rules
- Every public API change requires:
  - updated dartdoc comment,
  - updated example if behavior changed,
  - changelog entry.
- CI fails on missing dartdoc for public symbols beyond allowed exceptions.

### 9.3 Drift Prevention Workflow
1. Sync ACP schema from upstream (`tool/schema_sync`).
2. Re-generate schema-bound Dart models/codecs (`tool/generate`).
3. Run compliance checker against `doc/spec-compliance.md`.
4. Run doc linting and broken-link checks.
5. Rebuild API docs and publish preview artifact in CI.

### 9.3.1 Suggested Maintenance Cadence
- Weekly: schema sync dry-run and link check.
- Per release: full compliance pass + docs regeneration + example smoke tests.
- Monthly: dependency updates and analyzer/lint policy review.

### 9.3.2 Ownership Model
- Protocol owner: validates ACP deltas and compliance matrix updates.
- API owner: validates public API docs and migration notes.
- Tooling owner: validates CI, doc generation, and lint/test gates.

### 9.4 Documentation Quality Gates in CI
- `dart doc --validate-links`.
- custom script to detect undocumented public symbols.
- custom script to verify every method in compliance matrix has at least one test reference.
- markdown linting (`markdownlint`) and spelling checks for docs paths.

Recommended CI doc checks:
- no broken local markdown links,
- no stale ACP source links in compliance matrix,
- no TODO markers in release-facing docs,
- changelog entry required when public API signature changes.

### 9.5 Example and Snippet Validation
- Extract fenced Dart snippets from docs and compile in CI.
- Keep runnable examples under `example/` and run them as smoke tests where feasible.
- Track example compatibility with ACP spec versions.

### 9.6 Release Documentation Checklist
- Protocol version support statement updated.
- Migration notes for breaking and behavior changes.
- Updated extension point docs for any new hooks.
- Regenerated API docs linked from release notes.

---

## 10. Code Generation and Schema Strategy

### 10.1 Generated vs Handwritten Boundaries
- Generated:
  - low-level schema models (request/response types, content blocks, session updates),
  - JSON codecs (including custom discriminator-based `fromJson` factories),
  - method name constants and method↔type pairing tables.
- Handwritten:
  - connection orchestration (`Connection`, `AgentSideConnection`, `ClientSideConnection`),
  - transport adapters (`StdioTransport`, etc.),
  - extension dispatch,
  - ergonomics APIs (`TerminalHandle`, session helpers).

### 10.1.1 Code Generation Tooling
Use a **standalone Dart script** (`tool/generate/generate.dart`) that reads ACP's `schema.json` and emits Dart source files. This is the approach used by the Python SDK (custom script against `schema.json`).

Do **not** use `json_serializable` or `freezed` for generated schema types because:
- ACP uses non-standard discriminators (`sessionUpdate` key instead of `type` for `SessionUpdate`).
- `AuthMethod` has a missing-type-field default case (Kotlin handles this with a custom serializer).
- Generated custom `fromJson`/`toJson` factories give full control over these edge cases.

`build_runner` may be used for handwritten types if needed, but generated schema types must come from the standalone generator.

Input: `tool/upstream/schema/schema.json` (synced from ACP repo).
Output: `lib/src/schema/*.dart` (with `// GENERATED — DO NOT EDIT` headers).

### 10.2 Generation Safety
- Generated files include header notice and deterministic ordering.
- No manual edits in generated files.
- CI verifies generated output is up to date (`git diff --exit-code` after generate step).

Each generated artifact should include:
- generator version,
- upstream schema commit or timestamp,
- generation timestamp,
- checksum of source schema file.

### 10.3 Backward Compatibility Layer
- Keep compatibility shims for renamed fields/methods where possible.
- Mark deprecated APIs with `@Deprecated` and migration path docs.

---

## 11. Testing Strategy

### 11.1 Test Layers
- **Unit tests**: codecs, validators, routing, pending request lifecycle.
- **Integration tests**: full client-agent exchanges over stdio and websocket.
- **Compliance tests**: schema fixtures from ACP docs/examples.
- **Golden tests**: JSON payload shapes and error envelopes.
- **Property/fuzz tests**: malformed/partial payload resilience.

### 11.2 Must-Have Behavioral Tests
- pending request cleanup on disconnect.
- timeout and cancellation propagation (including `AcpCancellationToken` integration).
- extension request and notification routing (`_` prefix dispatch).
- unknown union/type preservation (`Unknown*` variants).
- capability-gated method handling (strict vs permissive enforcement).
- authentication flow negotiation (`initialize` → `authenticate` → `session/new`, and `auth_required` error path).
- `ContentBlock` discriminator resolution (all known `type` values + unknown fallback).
- `SessionUpdate` discriminator resolution (`sessionUpdate` key, not `type` — all known values + unknown fallback).
- connection state machine transitions (idle → opening → open → closing → closed).
- late response handling (response arrives after timeout — must discard and emit warning).
- `_meta` round-trip (preserved through deserialize → serialize).
- `extensionData` round-trip (unknown fields on known types preserved through deserialize → serialize).

### 11.3 Code Generation Tests
- Generator unit tests that parse schema fixtures and emit Dart source.
- Golden output comparison for key generated files (or invariant verification: all methods present, all unions have `Unknown*` variants, discriminators correct).
- Schema drift detection: CI fails if `schema.json` changes without regenerating code (`git diff --exit-code` on generated files).
- Verify method surface in generated code matches §4.7 compliance list.

### 11.4 Transport and Framing Tests
- NDJSON parser: partial frames, empty lines, CRLF vs LF, oversized frames, invalid UTF-8.
- `StdioProcessTransport`: process spawn, stdin/stdout piping, SIGTERM/SIGKILL shutdown, exit code propagation.
- Write queue ordering: concurrent `sendRequest` calls produce messages in call order.
- Backpressure: write buffer limit reached → inbound reading paused (not message drop).

### 11.5 Interop Test Plan
- Cross-test against reference ACP implementations when available.
- Maintain fixture corpus under `test/fixtures/acp_reference/`.

---

## 12. Analyzer, Lints, and Dev Quality Tooling

### 12.1 Analyzer Baseline (`analysis_options.yaml`)
Use `package:lints/recommended.yaml` as baseline and add stricter rules:
- `always_declare_return_types`
- `always_use_package_imports`
- `avoid_dynamic_calls`
- `avoid_print`
- `directives_ordering`
- `prefer_final_fields`
- `prefer_final_locals`
- `public_member_api_docs`
- `unawaited_futures`

Consider adding additional strictness in mature phases:
- `avoid_slow_async_io`
- `cancel_subscriptions`
- `close_sinks`
- `literal_only_boolean_expressions`
- `prefer_relative_imports` (only if project policy prefers it over package imports)

Enable stricter analyzer modes:
- `strict-casts: true`
- `strict-inference: true`
- `strict-raw-types: true`

### 12.2 Formatting and Static Checks
- `dart format --set-exit-if-changed .`
- `dart analyze`
- `dart run custom_lint` (if adopted)
- import sorting and unused public API detection scripts.

### 12.3 Test Configuration
- `dart_test.yaml` with:
  - tags (`unit`, `integration`, `compliance`, `slow`),
  - timeout defaults,
  - platform consistency settings.

### 12.4 Pre-Commit/Pre-Push Hooks
Recommended hooks:
- format check,
- analyzer,
- unit tests,
- docs lint for changed markdown,
- generated code freshness check for modified schema/generation paths.

### 12.5 CI Pipeline Stages
1. **Static**: format, analyze, lints.
2. **Unit**: fast tests.
3. **Integration**: transport and end-to-end tests.
4. **Compliance**: schema and matrix checks.
5. **Docs**: dartdoc + markdown checks.
6. **Package quality**: `dart pub publish --dry-run`.

Suggested CI artifacts:
- generated API docs preview,
- compliance report JSON/markdown,
- test coverage summary,
- extension registry manifest.

### 12.6 Security and Supply Chain
- Dependabot or Renovate for dependencies.
- Lockfile policy for app/example tool chains.
- License scanning and vulnerability checks in CI.

---

## 13. Reliability and Runtime Policies

### 13.1 Request Lifecycle Policy
- Every outgoing request has:
  - request ID,
  - deadline/timeout,
  - cancellation token handle.
- On close/disconnect, all pending requests fail with `ConnectionClosedException`.

### 13.2 Notification Policy
- Unknown notifications route to extension fallback without crashing connection.
- Invalid notification payloads emit structured warnings and optional hard-fail mode.

### 13.3 Backpressure and Throughput
- Single serial write queue per connection (via `StreamController` drained by a single send loop), matching the pattern used by all official ACP SDKs.
- Configurable write buffer size limit (default: 50 MB, matching Python SDK's buffer for multimodal payloads).
- **Never drop messages.** ACP notifications like `session/update` carry sequential deltas (text chunks, tool call updates). Dropping any message corrupts client state. If the write buffer is full, the connection should apply backpressure (pause reading) or fail — never silently discard.

### 13.4 Observability
- Use Dart's standard `package:logging` (`Logger` from `dart:developer` ecosystem). Do not invent a custom logging abstraction.
- Each runtime component (`Connection`, `AgentSideConnection`, `StdioTransport`) creates a named `Logger` for hierarchical filtering.
- Optional request tracing IDs in `_meta` for correlation.
- The `onSend` / `onReceive` tracing hooks (§6.5) provide the low-level message observability layer.

---

## 14. Migration and Evolution Plan

### 14.1 Initial Milestones
1. Foundation architecture and transport/rpc core.
2. Complete schema model coverage and codecs.
3. Typed endpoint surfaces and extension registry.
4. Compliance matrix + CI quality gates.
5. Documentation and examples stabilization.

### 14.2 Breaking Change Policy
- Breaking API changes only in major versions.
- 1-release deprecation window whenever practical.
- Migration guide required for every breaking release.

### 14.3 Governance of Extensions
- Extension namespaces documented and conflict policy defined.
- Optional extension compatibility registry in docs.

---

## 15. Suggested Initial ADRs (Architecture Decision Records)

Create these ADRs under `doc/decisions/`:
- `ADR-001-layered-architecture.md`
- `ADR-002-generated-schema-models.md`
- `ADR-003-extension-registry-contract.md`
- `ADR-004-request-timeout-and-cancellation.md`
- `ADR-005-docs-anti-drift-ci-policy.md`

Each ADR should include:
- context,
- decision,
- alternatives considered,
- consequences,
- links to source references (ACP + Dart docs),
- revision history.

---

## 16. Definition of Done for “Production-Ready”

The package is considered production-ready when all are true:
- 100% ACP method/notification coverage in compliance matrix.
- No known protocol mismatch in latest ACP version.
- All quality gates pass in CI on default branch.
- Public APIs have complete dartdoc coverage.
- Extension points are documented with at least one runnable example each.
- Interop tests pass against at least one external ACP implementation.

Additional release readiness checks:
- all ACP source links in `doc/spec-compliance.md` validated in CI,
- schema sync reports no unreviewed upstream deltas,
- at least one upgrade guide published for the latest minor/major line,
- examples verified against the current public API in CI.

---

## 17. Appendix: Suggested Living Documents

Create and maintain the following files early:
- `doc/protocol/spec-compliance.md`: ACP method/model coverage matrix.
- `doc/protocol/spec-discrepancies.md`: upstream ambiguities and local decisions.
- `doc/protocol/version-support.md`: ACP version compatibility policy.
- `doc/extensions/extension-index.md`: extension inventory and stability levels.
- `doc/operations/release-process.md`: release checklist and sign-off procedure.
- `doc/operations/docs-maintenance.md`: docs pipeline, ownership, and cadence.

Template sections for `doc/extensions/<name>.md`:
- summary,
- owner,
- stability level,
- method names and payload schema,
- capability declaration,
- fallback behavior,
- migration/deprecation policy,
- test coverage references,
- protocol/source references.
