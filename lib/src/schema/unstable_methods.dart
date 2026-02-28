// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.unstable.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/has_meta.dart';
import 'package:meta/meta.dart';

// -- session/list (unstable) --
@experimental
/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request parameters for listing existing sessions.
///
/// Only available if the Agent supports the `listSessions` capability.
final class ListSessionsRequest implements HasMeta {
  /// Opaque cursor token from a previous response's nextCursor field for cursor-based pagination
  final String? cursor;

  /// Filter sessions by working directory. Must be an absolute path.
  final String? cwd;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ListSessionsRequest].
  const ListSessionsRequest({
    this.cursor,
    this.cwd,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ListSessionsRequest.fromJson(Map<String, dynamic> json) {
    final known = {'cursor', 'cwd', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ListSessionsRequest(
      cursor: json['cursor'] as String?,
      cwd: json['cwd'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (cursor != null) 'cursor': cursor,
    if (cwd != null) 'cwd': cwd,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

@experimental
/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response from listing sessions.
final class ListSessionsResponse implements HasMeta {
  /// Opaque cursor token. If present, pass this in the next request's cursor parameter
  /// to fetch the next page. If absent, there are no more results.
  final String? nextCursor;

  /// Array of session information objects
  final List<Map<String, dynamic>> sessions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ListSessionsResponse].
  const ListSessionsResponse({
    this.nextCursor,
    this.sessions = const [],
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ListSessionsResponse.fromJson(Map<String, dynamic> json) {
    final known = {'nextCursor', 'sessions', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ListSessionsResponse(
      nextCursor: json['nextCursor'] as String?,
      sessions:
          (json['sessions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          const [],
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (nextCursor != null) 'nextCursor': nextCursor,
    'sessions': sessions,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

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
    required this.cwd,
    this.mcpServers = const [],
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ForkSessionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'cwd', 'mcpServers', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ForkSessionRequest(
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
