// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.unstable.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/has_meta.dart';
import 'package:meta/meta.dart';

// -- session/fork (unstable) --
@experimental
/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request parameters for forking an existing session.
///
/// Creates a new session based on the context of an existing one, allowing
/// operations like generating summaries without affecting the original session's history.
///
/// Only available if the Agent supports the `session.fork` capability.
final class ForkSessionRequest implements HasMeta {
  /// **UNSTABLE**
  ///
  /// This capability is not part of the spec yet, and may be removed or changed at any point.
  ///
  /// Additional workspace roots to activate for this session. Each path must be absolute.
  ///
  /// When omitted or empty, no additional roots are activated. When non-empty,
  /// this is the complete resulting additional-root list for the forked
  /// session.
  final List<String> additionalDirectories;

  /// The working directory for this session.
  final String cwd;

  /// List of MCP servers to connect to for this session.
  final List<Map<String, dynamic>> mcpServers;

  /// The ID of the session to fork.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ForkSessionRequest].
  const ForkSessionRequest({
    this.additionalDirectories = const [],
    required this.cwd,
    this.mcpServers = const [],
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ForkSessionRequest.fromJson(Map<String, dynamic> json) {
    final known = {
      'additionalDirectories',
      'cwd',
      'mcpServers',
      'sessionId',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ForkSessionRequest(
      additionalDirectories:
          (json['additionalDirectories'] as List<dynamic>?)?.cast<String>() ??
          const [],
      cwd: json['cwd'] as String,
      mcpServers:
          (json['mcpServers'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const [],
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'additionalDirectories': additionalDirectories,
    'cwd': cwd,
    'mcpServers': mcpServers,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

@experimental
/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response from forking an existing session.
final class ForkSessionResponse implements HasMeta {
  /// Initial session configuration options if supported by the Agent.
  final List<Map<String, dynamic>>? configOptions;

  /// **UNSTABLE**
  ///
  /// This capability is not part of the spec yet, and may be removed or changed at any point.
  ///
  /// Initial model state if supported by the Agent
  final Map<String, dynamic>? models;

  /// Initial mode state if supported by the Agent
  ///
  /// See protocol docs: [Session Modes](https://agentclientprotocol.com/protocol/session-modes)
  final Map<String, dynamic>? modes;

  /// Unique identifier for the newly created forked session.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ForkSessionResponse].
  const ForkSessionResponse({
    this.configOptions,
    this.models,
    this.modes,
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ForkSessionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'configOptions', 'models', 'modes', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ForkSessionResponse(
      configOptions:
          (json['configOptions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>(),
      models: json['models'] as Map<String, dynamic>?,
      modes: json['modes'] as Map<String, dynamic>?,
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (configOptions != null) 'configOptions': configOptions,
    if (models != null) 'models': models,
    if (modes != null) 'modes': modes,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
