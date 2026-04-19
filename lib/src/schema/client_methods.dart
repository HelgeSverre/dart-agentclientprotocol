// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/has_meta.dart';

// -- File System --
/// Request to read content from a text file.
///
/// Only available if the client supports the `fs.readTextFile` capability.
final class ReadTextFileRequest implements HasMeta {
  /// Maximum number of lines to read.
  final int? limit;

  /// Line number to start reading from (1-based).
  final int? line;

  /// Absolute path to the file to read.
  final String path;

  /// The session ID for this request.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ReadTextFileRequest].
  const ReadTextFileRequest({
    this.limit,
    this.line,
    required this.path,
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ReadTextFileRequest.fromJson(Map<String, dynamic> json) {
    final known = {'limit', 'line', 'path', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ReadTextFileRequest(
      limit: json['limit'] as int?,
      line: json['line'] as int?,
      path: json['path'] as String,
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (limit != null) 'limit': limit,
    if (line != null) 'line': line,
    'path': path,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response containing the contents of a text file.
final class ReadTextFileResponse implements HasMeta {
  /// The content.
  final String content;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ReadTextFileResponse].
  const ReadTextFileResponse({
    required this.content,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ReadTextFileResponse.fromJson(Map<String, dynamic> json) {
    final known = {'content', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ReadTextFileResponse(
      content: json['content'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'content': content,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request to write content to a text file.
///
/// Only available if the client supports the `fs.writeTextFile` capability.
final class WriteTextFileRequest implements HasMeta {
  /// The text content to write to the file.
  final String content;

  /// Absolute path to the file to write.
  final String path;

  /// The session ID for this request.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [WriteTextFileRequest].
  const WriteTextFileRequest({
    required this.content,
    required this.path,
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory WriteTextFileRequest.fromJson(Map<String, dynamic> json) {
    final known = {'content', 'path', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return WriteTextFileRequest(
      content: json['content'] as String,
      path: json['path'] as String,
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'content': content,
    'path': path,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `fs/write_text_file`
final class WriteTextFileResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [WriteTextFileResponse].
  const WriteTextFileResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory WriteTextFileResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return WriteTextFileResponse(
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

// -- Terminal --

/// Request to create a new terminal and execute a command.
final class CreateTerminalRequest implements HasMeta {
  /// Array of command arguments.
  final List<String> args;

  /// The command to execute.
  final String command;

  /// Working directory for the command (absolute path).
  final String? cwd;

  /// Environment variables for the command.
  final List<Map<String, dynamic>> env;

  /// Maximum number of output bytes to retain.
  ///
  /// When the limit is exceeded, the Client truncates from the beginning of the output
  /// to stay within the limit.
  ///
  /// The Client MUST ensure truncation happens at a character boundary to maintain valid
  /// string output, even if this means the retained output is slightly less than the
  /// specified limit.
  final int? outputByteLimit;

  /// The session ID for this request.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CreateTerminalRequest].
  const CreateTerminalRequest({
    this.args = const [],
    required this.command,
    this.cwd,
    this.env = const [],
    this.outputByteLimit,
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory CreateTerminalRequest.fromJson(Map<String, dynamic> json) {
    final known = {
      'args',
      'command',
      'cwd',
      'env',
      'outputByteLimit',
      'sessionId',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CreateTerminalRequest(
      args: (json['args'] as List<dynamic>?)?.cast<String>() ?? const [],
      command: json['command'] as String,
      cwd: json['cwd'] as String?,
      env:
          (json['env'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          const [],
      outputByteLimit: json['outputByteLimit'] as int?,
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'args': args,
    'command': command,
    if (cwd != null) 'cwd': cwd,
    'env': env,
    if (outputByteLimit != null) 'outputByteLimit': outputByteLimit,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response containing the ID of the created terminal.
final class CreateTerminalResponse implements HasMeta {
  /// The unique identifier for the created terminal.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CreateTerminalResponse].
  const CreateTerminalResponse({
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory CreateTerminalResponse.fromJson(Map<String, dynamic> json) {
    final known = {'terminalId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CreateTerminalResponse(
      terminalId: json['terminalId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request to get the current output and status of a terminal.
final class TerminalOutputRequest implements HasMeta {
  /// The session ID for this request.
  final String sessionId;

  /// The ID of the terminal to get output from.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [TerminalOutputRequest].
  const TerminalOutputRequest({
    required this.sessionId,
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory TerminalOutputRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'terminalId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return TerminalOutputRequest(
      sessionId: json['sessionId'] as String,
      terminalId: json['terminalId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response containing the terminal output and exit status.
final class TerminalOutputResponse implements HasMeta {
  /// Exit status if the command has completed.
  final Map<String, dynamic>? exitStatus;

  /// The terminal output captured so far.
  final String output;

  /// Whether the output was truncated due to byte limits.
  final bool truncated;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [TerminalOutputResponse].
  const TerminalOutputResponse({
    this.exitStatus,
    required this.output,
    required this.truncated,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory TerminalOutputResponse.fromJson(Map<String, dynamic> json) {
    final known = {'exitStatus', 'output', 'truncated', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return TerminalOutputResponse(
      exitStatus: json['exitStatus'] as Map<String, dynamic>?,
      output: json['output'] as String,
      truncated: json['truncated'] as bool,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (exitStatus != null) 'exitStatus': exitStatus,
    'output': output,
    'truncated': truncated,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request to release a terminal and free its resources.
final class ReleaseTerminalRequest implements HasMeta {
  /// The session ID for this request.
  final String sessionId;

  /// The ID of the terminal to release.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ReleaseTerminalRequest].
  const ReleaseTerminalRequest({
    required this.sessionId,
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ReleaseTerminalRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'terminalId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ReleaseTerminalRequest(
      sessionId: json['sessionId'] as String,
      terminalId: json['terminalId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to terminal/release method
final class ReleaseTerminalResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ReleaseTerminalResponse].
  const ReleaseTerminalResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory ReleaseTerminalResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ReleaseTerminalResponse(
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

/// Request to kill a terminal without releasing it.
final class KillTerminalCommandRequest implements HasMeta {
  /// The session ID for this request.
  final String sessionId;

  /// The ID of the terminal to kill.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [KillTerminalCommandRequest].
  const KillTerminalCommandRequest({
    required this.sessionId,
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory KillTerminalCommandRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'terminalId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return KillTerminalCommandRequest(
      sessionId: json['sessionId'] as String,
      terminalId: json['terminalId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `terminal/kill` method
final class KillTerminalCommandResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [KillTerminalCommandResponse].
  const KillTerminalCommandResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory KillTerminalCommandResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return KillTerminalCommandResponse(
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

/// Request to wait for a terminal command to exit.
final class WaitForTerminalExitRequest implements HasMeta {
  /// The session ID for this request.
  final String sessionId;

  /// The ID of the terminal to wait for.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [WaitForTerminalExitRequest].
  const WaitForTerminalExitRequest({
    required this.sessionId,
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory WaitForTerminalExitRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'terminalId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return WaitForTerminalExitRequest(
      sessionId: json['sessionId'] as String,
      terminalId: json['terminalId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response containing the exit status of a terminal command.
final class WaitForTerminalExitResponse implements HasMeta {
  /// The process exit code (may be null if terminated by signal).
  final int? exitCode;

  /// The signal that terminated the process (may be null if exited normally).
  final String? signal;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [WaitForTerminalExitResponse].
  const WaitForTerminalExitResponse({
    this.exitCode,
    this.signal,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory WaitForTerminalExitResponse.fromJson(Map<String, dynamic> json) {
    final known = {'exitCode', 'signal', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return WaitForTerminalExitResponse(
      exitCode: json['exitCode'] as int?,
      signal: json['signal'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (exitCode != null) 'exitCode': exitCode,
    if (signal != null) 'signal': signal,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

// -- Permission --

/// Request for user permission to execute a tool call.
///
/// Sent when the agent needs authorization before performing a sensitive operation.
///
/// See protocol docs: [Requesting Permission](https://agentclientprotocol.com/protocol/tool-calls#requesting-permission)
final class RequestPermissionRequest implements HasMeta {
  /// Available permission options for the user to choose from.
  final List<Map<String, dynamic>> options;

  /// The session ID for this request.
  final String sessionId;

  /// Details about the tool call requiring permission.
  final Map<String, dynamic> toolCall;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [RequestPermissionRequest].
  const RequestPermissionRequest({
    this.options = const [],
    required this.sessionId,
    required this.toolCall,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory RequestPermissionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'options', 'sessionId', 'toolCall', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return RequestPermissionRequest(
      options:
          (json['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          const [],
      sessionId: json['sessionId'] as String,
      toolCall: json['toolCall'] as Map<String, dynamic>,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'options': options,
    'sessionId': sessionId,
    'toolCall': toolCall,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to a permission request.
final class RequestPermissionResponse implements HasMeta {
  /// The user's decision on the permission request.
  final Map<String, dynamic> outcome;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [RequestPermissionResponse].
  const RequestPermissionResponse({
    required this.outcome,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory RequestPermissionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'outcome', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return RequestPermissionResponse(
      outcome: json['outcome'] as Map<String, dynamic>,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'outcome': outcome,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
