# ACP Version Support

## Target Version

This library targets **ACP schema v0.12.0**, released by the official ACP
repository on 2026-04-17.

The protocol version integer is exchanged during the `initialize` handshake
via `InitializeRequest.protocolVersion` and
`InitializeResponse.protocolVersion`.

## Version Tracking Policy

- Upstream ACP schema releases are tracked via `tool/schema_sync`.
- When a new schema version is synced, the schema source at
  `tool/upstream/schema/schema.json` is updated and code is regenerated
  via `tool/generate/generate.dart`.
- Primary reference snapshots are kept under `doc/references/`.
- This document is updated on each sync to reflect the new target version.
- Breaking protocol changes follow the library's semver policy: breaking
  changes only in major versions, with a deprecation window when practical.

## Spec Compliance

See [spec-compliance.md](spec-compliance.md) for the full compliance matrix
covering every ACP method, notification, and schema type.

## Schema Coverage Summary

### Methods (client → agent)

| Method                      | Status        |
| --------------------------- | ------------- |
| `initialize`                | ✅            |
| `authenticate`              | ✅            |
| `session/new`               | ✅            |
| `session/load`              | ✅            |
| `session/prompt`            | ✅            |
| `session/set_mode`          | ✅            |
| `session/set_config_option` | ✅            |
| `session/list`              | ✅            |
| `session/fork`              | ✅ (unstable) |

### Methods (agent → client)

| Method                       | Status |
| ---------------------------- | ------ |
| `fs/read_text_file`          | ✅     |
| `fs/write_text_file`         | ✅     |
| `terminal/create`            | ✅     |
| `terminal/output`            | ✅     |
| `terminal/release`           | ✅     |
| `terminal/kill`              | ✅     |
| `terminal/wait_for_exit`     | ✅     |
| `session/request_permission` | ✅     |

### Notifications

| Notification        | Direction      | Status |
| ------------------- | -------------- | ------ |
| `session/update`    | agent → client | ✅     |
| `session/cancel`    | client → agent | ✅     |
| `$/cancel_request`  | both           | ✅     |
| `$/ping` / `$/pong` | both           | ✅     |

### SessionUpdate discriminators

Discriminated by the `sessionUpdate` JSON key (not `type`):

- `agent_message_chunk` — `AgentMessageChunk`
- `user_message_chunk` — `UserMessageChunk`
- `agent_thought_chunk` — `AgentThoughtChunk`
- `tool_call` — `ToolCallSessionUpdate`
- `tool_call_update` — `ToolCallDeltaSessionUpdate`
- `plan` — `PlanUpdate`
- `available_commands_update` — `AvailableCommandsSessionUpdate`
- `current_mode_update` — `CurrentModeSessionUpdate`
- `config_option_update` — `ConfigOptionSessionUpdate`
- Unknown values → `UnknownSessionUpdate`

### ContentBlock types

Discriminated by `type`:

- `text` — `TextContent`
- `image` — `ImageContent`
- `audio` — `AudioContent`
- `resource_link` — `ResourceLink`
- `resource` — `EmbeddedResource`
- Unknown values → `UnknownContentBlock`

### Auth methods

`AuthMethod` is a plain struct with `id`, `name`, and optional `description`.
Authentication type is determined by `id` convention. Unknown fields are
preserved via `extensionData`.

## Forward Compatibility Approach

The library is designed to handle schema evolution gracefully:

- **`extensionData`** — Every schema model collects unknown JSON fields into an
  `extensionData` map. These are preserved through `fromJson()` → `toJson()`
  round-trips, ensuring fields added in future schema versions are not lost.

- **`_meta`** — All schema models implement `HasMeta`, exposing an optional
  `Map<String, Object?>? meta` field mapped from the `_meta` JSON key. This is
  the ACP-standard metadata extension point, preserved through round-trips.

- **`Unknown*` fallback variants** — Every sealed union hierarchy includes an
  `Unknown` variant (`UnknownSessionUpdate`, `UnknownContentBlock`) that
  captures the full raw JSON when an unrecognized discriminator value is
  encountered. This prevents deserialization failures when a newer peer sends
  types unknown to this library version.

- **Extension method routing** — Methods prefixed with `_` are routed to
  extension handlers rather than rejected as unknown. This allows vendor or
  experimental extensions without library changes.

- **Permissive capability mode** — `CapabilityEnforcement.permissive` allows
  sending requests regardless of peer-advertised capabilities, enabling
  communication with peers that support features not yet reflected in their
  capability advertisements.
