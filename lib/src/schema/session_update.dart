import 'package:acp/src/schema/has_meta.dart';

/// A streaming session update notification payload.
///
/// Session updates are discriminated by the `sessionUpdate` JSON key
/// (NOT the standard `type` field). This is a non-standard discriminator
/// pattern specific to ACP.
///
/// Unknown discriminator values are captured as [UnknownSessionUpdate]
/// for forward compatibility.
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
      'agent_message_chunk' => AgentMessageChunk.fromJson(json),
      'user_message_chunk' => UserMessageChunk.fromJson(json),
      'agent_thought_chunk' => AgentThoughtChunk.fromJson(json),
      'tool_call' => ToolCallSessionUpdate.fromJson(json),
      'tool_call_update' => ToolCallDeltaSessionUpdate.fromJson(json),
      'plan' => PlanUpdate.fromJson(json),
      'available_commands_update' => AvailableCommandsSessionUpdate.fromJson(
        json,
      ),
      'current_mode_update' => CurrentModeSessionUpdate.fromJson(json),
      'config_option_update' => ConfigOptionSessionUpdate.fromJson(json),
      _ => UnknownSessionUpdate(
        sessionUpdateType: updateType,
        rawJson: json,
        meta: json['_meta'] as Map<String, Object?>?,
      ),
    };
  }

  /// Serializes this session update to JSON.
  Map<String, dynamic> toJson();
}

/// Agent message text chunk.
final class AgentMessageChunk extends SessionUpdate {
  /// The content chunk (raw JSON, preserving ContentBlock structure).
  final Map<String, dynamic> content;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [AgentMessageChunk].
  const AgentMessageChunk({required this.content, this.meta});

  /// Deserializes from JSON.
  factory AgentMessageChunk.fromJson(Map<String, dynamic> json) {
    return AgentMessageChunk(
      content: json['content'] as Map<String, dynamic>,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'agent_message_chunk',
    'content': content,
    if (meta != null) '_meta': meta,
  };
}

/// User message text chunk.
final class UserMessageChunk extends SessionUpdate {
  /// The content chunk.
  final Map<String, dynamic> content;

  @override
  final Map<String, Object?>? meta;

  /// Creates a [UserMessageChunk].
  const UserMessageChunk({required this.content, this.meta});

  /// Deserializes from JSON.
  factory UserMessageChunk.fromJson(Map<String, dynamic> json) {
    return UserMessageChunk(
      content: json['content'] as Map<String, dynamic>,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'user_message_chunk',
    'content': content,
    if (meta != null) '_meta': meta,
  };
}

/// Agent thought/reasoning chunk.
final class AgentThoughtChunk extends SessionUpdate {
  /// The content chunk.
  final Map<String, dynamic> content;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [AgentThoughtChunk].
  const AgentThoughtChunk({required this.content, this.meta});

  /// Deserializes from JSON.
  factory AgentThoughtChunk.fromJson(Map<String, dynamic> json) {
    return AgentThoughtChunk(
      content: json['content'] as Map<String, dynamic>,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'agent_thought_chunk',
    'content': content,
    if (meta != null) '_meta': meta,
  };
}

/// Tool call initiated.
final class ToolCallSessionUpdate extends SessionUpdate {
  /// The raw tool call JSON payload.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates a [ToolCallSessionUpdate].
  const ToolCallSessionUpdate({required this.rawJson, this.meta});

  /// Deserializes from JSON.
  factory ToolCallSessionUpdate.fromJson(Map<String, dynamic> json) {
    return ToolCallSessionUpdate(
      rawJson: json,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// Tool call progress update.
final class ToolCallDeltaSessionUpdate extends SessionUpdate {
  /// The raw tool call update JSON payload.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates a [ToolCallDeltaSessionUpdate].
  const ToolCallDeltaSessionUpdate({required this.rawJson, this.meta});

  /// Deserializes from JSON.
  factory ToolCallDeltaSessionUpdate.fromJson(Map<String, dynamic> json) {
    return ToolCallDeltaSessionUpdate(
      rawJson: json,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// Execution plan update (full snapshot replacement).
final class PlanUpdate extends SessionUpdate {
  /// The raw plan JSON payload.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates a [PlanUpdate].
  const PlanUpdate({required this.rawJson, this.meta});

  /// Deserializes from JSON.
  factory PlanUpdate.fromJson(Map<String, dynamic> json) {
    return PlanUpdate(
      rawJson: json,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// Available commands update (full snapshot replacement).
final class AvailableCommandsSessionUpdate extends SessionUpdate {
  /// The raw available commands JSON payload.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [AvailableCommandsSessionUpdate].
  const AvailableCommandsSessionUpdate({required this.rawJson, this.meta});

  /// Deserializes from JSON.
  factory AvailableCommandsSessionUpdate.fromJson(Map<String, dynamic> json) {
    return AvailableCommandsSessionUpdate(
      rawJson: json,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// Current mode changed.
final class CurrentModeSessionUpdate extends SessionUpdate {
  /// The new current mode ID.
  final String currentModeId;

  @override
  final Map<String, Object?>? meta;

  /// Creates a [CurrentModeSessionUpdate].
  const CurrentModeSessionUpdate({required this.currentModeId, this.meta});

  /// Deserializes from JSON.
  factory CurrentModeSessionUpdate.fromJson(Map<String, dynamic> json) {
    return CurrentModeSessionUpdate(
      currentModeId: json['currentModeId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'current_mode_update',
    'currentModeId': currentModeId,
    if (meta != null) '_meta': meta,
  };
}

/// Configuration option update.
final class ConfigOptionSessionUpdate extends SessionUpdate {
  /// The raw config option update JSON payload.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates a [ConfigOptionSessionUpdate].
  const ConfigOptionSessionUpdate({required this.rawJson, this.meta});

  /// Deserializes from JSON.
  factory ConfigOptionSessionUpdate.fromJson(Map<String, dynamic> json) {
    return ConfigOptionSessionUpdate(
      rawJson: json,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// Unknown session update, preserved for forward compatibility.
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
