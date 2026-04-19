// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/has_meta.dart';

/// Different types of updates that can be sent during session processing.
///
/// These updates provide real-time feedback about the agent's progress.
///
/// See protocol docs: [Agent Reports Output](https://agentclientprotocol.com/protocol/prompt-turn#3-agent-reports-output)
sealed class SessionUpdate implements HasMeta {
  const SessionUpdate();

  /// Deserializes a [SessionUpdate] from JSON.
  ///
  /// Switches on the `sessionUpdate` discriminator field.
  factory SessionUpdate.fromJson(Map<String, dynamic> json) {
    final updateType = json['sessionUpdate'] as String?;
    if (updateType == null) {
      return UnknownSessionUpdate(rawJson: json);
    }
    return switch (updateType) {
      'user_message_chunk' => UserMessageChunk.fromJson(json),
      'agent_message_chunk' => AgentMessageChunk.fromJson(json),
      'agent_thought_chunk' => AgentThoughtChunk.fromJson(json),
      'tool_call' => ToolCallSessionUpdate.fromJson(json),
      'tool_call_update' => ToolCallDeltaSessionUpdate.fromJson(json),
      'plan' => PlanUpdate.fromJson(json),
      'available_commands_update' => AvailableCommandsSessionUpdate.fromJson(
        json,
      ),
      'current_mode_update' => CurrentModeSessionUpdate.fromJson(json),
      'config_option_update' => ConfigOptionSessionUpdate.fromJson(json),
      'session_info_update' => SessionInfoUpdate.fromJson(json),
      _ => UnknownSessionUpdate(
        sessionUpdateType: updateType,
        rawJson: json,
        meta: json['_meta'] as Map<String, Object?>?,
      ),
    };
  }

  /// Serializes this sessionUpdate to JSON.
  Map<String, dynamic> toJson();
}

