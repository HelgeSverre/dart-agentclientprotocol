# ACP Examples

A guided tour of the Agent Client Protocol through four progressively richer
examples. If you've never used ACP before, read the sections in order and run
each example as you go.

## What you'll learn

- How an ACP **agent** and **client** talk to each other at a wire level.
- How editors like [Zed](https://zed.dev/docs/ai/external-agents) and
  [JetBrains IDEs](https://www.jetbrains.com/acp/) spawn local agents as
  subprocesses over stdio.
- How to stream progressive updates — thoughts, plans, message tokens — from
  an agent to a client.
- How to wire up permission prompts, filesystem access, and terminal commands
  so an agent can do useful work without owning the user's machine.

## Prerequisites

- Dart SDK `^3.7.0` (`dart --version`).
- Comfort with `async`/`await` and `Stream`. You don't need to know JSON-RPC —
  the library hides it.

## What is ACP?

The Agent Client Protocol is an open standard for letting any AI coding agent
work in any editor or tool. Think **LSP but for AI agents**: the same way
`rust-analyzer` can power autocomplete in VS Code, Zed, Neovim, or Helix
because they all speak the Language Server Protocol, an ACP-compatible agent
can power agentic workflows in any editor that speaks ACP.

Under the hood, ACP is [JSON-RPC 2.0](https://www.jsonrpc.org/specification)
— tiny framed messages exchanged over stdio, WebSocket, or HTTP/SSE. This
Dart library wraps the wire format so you write typed Dart code and let the
library handle framing, request/response correlation, cancellation, and
capability enforcement.

## Who uses ACP today?

ACP is the lingua franca of a growing ecosystem:

- **Zed** ships integrations for [Gemini CLI](https://google-gemini.github.io/gemini-cli/),
  [Claude Agent](https://www.anthropic.com/claude-code), OpenAI Codex, and
  GitHub Copilot. Zed spawns each one as a subprocess and talks ACP.
  — https://zed.dev/docs/ai/external-agents
- **JetBrains** AI Assistant supports ACP in every IntelliJ-family IDE
  (IntelliJ IDEA, PyCharm, WebStorm, GoLand, RubyMine, Rider, …) from
  version 2025.3 on. Users install agents one-click from the [ACP Agent
  Registry](https://blog.jetbrains.com/ai/2026/01/acp-agent-registry/),
  launched January 2026. — https://www.jetbrains.com/help/ai-assistant/acp.html
- **Agents available today** through those hosts: Gemini CLI, Claude Agent,
  OpenAI Codex, Cursor (on JetBrains from March 2026), Kimi CLI, Block's
  goose, Augment Code, Kiro CLI, OpenCode, and any
  [Koog](https://blog.jetbrains.com/ai/2026/02/koog-x-acp-connect-an-agent-to-your-ide-and-more/)-built
  agent.

When you build an agent with this library, it slots into all of those hosts
automatically.

## Reading order

| # | File | Teaches |
|---|---|---|
| 1 | [`main.dart`](./main.dart) | The three methods every agent must implement. |
| 2 | [`subprocess_client.dart`](./subprocess_client.dart) | How a client spawns an agent process and drives a full session. Mirrors what Zed/JetBrains do. |
| 3 | [`streaming_agent.dart`](./streaming_agent.dart) | How agents stream progressive output — thoughts, plans, message chunks. |
| 4 | [`project_assistant.dart`](./project_assistant.dart) | Permissions, filesystem, terminal. The full coding-assistant shape. |

## The examples

### 1. `main.dart` — the minimum viable agent

```bash
dart run example/main.dart
```

Running it standalone will look like it hangs — that's correct. It's waiting
for a client to send it JSON-RPC messages on stdin. That's exactly how Zed
launches an agent: the editor spawns the process, then writes an `initialize`
request to its stdin.

**What it implements:**
- `initialize` — handshake.
- `session/new` — create a session.
- `session/prompt` — reply to a prompt by echoing it back as an
  `AgentMessageChunk`.

**Spec reference:** [Initialization](https://agentclientprotocol.com/protocol/initialization),
[Session setup](https://agentclientprotocol.com/protocol/session-setup),
[Prompt turn](https://agentclientprotocol.com/protocol/prompt-turn).

### 2. `subprocess_client.dart` — how editors spawn agents

```bash
dart run example/subprocess_client.dart
```

This example launches `main.dart` as a child process via
`StdioProcessTransport`, drives the canonical `initialize → new session →
prompt → close` flow, and prints each step. **This is the exact pattern Zed
uses to run Gemini CLI or Claude Agent**, and the pattern JetBrains IDEs use
when they load an agent from the ACP Registry.

**What it demonstrates:**
- `StdioProcessTransport.start` — spawning a process with stdin/stdout piped.
- `ClientSideConnection` — the typed client facade.
- `ImplementationInfo` — advertising who you are during the handshake.

The subprocess lifecycle is handled for you: on `client.close()` the
transport sends `SIGTERM`, waits up to 5 seconds, then `SIGKILL`s if the
child hasn't exited.

### 3. `streaming_agent.dart` — how real LLM agents respond

```bash
dart run example/streaming_agent.dart
```

Real agents don't return a single text blob. They stream. This example
shows a complete prompt turn producing, in order:

1. An `AgentThoughtChunk` (internal reasoning — hidden by most editors).
2. A `PlanUpdate` with `in_progress` entries (a live TODO list).
3. Several `AgentMessageChunk`s (the user-visible answer, token by token).
4. A final `PlanUpdate` with all entries `completed`.
5. A `PromptResponse` with `stopReason: StopReason.endTurn`.

The client prints each update with elapsed time so you can see the ordering.

**Spec reference:** [Session updates](https://agentclientprotocol.com/protocol/overview),
[Content blocks](https://agentclientprotocol.com/protocol/content).

### 4. `project_assistant.dart` — the full coding-assistant shape

```bash
dart run example/project_assistant.dart
```

Everything a real agent-powered editor does: session listing, per-session
config options and modes, streaming plan updates, user **permission
prompts**, filesystem reads, and terminal commands. Both peers live
in-process over linked in-memory transports, so the file stands alone — the
handler code, though, would work unchanged over stdio or WebSocket.

**What it demonstrates:**
- `ClientCapabilities` — client advertises `fs` and `terminal` support.
- `AgentCapabilities` — agent advertises `promptCapabilities` and session listing.
- `session/list` + `session/new` — the "load previous / start new" pattern.
- `PlanUpdate` + `AvailableCommandsSessionUpdate` — live UI state.
- `session/request_permission` — the agent asks the user before touching disk.
- `fs/read_text_file` + `terminal/create` — the agent calls back into the client.
- `TerminalHandle` — an ergonomic wrapper over the raw `terminal/*` RPCs.

**Spec reference:** [File system](https://agentclientprotocol.com/protocol/file-system),
[Terminals](https://agentclientprotocol.com/protocol/terminals),
[Tool calls](https://agentclientprotocol.com/protocol/tool-calls).

## Glossary

Grounded in the Dart class names you'll see in the code. One sentence each.

### Core concepts

- **Agent** — a process that accepts prompts and does work in response (runs
  an LLM, edits files, etc.).
- **Client** — the host that talks to the agent: typically an editor, but
  could be a CLI tool or web app.
- **Session** — one logical conversation, identified by a `sessionId`.
  Multiple turns of prompts can happen within a session.
- **Turn** — a single request/response cycle within a session: the client
  sends a prompt, the agent streams updates and then responds.
- **Connection** — a bidirectional JSON-RPC link. Both sides can send
  requests. Implemented as `AgentSideConnection` / `ClientSideConnection`.
- **Transport** — the byte pipe underneath the connection: stdio, WebSocket,
  HTTP/SSE, or an in-memory test double.

### Message kinds

- **Request** (`JsonRpcRequest`) — expects a response; has an `id`.
- **Response** (`JsonRpcResponse`) — the reply, matching `id`.
- **Notification** (`JsonRpcNotification`) — fire-and-forget; no reply.
  Session updates flow as notifications.

### Methods you'll meet

Client → agent:

- `initialize` — handshake.
- `authenticate` — optional; for agents that need credentials.
- `session/new` — create a session.
- `session/load` — reopen an existing session (capability-gated).
- `session/list` — list known sessions (capability-gated).
- `session/prompt` — send a prompt.
- `session/cancel` — abort the current turn (notification).
- `session/set_mode` — switch between agent modes (e.g. review / edit).
- `session/set_config_option` — tweak session config.

Agent → client:

- `fs/read_text_file` / `fs/write_text_file` — read or write a file.
- `terminal/create`, `terminal/output`, `terminal/wait_for_exit`,
  `terminal/kill`, `terminal/release` — spawn and control a shell command.
- `session/request_permission` — ask the user before doing something risky.
- `session/update` — stream a progress update (notification).

### Session update variants (streamed agent → client)

All extend `SessionUpdate`:

- `AgentMessageChunk` — user-visible output, usually streamed token-by-token.
- `AgentThoughtChunk` — internal reasoning; editors can show or hide it.
- `UserMessageChunk` — echo of user input (rare, used by some transports).
- `PlanUpdate` — the full current TODO list; the client replaces its plan
  on every update.
- `AvailableCommandsSessionUpdate` — commands the user can invoke in this
  session.
- `ToolCallSessionUpdate` / `ToolCallDeltaSessionUpdate` — start and progress
  of a tool call the agent is performing.
- `CurrentModeSessionUpdate` — agent switched modes (e.g. review → edit).
- `ConfigOptionSessionUpdate` — session config changed.
- `SessionInfoUpdate` — session title or timestamp changed.
- `UnknownSessionUpdate` — the generated fallback for forward compatibility
  with newer spec versions.

### Content blocks (what a prompt or message contains)

All extend `ContentBlock`:

- `TextContent` — plain text or Markdown. Every agent must accept this.
- `ImageContent` — base64-encoded image (capability-gated).
- `AudioContent` — base64-encoded audio (capability-gated).
- `ResourceLink` — a reference to a file or URL, not the bytes themselves.
- `EmbeddedResource` — the bytes themselves inlined into the message.
- `UnknownContentBlock` — forward-compat fallback.

### Capabilities

- `ClientCapabilities` — what the client can do for the agent.
  - `FileSystemCapability` — `readTextFile`, `writeTextFile`.
  - `terminal` — can create, read, kill terminal processes.
- `AgentCapabilities` — what the agent supports.
  - `PromptCapabilities` — `image`, `audio`, `embeddedContext`.
  - `SessionCapabilities` — optional session methods like `list`.
  - `loadSession` — `session/load` supported.
- `CapabilityEnforcement` — `strict` (default) throws if you try to call a
  method the peer didn't advertise. `permissive` sends anyway, useful for
  testing.

### Transports

- `StdioTransport` — NDJSON over `stdin`/`stdout`. Used by an agent subprocess.
- `StdioProcessTransport` — spawns an agent subprocess and pipes it; used by
  a client (this is what Zed/JetBrains use).
- `WebSocketTransport` — JSON over WebSocket frames. For remote agents.
- `HttpSseTransport` — HTTP POST for upstream, Server-Sent Events for
  downstream. For fire-and-forget remote setups.
- `BrowserWebSocketTransport` — same as WebSocketTransport but works in
  `dart:html` / `dart:js_interop` environments.
- `ReconnectingTransport` — wraps another transport with exponential-backoff
  auto-reconnect.

### Miscellaneous

- `AcpCancellationToken` / `AcpCancellationSource` — cooperative cancellation
  passed to every handler method.
- `TerminalHandle` — agent-side convenience wrapper over the `terminal/*`
  RPCs.
- `ImplementationInfo` — `{name, title, version}` advertised during
  `initialize`.
- `stopReason` — string on `PromptResponse`: `end_turn`, `max_tokens`,
  `tool_use_requested`, `cancelled`.
- `cwd` — absolute working directory. Required on `session/new` and
  `session/load`. The library validates absoluteness before sending.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `CapabilityException` when calling `sendReadTextFile` | Peer didn't advertise that capability, and `CapabilityEnforcement.strict` is on. Pass `permissive` for testing, or have the client set `ClientCapabilities(fs: FileSystemCapability(readTextFile: true))`. |
| Agent seems idle after your client sends `session/prompt` | Your agent's `prompt` handler must call `notifySessionUpdate` **and** return a `PromptResponse`. Returning without updates is legal but boring. |
| Subprocess agent never exits when you close the client | `StdioProcessTransport` sends `SIGTERM` then `SIGKILL` after 5s. If your own agent has cleanup that blocks for longer than that, handle the shutdown explicitly. |
| "Method not found: foo/bar" errors | The peer doesn't implement that method. If it's an `@experimental` / unstable method, both sides need `useUnstableProtocol: true` and the agent needs `with UnstableAgentHandler`. |
| `RequestTimeoutException` on `sendPrompt` | Default timeout is 60s. Pass `defaultTimeout` on connection construction, or `timeout` per-call on `sendRequest`. |

## Further reading

- **Upstream ACP spec** — https://agentclientprotocol.com/
- **This library's architecture docs** — [`doc/architecture/`](../doc/architecture/),
  [`doc/protocol/`](../doc/protocol/)
- **Zed external agents** — https://zed.dev/docs/ai/external-agents
- **JetBrains ACP** — https://www.jetbrains.com/help/ai-assistant/acp.html
- **ACP Agent Registry** — https://blog.jetbrains.com/ai/2026/01/acp-agent-registry/
- **JSON-RPC 2.0 spec** — https://www.jsonrpc.org/specification (you rarely
  need this; the library hides JSON-RPC from you).
