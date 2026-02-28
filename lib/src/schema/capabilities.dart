import 'package:acp/src/schema/has_meta.dart';

/// File system capabilities supported by the client.
final class FileSystemCapability implements HasMeta {
  /// Whether the client supports reading text files.
  final bool readTextFile;

  /// Whether the client supports writing text files.
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
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return FileSystemCapability(
      readTextFile: json['readTextFile'] as bool? ?? false,
      writeTextFile: json['writeTextFile'] as bool? ?? false,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
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
/// Advertised during initialization to inform the agent about available
/// features and methods.
final class ClientCapabilities implements HasMeta {
  /// File system capabilities.
  final FileSystemCapability fs;

  /// Whether the client supports all `terminal/*` methods.
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
    final extension = Map<String, Object?>.fromEntries(
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
      extensionData: extension.isEmpty ? null : extension,
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

/// Prompt capabilities supported by the agent.
final class PromptCapabilities implements HasMeta {
  /// Whether the agent supports image content blocks.
  final bool image;

  /// Whether the agent supports audio content blocks.
  final bool audio;

  /// Whether the agent supports embedded context content blocks.
  final bool embeddedContext;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [PromptCapabilities].
  const PromptCapabilities({
    this.image = false,
    this.audio = false,
    this.embeddedContext = false,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory PromptCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'image', 'audio', 'embeddedContext', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return PromptCapabilities(
      image: json['image'] as bool? ?? false,
      audio: json['audio'] as bool? ?? false,
      embeddedContext: json['embeddedContext'] as bool? ?? false,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'image': image,
    'audio': audio,
    'embeddedContext': embeddedContext,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// MCP capabilities supported by the agent.
final class McpCapabilities implements HasMeta {
  /// Whether the agent supports HTTP MCP transport.
  final bool http;

  /// Whether the agent supports SSE MCP transport.
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
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return McpCapabilities(
      http: json['http'] as bool? ?? false,
      sse: json['sse'] as bool? ?? false,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
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
final class SessionCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionCapabilities].
  const SessionCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory SessionCapabilities.fromJson(Map<String, dynamic> json) {
    final known = <String>{'_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionCapabilities(
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Capabilities supported by the agent.
final class AgentCapabilities implements HasMeta {
  /// Whether the agent supports loading existing sessions.
  final bool loadSession;

  /// Prompt content type capabilities.
  final PromptCapabilities promptCapabilities;

  /// MCP server capabilities.
  final McpCapabilities mcpCapabilities;

  /// Session-level capabilities.
  final SessionCapabilities sessionCapabilities;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AgentCapabilities].
  const AgentCapabilities({
    this.loadSession = false,
    this.promptCapabilities = const PromptCapabilities(),
    this.mcpCapabilities = const McpCapabilities(),
    this.sessionCapabilities = const SessionCapabilities(),
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AgentCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {
      'loadSession',
      'promptCapabilities',
      'mcpCapabilities',
      'sessionCapabilities',
      '_meta',
    };
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AgentCapabilities(
      loadSession: json['loadSession'] as bool? ?? false,
      promptCapabilities:
          json['promptCapabilities'] is Map<String, dynamic>
              ? PromptCapabilities.fromJson(
                json['promptCapabilities'] as Map<String, dynamic>,
              )
              : const PromptCapabilities(),
      mcpCapabilities:
          json['mcpCapabilities'] is Map<String, dynamic>
              ? McpCapabilities.fromJson(
                json['mcpCapabilities'] as Map<String, dynamic>,
              )
              : const McpCapabilities(),
      sessionCapabilities:
          json['sessionCapabilities'] is Map<String, dynamic>
              ? SessionCapabilities.fromJson(
                json['sessionCapabilities'] as Map<String, dynamic>,
              )
              : const SessionCapabilities(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'loadSession': loadSession,
    'promptCapabilities': promptCapabilities.toJson(),
    'mcpCapabilities': mcpCapabilities.toJson(),
    'sessionCapabilities': sessionCapabilities.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