/// A chunk of the user's message being streamed.
final class UserMessageChunk extends SessionUpdate {
  /// A single item of content
  final ContentBlock content;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [UserMessageChunk].
  const UserMessageChunk({
    required this.content,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory UserMessageChunk.fromJson(Map<String, dynamic> json) {
    final known = {'content', '_meta', 'sessionUpdate'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return UserMessageChunk(
      content: ContentBlock.fromJson(json['content'] as Map<String, dynamic>),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'user_message_chunk',
    'content': content.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A chunk of the agent's response being streamed.
final class AgentMessageChunk extends SessionUpdate {
  /// A single item of content
  final ContentBlock content;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AgentMessageChunk].
  const AgentMessageChunk({
    required this.content,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AgentMessageChunk.fromJson(Map<String, dynamic> json) {
    final known = {'content', '_meta', 'sessionUpdate'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AgentMessageChunk(
      content: ContentBlock.fromJson(json['content'] as Map<String, dynamic>),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'agent_message_chunk',
    'content': content.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A chunk of the agent's internal reasoning being streamed.
final class AgentThoughtChunk extends SessionUpdate {
  /// A single item of content
  final ContentBlock content;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AgentThoughtChunk].
  const AgentThoughtChunk({
    required this.content,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AgentThoughtChunk.fromJson(Map<String, dynamic> json) {
    final known = {'content', '_meta', 'sessionUpdate'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AgentThoughtChunk(
      content: ContentBlock.fromJson(json['content'] as Map<String, dynamic>),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'agent_thought_chunk',
    'content': content.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Notification that a new tool call has been initiated.
final class ToolCallSessionUpdate extends SessionUpdate {
  /// Content produced by the tool call.
  final List<Map<String, dynamic>>? content;

  /// The category of tool being invoked.
  /// Helps clients choose appropriate icons and UI treatment.
  final String? kind;

  /// File locations affected by this tool call.
  /// Enables "follow-along" features in clients.
  final List<Map<String, dynamic>>? locations;

  /// Raw input parameters sent to the tool.
  final Map<String, dynamic>? rawInput;

  /// Raw output returned by the tool.
  final Map<String, dynamic>? rawOutput;

  /// Current execution status of the tool call.
  final String? status;

  /// Human-readable title describing what the tool is doing.
  final String title;

  /// Unique identifier for this tool call within the session.
  final String toolCallId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ToolCallSessionUpdate].
  const ToolCallSessionUpdate({
    this.content,
    this.kind,
    this.locations,
    this.rawInput,
    this.rawOutput,
    this.status,
    required this.title,
    required this.toolCallId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ToolCallSessionUpdate.fromJson(Map<String, dynamic> json) {
    final known = {
      'content',
      'kind',
      'locations',
      'rawInput',
      'rawOutput',
      'status',
      'title',
      'toolCallId',
      '_meta',
      'sessionUpdate',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ToolCallSessionUpdate(
      content:
          (json['content'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      kind: json['kind'] as String?,
      locations:
          (json['locations'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      rawInput: json['rawInput'] as Map<String, dynamic>?,
      rawOutput: json['rawOutput'] as Map<String, dynamic>?,
      status: json['status'] as String?,
      title: json['title'] as String,
      toolCallId: json['toolCallId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'tool_call',
    if (content != null) 'content': content,
    if (kind != null) 'kind': kind,
    if (locations != null) 'locations': locations,
    if (rawInput != null) 'rawInput': rawInput,
    if (rawOutput != null) 'rawOutput': rawOutput,
    if (status != null) 'status': status,
    'title': title,
    'toolCallId': toolCallId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Update on the status or results of a tool call.
final class ToolCallDeltaSessionUpdate extends SessionUpdate {
  /// Replace the content collection.
  final List<Map<String, dynamic>>? content;

  /// Update the tool kind.
  final String? kind;

  /// Replace the locations collection.
  final List<Map<String, dynamic>>? locations;

  /// Update the raw input.
  final Map<String, dynamic>? rawInput;

  /// Update the raw output.
  final Map<String, dynamic>? rawOutput;

  /// Update the execution status.
  final String? status;

  /// Update the human-readable title.
  final String? title;

  /// The ID of the tool call being updated.
  final String toolCallId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ToolCallDeltaSessionUpdate].
  const ToolCallDeltaSessionUpdate({
    this.content,
    this.kind,
    this.locations,
    this.rawInput,
    this.rawOutput,
    this.status,
    this.title,
    required this.toolCallId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ToolCallDeltaSessionUpdate.fromJson(Map<String, dynamic> json) {
    final known = {
      'content',
      'kind',
      'locations',
      'rawInput',
      'rawOutput',
      'status',
      'title',
      'toolCallId',
      '_meta',
      'sessionUpdate',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ToolCallDeltaSessionUpdate(
      content:
          (json['content'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      kind: json['kind'] as String?,
      locations:
          (json['locations'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      rawInput: json['rawInput'] as Map<String, dynamic>?,
      rawOutput: json['rawOutput'] as Map<String, dynamic>?,
      status: json['status'] as String?,
      title: json['title'] as String?,
      toolCallId: json['toolCallId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'tool_call_update',
    if (content != null) 'content': content,
    if (kind != null) 'kind': kind,
    if (locations != null) 'locations': locations,
    if (rawInput != null) 'rawInput': rawInput,
    if (rawOutput != null) 'rawOutput': rawOutput,
    if (status != null) 'status': status,
    if (title != null) 'title': title,
    'toolCallId': toolCallId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// The agent's execution plan for complex tasks.
/// See protocol docs: [Agent Plan](https://agentclientprotocol.com/protocol/agent-plan)
final class PlanUpdate extends SessionUpdate {
  /// The list of tasks to be accomplished.
  ///
  /// When updating a plan, the agent must send a complete list of all entries
  /// with their current status. The client replaces the entire plan with each update.
  final List<Map<String, dynamic>> entries;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [PlanUpdate].
  const PlanUpdate({required this.entries, this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory PlanUpdate.fromJson(Map<String, dynamic> json) {
    final known = {'entries', '_meta', 'sessionUpdate'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return PlanUpdate(
      entries: (json['entries'] as List<dynamic>).cast<Map<String, dynamic>>(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'plan',
    'entries': entries,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Available commands are ready or have changed
final class AvailableCommandsSessionUpdate extends SessionUpdate {
  /// Commands the agent can execute
  final List<Map<String, dynamic>> availableCommands;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AvailableCommandsSessionUpdate].
  const AvailableCommandsSessionUpdate({
    required this.availableCommands,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AvailableCommandsSessionUpdate.fromJson(Map<String, dynamic> json) {
    final known = {'availableCommands', '_meta', 'sessionUpdate'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AvailableCommandsSessionUpdate(
      availableCommands:
          (json['availableCommands'] as List<dynamic>)
              .cast<Map<String, dynamic>>(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'available_commands_update',
    'availableCommands': availableCommands,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// The current mode of the session has changed
///
/// See protocol docs: [Session Modes](https://agentclientprotocol.com/protocol/session-modes)
final class CurrentModeSessionUpdate extends SessionUpdate {
  /// The ID of the current mode
  final String currentModeId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CurrentModeSessionUpdate].
  const CurrentModeSessionUpdate({
    required this.currentModeId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory CurrentModeSessionUpdate.fromJson(Map<String, dynamic> json) {
    final known = {'currentModeId', '_meta', 'sessionUpdate'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CurrentModeSessionUpdate(
      currentModeId: json['currentModeId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'current_mode_update',
    'currentModeId': currentModeId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Session configuration options have been updated.
final class ConfigOptionSessionUpdate extends SessionUpdate {
  /// The full set of configuration options and their current values.
  final List<Map<String, dynamic>> configOptions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ConfigOptionSessionUpdate].
  const ConfigOptionSessionUpdate({
    required this.configOptions,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ConfigOptionSessionUpdate.fromJson(Map<String, dynamic> json) {
    final known = {'configOptions', '_meta', 'sessionUpdate'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ConfigOptionSessionUpdate(
      configOptions:
          (json['configOptions'] as List<dynamic>).cast<Map<String, dynamic>>(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'config_option_update',
    'configOptions': configOptions,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Session metadata has been updated (title, timestamps, custom metadata)
final class SessionInfoUpdate extends SessionUpdate {
  /// Human-readable title for the session. Set to null to clear.
  final String? title;

  /// ISO 8601 timestamp of last activity. Set to null to clear.
  final String? updatedAt;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionInfoUpdate].
  const SessionInfoUpdate({
    this.title,
    this.updatedAt,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SessionInfoUpdate.fromJson(Map<String, dynamic> json) {
    final known = {'title', 'updatedAt', '_meta', 'sessionUpdate'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionInfoUpdate(
      title: json['title'] as String?,
      updatedAt: json['updatedAt'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'session_info_update',
    if (title != null) 'title': title,
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A sessionUpdate with an unknown sessionUpdate, preserved for forward compatibility.
final class UnknownSessionUpdate extends SessionUpdate {
  /// The unknown discriminator value.
  final String? sessionUpdateType;

  /// The raw JSON object, preserved as-is.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [UnknownSessionUpdate].
  const UnknownSessionUpdate({
    this.sessionUpdateType,
    required this.rawJson,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => rawJson;
}
