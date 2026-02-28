import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/has_meta.dart';

/// Request parameters for the `session/new` method.
final class NewSessionRequest implements HasMeta {
  /// The working directory for the session.
  final String cwd;

  /// MCP servers to connect to (raw JSON for each server).
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

/// Response to the `session/new` method.
final class NewSessionResponse implements HasMeta {
  /// The unique session identifier.
  final String sessionId;

  /// Available modes and current mode (raw JSON).
  final Map<String, dynamic>? modes;

  /// Available configuration options (raw JSON list).
  final List<Map<String, dynamic>>? configOptions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NewSessionResponse].
  const NewSessionResponse({
    required this.sessionId,
    this.modes,
    this.configOptions,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NewSessionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'modes', 'configOptions', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NewSessionResponse(
      sessionId: json['sessionId'] as String,
      modes: json['modes'] as Map<String, dynamic>?,
      configOptions:
          (json['configOptions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    if (modes != null) 'modes': modes,
    if (configOptions != null) 'configOptions': configOptions,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request parameters for the `session/load` method.
final class LoadSessionRequest implements HasMeta {
  /// The session ID to resume.
  final String sessionId;

  /// The working directory.
  final String cwd;

  /// MCP servers to connect to (raw JSON for each server).
  final List<Map<String, dynamic>> mcpServers;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [LoadSessionRequest].
  const LoadSessionRequest({
    required this.sessionId,
    required this.cwd,
    this.mcpServers = const [],
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory LoadSessionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'cwd', 'mcpServers', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return LoadSessionRequest(
      sessionId: json['sessionId'] as String,
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
    'sessionId': sessionId,
    'cwd': cwd,
    'mcpServers': mcpServers,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to the `session/load` method.
final class LoadSessionResponse implements HasMeta {
  /// Available modes and current mode (raw JSON).
  final Map<String, dynamic>? modes;

  /// Available configuration options (raw JSON list).
  final List<Map<String, dynamic>>? configOptions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [LoadSessionResponse].
  const LoadSessionResponse({
    this.modes,
    this.configOptions,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory LoadSessionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'modes', 'configOptions', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return LoadSessionResponse(
      modes: json['modes'] as Map<String, dynamic>?,
      configOptions:
          (json['configOptions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (modes != null) 'modes': modes,
    if (configOptions != null) 'configOptions': configOptions,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request parameters for the `session/prompt` method.
final class PromptRequest implements HasMeta {
  /// The session ID to send the prompt to.
  final String sessionId;

  /// The prompt content blocks.
  final List<ContentBlock> prompt;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [PromptRequest].
  const PromptRequest({
    required this.sessionId,
    required this.prompt,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory PromptRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'prompt', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return PromptRequest(
      sessionId: json['sessionId'] as String,
      prompt:
          (json['prompt'] as List<dynamic>)
              .map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
              .toList(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'prompt': prompt.map((e) => e.toJson()).toList(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// The reason a prompt turn ended.
enum StopReason {
  /// The agent finished its turn normally.
  endTurn('end_turn'),

  /// Token limit reached.
  maxTokens('max_tokens'),

  /// Turn request limit reached.
  maxTurnRequests('max_turn_requests'),

  /// The agent refused to continue.
  refusal('refusal'),

  /// The prompt was canceled.
  cancelled('cancelled');

  /// The wire-format string value.
  final String value;

  const StopReason(this.value);

  /// Parses a [StopReason] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static StopReason? fromString(String value) {
    for (final reason in values) {
      if (reason.value == value) return reason;
    }
    return null;
  }
}

/// Response to the `session/prompt` method.
final class PromptResponse implements HasMeta {
  /// Why the prompt turn ended (wire-format string).
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

  /// The parsed [StopReason], or `null` if the value is unknown.
  StopReason? get stopReasonEnum => StopReason.fromString(stopReason);

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

/// Parameters for the `session/cancel` notification.
final class CancelNotification implements HasMeta {
  /// The session ID to cancel.
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

/// Request parameters for `session/set_mode`.
final class SetSessionModeRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// The mode ID to switch to.
  final String modeId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionModeRequest].
  const SetSessionModeRequest({
    required this.sessionId,
    required this.modeId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SetSessionModeRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'modeId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetSessionModeRequest(
      sessionId: json['sessionId'] as String,
      modeId: json['modeId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'modeId': modeId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `session/set_mode`.
final class SetSessionModeResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionModeResponse].
  const SetSessionModeResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory SetSessionModeResponse.fromJson(Map<String, dynamic> json) {
    final known = <String>{'_meta'};
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

/// Request parameters for `session/set_config_option`.
final class SetSessionConfigOptionRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// The config option ID.
  final String configId;

  /// The new value.
  final String value;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionConfigOptionRequest].
  const SetSessionConfigOptionRequest({
    required this.sessionId,
    required this.configId,
    required this.value,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SetSessionConfigOptionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'configId', 'value', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetSessionConfigOptionRequest(
      sessionId: json['sessionId'] as String,
      configId: json['configId'] as String,
      value: json['value'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'configId': configId,
    'value': value,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `session/set_config_option`.
final class SetSessionConfigOptionResponse implements HasMeta {
  /// The full set of configuration options and their current values.
  final List<Map<String, dynamic>> configOptions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionConfigOptionResponse].
  const SetSessionConfigOptionResponse({
    required this.configOptions,
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
          (json['configOptions'] as List<dynamic>).cast<Map<String, dynamic>>(),
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

/// Session update notification envelope.
///
/// Wraps a session update with the session ID it belongs to.
final class SessionNotification implements HasMeta {
  /// The session this update belongs to.
  final String sessionId;

  /// The update payload (raw JSON for the SessionUpdate).
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
