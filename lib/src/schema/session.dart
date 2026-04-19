// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/has_meta.dart';

/// Request parameters for creating a new session.
///
/// See protocol docs: [Creating a Session](https://agentclientprotocol.com/protocol/session-setup#creating-a-session)
final class NewSessionRequest implements HasMeta {
  /// The working directory for this session. Must be an absolute path.
  final String cwd;

  /// List of MCP (Model Context Protocol) servers the agent should connect to.
  final List<Map<String, dynamic>> mcpServers;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NewSessionRequest].
  const NewSessionRequest({
    required this.cwd,
    this.mcpServers = const [],
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NewSessionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'cwd', 'mcpServers', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NewSessionRequest(
      cwd: json['cwd'] as String,
      mcpServers:
          (json['mcpServers'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const [],
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'cwd': cwd,
    'mcpServers': mcpServers,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response from creating a new session.
///
/// See protocol docs: [Creating a Session](https://agentclientprotocol.com/protocol/session-setup#creating-a-session)
final class NewSessionResponse implements HasMeta {
  /// Initial session configuration options if supported by the Agent.
  final List<Map<String, dynamic>>? configOptions;

  /// Initial mode state if supported by the Agent
  ///
  /// See protocol docs: [Session Modes](https://agentclientprotocol.com/protocol/session-modes)
  final Map<String, dynamic>? modes;

  /// Unique identifier for the created session.
  ///
  /// Used in all subsequent requests for this conversation.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NewSessionResponse].
  const NewSessionResponse({
    this.configOptions,
    this.modes,
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NewSessionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'configOptions', 'modes', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NewSessionResponse(
      configOptions:
          (json['configOptions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>(),
      modes: json['modes'] as Map<String, dynamic>?,
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (configOptions != null) 'configOptions': configOptions,
    if (modes != null) 'modes': modes,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request parameters for loading an existing session.
///
/// Only available if the Agent supports the `loadSession` capability.
///
/// See protocol docs: [Loading Sessions](https://agentclientprotocol.com/protocol/session-setup#loading-sessions)
final class LoadSessionRequest implements HasMeta {
  /// The working directory for this session.
  final String cwd;

  /// List of MCP servers to connect to for this session.
  final List<Map<String, dynamic>> mcpServers;

  /// The ID of the session to load.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [LoadSessionRequest].
  const LoadSessionRequest({
    required this.cwd,
    this.mcpServers = const [],
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory LoadSessionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'cwd', 'mcpServers', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return LoadSessionRequest(
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

/// Response from loading an existing session.
final class LoadSessionResponse implements HasMeta {
  /// Initial session configuration options if supported by the Agent.
  final List<Map<String, dynamic>>? configOptions;

  /// Initial mode state if supported by the Agent
  ///
  /// See protocol docs: [Session Modes](https://agentclientprotocol.com/protocol/session-modes)
  final Map<String, dynamic>? modes;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [LoadSessionResponse].
  const LoadSessionResponse({
    this.configOptions,
    this.modes,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory LoadSessionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'configOptions', 'modes', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return LoadSessionResponse(
      configOptions:
          (json['configOptions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>(),
      modes: json['modes'] as Map<String, dynamic>?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (configOptions != null) 'configOptions': configOptions,
    if (modes != null) 'modes': modes,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request parameters for sending a user prompt to the agent.
///
/// Contains the user's message and any additional context.
///
/// See protocol docs: [User Message](https://agentclientprotocol.com/protocol/prompt-turn#1-user-message)
final class PromptRequest implements HasMeta {
  /// The blocks of content that compose the user's message.
  ///
  /// As a baseline, the Agent MUST support [`ContentBlock::Text`] and [`ContentBlock::ResourceLink`],
  /// while other variants are optionally enabled via [`PromptCapabilities`].
  ///
  /// The Client MUST adapt its interface according to [`PromptCapabilities`].
  ///
  /// The client MAY include referenced pieces of context as either
  /// [`ContentBlock::Resource`] or [`ContentBlock::ResourceLink`].
  ///
  /// When available, [`ContentBlock::Resource`] is preferred
  /// as it avoids extra round-trips and allows the message to include
  /// pieces of context from sources the agent may not have access to.
  final List<ContentBlock> prompt;

  /// The ID of the session to send this user message to
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [PromptRequest].
  const PromptRequest({
    this.prompt = const [],
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory PromptRequest.fromJson(Map<String, dynamic> json) {
    final known = {'prompt', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return PromptRequest(
      prompt:
          (json['prompt'] as List<dynamic>?)
              ?.map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'prompt': prompt.map((e) => e.toJson()).toList(),
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Reasons why an agent stops processing a prompt turn.
///
/// See protocol docs: [Stop Reasons](https://agentclientprotocol.com/protocol/prompt-turn#stop-reasons)
enum StopReason {
  /// The turn ended successfully.
  endTurn('end_turn'),

  /// The turn ended because the agent reached the maximum number of tokens.
  maxTokens('max_tokens'),

  /// The turn ended because the agent reached the maximum number of allowed
  /// agent requests between user turns.
  maxTurnRequests('max_turn_requests'),

  /// The turn ended because the agent refused to continue. The user prompt
  /// and everything that comes after it won't be included in the next
  /// prompt, so this should be reflected in the UI.
  refusal('refusal'),

  /// The turn was cancelled by the client via `session/cancel`.
  ///
  /// This stop reason MUST be returned when the client sends a `session/cancel`
  /// notification, even if the cancellation causes exceptions in underlying operations.
  /// Agents should catch these exceptions and return this semantically meaningful
  /// response to confirm successful cancellation.
  cancelled('cancelled');

  /// The wire-format string value.
  final String value;

  const StopReason(this.value);

  /// Parses a [StopReason] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static StopReason? fromString(String value) {
    for (final v in values) {
      if (v.value == value) return v;
    }
    return null;
  }
}

/// Response from processing a user prompt.
///
/// See protocol docs: [Check for Completion](https://agentclientprotocol.com/protocol/prompt-turn#4-check-for-completion)
final class PromptResponse implements HasMeta {
  /// Indicates why the agent stopped processing the turn.
  final String stopReason;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [PromptResponse].
  const PromptResponse({
    required this.stopReason,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory PromptResponse.fromJson(Map<String, dynamic> json) {
    final known = {'stopReason', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return PromptResponse(
      stopReason: json['stopReason'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'stopReason': stopReason,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Notification to cancel ongoing operations for a session.
///
/// See protocol docs: [Cancellation](https://agentclientprotocol.com/protocol/prompt-turn#cancellation)
final class CancelNotification implements HasMeta {
  /// The ID of the session to cancel operations for.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CancelNotification].
  const CancelNotification({
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory CancelNotification.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CancelNotification(
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request parameters for setting a session mode.
final class SetSessionModeRequest implements HasMeta {
  /// The ID of the mode to set.
  final String modeId;

  /// The ID of the session to set the mode for.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionModeRequest].
  const SetSessionModeRequest({
    required this.modeId,
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SetSessionModeRequest.fromJson(Map<String, dynamic> json) {
    final known = {'modeId', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetSessionModeRequest(
      modeId: json['modeId'] as String,
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'modeId': modeId,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `session/set_mode` method.
final class SetSessionModeResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionModeResponse].
  const SetSessionModeResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory SetSessionModeResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetSessionModeResponse(
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request parameters for setting a session configuration option.
final class SetSessionConfigOptionRequest implements HasMeta {
  /// The ID of the configuration option to set.
  final String configId;

  /// The ID of the session to set the configuration option for.
  final String sessionId;

  /// The ID of the configuration option value to set.
  final String value;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionConfigOptionRequest].
  const SetSessionConfigOptionRequest({
    required this.configId,
    required this.sessionId,
    required this.value,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SetSessionConfigOptionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'configId', 'sessionId', 'value', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetSessionConfigOptionRequest(
      configId: json['configId'] as String,
      sessionId: json['sessionId'] as String,
      value: json['value'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'configId': configId,
    'sessionId': sessionId,
    'value': value,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `session/set_config_option` method.
final class SetSessionConfigOptionResponse implements HasMeta {
  /// The full set of configuration options and their current values.
  final List<Map<String, dynamic>> configOptions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionConfigOptionResponse].
  const SetSessionConfigOptionResponse({
    this.configOptions = const [],
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SetSessionConfigOptionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'configOptions', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetSessionConfigOptionResponse(
      configOptions:
          (json['configOptions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const [],
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'configOptions': configOptions,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Notification containing a session update from the agent.
///
/// Used to stream real-time progress and results during prompt processing.
///
/// See protocol docs: [Agent Reports Output](https://agentclientprotocol.com/protocol/prompt-turn#3-agent-reports-output)
final class SessionNotification implements HasMeta {
  /// The ID of the session this update pertains to.
  final String sessionId;

  /// The actual update content.
  final Map<String, dynamic> update;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionNotification].
  const SessionNotification({
    required this.sessionId,
    required this.update,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SessionNotification.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'update', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionNotification(
      sessionId: json['sessionId'] as String,
      update: json['update'] as Map<String, dynamic>,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'update': update,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Information about a session returned by session/list
final class SessionInfo implements HasMeta {
  /// The working directory for this session. Must be an absolute path.
  final String cwd;

  /// Unique identifier for the session
  final String sessionId;

  /// Human-readable title for the session
  final String? title;

  /// ISO 8601 timestamp of last activity
  final String? updatedAt;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionInfo].
  const SessionInfo({
    required this.cwd,
    required this.sessionId,
    this.title,
    this.updatedAt,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    final known = {'cwd', 'sessionId', 'title', 'updatedAt', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionInfo(
      cwd: json['cwd'] as String,
      sessionId: json['sessionId'] as String,
      title: json['title'] as String?,
      updatedAt: json['updatedAt'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'cwd': cwd,
    'sessionId': sessionId,
    if (title != null) 'title': title,
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request parameters for listing existing sessions.
///
/// Only available if the Agent supports the `sessionCapabilities.list` capability.
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

/// Response from listing sessions.
final class ListSessionsResponse implements HasMeta {
  /// Opaque cursor token. If present, pass this in the next request's cursor parameter
  /// to fetch the next page. If absent, there are no more results.
  final String? nextCursor;

  /// Array of session information objects
  final List<SessionInfo> sessions;

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
          (json['sessions'] as List<dynamic>?)
              ?.map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (nextCursor != null) 'nextCursor': nextCursor,
    'sessions': sessions.map((e) => e.toJson()).toList(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
