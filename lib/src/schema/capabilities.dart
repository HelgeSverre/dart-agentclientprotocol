// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/has_meta.dart';

/// File system capabilities that a client may support.
///
/// See protocol docs: [FileSystem](https://agentclientprotocol.com/protocol/initialization#filesystem)
final class FileSystemCapability implements HasMeta {
  /// Whether the Client supports `fs/read_text_file` requests.
  final bool readTextFile;

  /// Whether the Client supports `fs/write_text_file` requests.
  final bool writeTextFile;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [FileSystemCapability].
  const FileSystemCapability({
    this.readTextFile = false,
    this.writeTextFile = false,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory FileSystemCapability.fromJson(Map<String, dynamic> json) {
    final known = {'readTextFile', 'writeTextFile', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return FileSystemCapability(
      readTextFile: json['readTextFile'] as bool? ?? false,
      writeTextFile: json['writeTextFile'] as bool? ?? false,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'readTextFile': readTextFile,
    'writeTextFile': writeTextFile,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Capabilities supported by the client.
///
/// Advertised during initialization to inform the agent about
/// available features and methods.
///
/// See protocol docs: [Client Capabilities](https://agentclientprotocol.com/protocol/initialization#client-capabilities)
final class ClientCapabilities implements HasMeta {
  /// File system capabilities supported by the client.
  /// Determines which file operations the agent can request.
  final FileSystemCapability fs;

  /// Whether the Client support all `terminal/*` methods.
  final bool terminal;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ClientCapabilities].
  const ClientCapabilities({
    this.fs = const FileSystemCapability(),
    this.terminal = false,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ClientCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'fs', 'terminal', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ClientCapabilities(
      fs:
          json['fs'] is Map<String, dynamic>
              ? FileSystemCapability.fromJson(
                json['fs'] as Map<String, dynamic>,
              )
              : const FileSystemCapability(),
      terminal: json['terminal'] as bool? ?? false,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'fs': fs.toJson(),
    'terminal': terminal,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Prompt capabilities supported by the agent in `session/prompt` requests.
///
/// Baseline agent functionality requires support for [`ContentBlock::Text`]
/// and [`ContentBlock::ResourceLink`] in prompt requests.
///
/// Other variants must be explicitly opted in to.
/// Capabilities for different types of content in prompt requests.
///
/// Indicates which content types beyond the baseline (text and resource links)
/// the agent can process.
///
/// See protocol docs: [Prompt Capabilities](https://agentclientprotocol.com/protocol/initialization#prompt-capabilities)
final class PromptCapabilities implements HasMeta {
  /// Agent supports [`ContentBlock::Audio`].
  final bool audio;

  /// Agent supports embedded context in `session/prompt` requests.
  ///
  /// When enabled, the Client is allowed to include [`ContentBlock::Resource`]
  /// in prompt requests for pieces of context that are referenced in the message.
  final bool embeddedContext;

  /// Agent supports [`ContentBlock::Image`].
  final bool image;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [PromptCapabilities].
  const PromptCapabilities({
    this.audio = false,
    this.embeddedContext = false,
    this.image = false,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory PromptCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'audio', 'embeddedContext', 'image', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return PromptCapabilities(
      audio: json['audio'] as bool? ?? false,
      embeddedContext: json['embeddedContext'] as bool? ?? false,
      image: json['image'] as bool? ?? false,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'audio': audio,
    'embeddedContext': embeddedContext,
    'image': image,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// MCP capabilities supported by the agent
final class McpCapabilities implements HasMeta {
  /// Agent supports [`McpServer::Http`].
  final bool http;

  /// Agent supports [`McpServer::Sse`].
  final bool sse;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [McpCapabilities].
  const McpCapabilities({
    this.http = false,
    this.sse = false,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory McpCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'http', 'sse', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return McpCapabilities(
      http: json['http'] as bool? ?? false,
      sse: json['sse'] as bool? ?? false,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'http': http,
    'sse': sse,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Session capabilities supported by the agent.
///
/// As a baseline, all Agents **MUST** support `session/new`, `session/prompt`, `session/cancel`, and `session/update`.
///
/// Optionally, they **MAY** support other session methods and notifications by specifying additional capabilities.
///
/// Note: `session/load` is still handled by the top-level `load_session` capability. This will be unified in future versions of the protocol.
///
/// See protocol docs: [Session Capabilities](https://agentclientprotocol.com/protocol/initialization#session-capabilities)
final class SessionCapabilities implements HasMeta {
  /// Whether the agent supports `session/list`.
  final Map<String, dynamic>? list;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionCapabilities].
  const SessionCapabilities({this.list, this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory SessionCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'list', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionCapabilities(
      list: json['list'] as Map<String, dynamic>?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (list != null) 'list': list,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Capabilities supported by the agent.
///
/// Advertised during initialization to inform the client about
/// available features and content types.
///
/// See protocol docs: [Agent Capabilities](https://agentclientprotocol.com/protocol/initialization#agent-capabilities)
final class AgentCapabilities implements HasMeta {
  /// Whether the agent supports `session/load`.
  final bool loadSession;

  /// MCP capabilities supported by the agent.
  final McpCapabilities mcpCapabilities;

  /// Prompt capabilities supported by the agent.
  final PromptCapabilities promptCapabilities;

  /// The session capabilities.
  final SessionCapabilities sessionCapabilities;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AgentCapabilities].
  const AgentCapabilities({
    this.loadSession = false,
    this.mcpCapabilities = const McpCapabilities(),
    this.promptCapabilities = const PromptCapabilities(),
    this.sessionCapabilities = const SessionCapabilities(),
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AgentCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {
      'loadSession',
      'mcpCapabilities',
      'promptCapabilities',
      'sessionCapabilities',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AgentCapabilities(
      loadSession: json['loadSession'] as bool? ?? false,
      mcpCapabilities:
          json['mcpCapabilities'] is Map<String, dynamic>
              ? McpCapabilities.fromJson(
                json['mcpCapabilities'] as Map<String, dynamic>,
              )
              : const McpCapabilities(),
      promptCapabilities:
          json['promptCapabilities'] is Map<String, dynamic>
              ? PromptCapabilities.fromJson(
                json['promptCapabilities'] as Map<String, dynamic>,
              )
              : const PromptCapabilities(),
      sessionCapabilities:
          json['sessionCapabilities'] is Map<String, dynamic>
              ? SessionCapabilities.fromJson(
                json['sessionCapabilities'] as Map<String, dynamic>,
              )
              : const SessionCapabilities(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'loadSession': loadSession,
    'mcpCapabilities': mcpCapabilities.toJson(),
    'promptCapabilities': promptCapabilities.toJson(),
    'sessionCapabilities': sessionCapabilities.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
