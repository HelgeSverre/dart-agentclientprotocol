import 'package:acp/src/schema/has_meta.dart';

// -- File System --

/// Request to read a text file (`fs/read_text_file`).
final class ReadTextFileRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// Path to the file.
  final String path;

  /// Optional starting line number.
  final int? line;

  /// Optional line count limit.
  final int? limit;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const ReadTextFileRequest({
    required this.sessionId,
    required this.path,
    this.line,
    this.limit,
    this.meta,
    this.extensionData,
  });

  factory ReadTextFileRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'path', 'line', 'limit', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ReadTextFileRequest(
      sessionId: json['sessionId'] as String,
      path: json['path'] as String,
      line: json['line'] as int?,
      limit: json['limit'] as int?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'path': path,
    if (line != null) 'line': line,
    if (limit != null) 'limit': limit,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `fs/read_text_file`.
final class ReadTextFileResponse implements HasMeta {
  /// The file content.
  final String content;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const ReadTextFileResponse({
    required this.content,
    this.meta,
    this.extensionData,
  });

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

  Map<String, dynamic> toJson() => {
    'content': content,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request to write a text file (`fs/write_text_file`).
final class WriteTextFileRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// Path to the file.
  final String path;

  /// The content to write.
  final String content;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const WriteTextFileRequest({
    required this.sessionId,
    required this.path,
    required this.content,
    this.meta,
    this.extensionData,
  });

  factory WriteTextFileRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'path', 'content', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return WriteTextFileRequest(
      sessionId: json['sessionId'] as String,
      path: json['path'] as String,
      content: json['content'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'path': path,
    'content': content,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `fs/write_text_file`.
final class WriteTextFileResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const WriteTextFileResponse({this.meta, this.extensionData});

  factory WriteTextFileResponse.fromJson(Map<String, dynamic> json) {
    final known = <String>{'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return WriteTextFileResponse(
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  Map<String, dynamic> toJson() => {
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

// -- Terminal --

/// Request to create a terminal (`terminal/create`).
final class CreateTerminalRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// The command to execute.
  final String command;

  /// Optional command arguments.
  final List<String>? args;

  /// Optional environment variables (raw JSON).
  final List<Map<String, dynamic>>? env;

  /// Optional working directory.
  final String? cwd;

  /// Optional output byte limit.
  final int? outputByteLimit;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const CreateTerminalRequest({
    required this.sessionId,
    required this.command,
    this.args,
    this.env,
    this.cwd,
    this.outputByteLimit,
    this.meta,
    this.extensionData,
  });

  factory CreateTerminalRequest.fromJson(Map<String, dynamic> json) {
    final known = {
      'sessionId',
      'command',
      'args',
      'env',
      'cwd',
      'outputByteLimit',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CreateTerminalRequest(
      sessionId: json['sessionId'] as String,
      command: json['command'] as String,
      args: (json['args'] as List<dynamic>?)?.cast<String>(),
      env: (json['env'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      cwd: json['cwd'] as String?,
      outputByteLimit: json['outputByteLimit'] as int?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'command': command,
    if (args != null) 'args': args,
    if (env != null) 'env': env,
    if (cwd != null) 'cwd': cwd,
    if (outputByteLimit != null) 'outputByteLimit': outputByteLimit,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `terminal/create`.
final class CreateTerminalResponse implements HasMeta {
  /// The unique terminal identifier.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const CreateTerminalResponse({
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

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

  Map<String, dynamic> toJson() => {
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request for terminal output (`terminal/output`).
final class TerminalOutputRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// The terminal ID.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const TerminalOutputRequest({
    required this.sessionId,
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

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

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `terminal/output`.
final class TerminalOutputResponse implements HasMeta {
  /// The terminal output.
  final String output;

  /// Whether the output was truncated.
  final bool truncated;

  /// Exit status if the process has exited (raw JSON).
  final Map<String, dynamic>? exitStatus;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const TerminalOutputResponse({
    required this.output,
    required this.truncated,
    this.exitStatus,
    this.meta,
    this.extensionData,
  });

  factory TerminalOutputResponse.fromJson(Map<String, dynamic> json) {
    final known = {'output', 'truncated', 'exitStatus', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return TerminalOutputResponse(
      output: json['output'] as String,
      truncated: json['truncated'] as bool,
      exitStatus: json['exitStatus'] as Map<String, dynamic>?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  Map<String, dynamic> toJson() => {
    'output': output,
    'truncated': truncated,
    if (exitStatus != null) 'exitStatus': exitStatus,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request to release a terminal (`terminal/release`).
final class ReleaseTerminalRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// The terminal ID.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const ReleaseTerminalRequest({
    required this.sessionId,
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

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

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request to kill a terminal command (`terminal/kill`).
final class KillTerminalCommandRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// The terminal ID.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const KillTerminalCommandRequest({
    required this.sessionId,
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

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

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request to wait for terminal exit (`terminal/wait_for_exit`).
final class WaitForTerminalExitRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// The terminal ID.
  final String terminalId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const WaitForTerminalExitRequest({
    required this.sessionId,
    required this.terminalId,
    this.meta,
    this.extensionData,
  });

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

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'terminalId': terminalId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `terminal/wait_for_exit`.
final class WaitForTerminalExitResponse implements HasMeta {
  /// Exit code, if available.
  final int? exitCode;

  /// Signal name, if the process was killed by a signal.
  final String? signal;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const WaitForTerminalExitResponse({
    this.exitCode,
    this.signal,
    this.meta,
    this.extensionData,
  });

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

  Map<String, dynamic> toJson() => {
    if (exitCode != null) 'exitCode': exitCode,
    if (signal != null) 'signal': signal,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

// -- Permission --

/// Request for user permission (`session/request_permission`).
final class RequestPermissionRequest implements HasMeta {
  /// The session ID.
  final String sessionId;

  /// The tool call requiring permission (raw JSON).
  final Map<String, dynamic> toolCall;

  /// Available permission options (raw JSON).
  final List<Map<String, dynamic>> options;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const RequestPermissionRequest({
    required this.sessionId,
    required this.toolCall,
    required this.options,
    this.meta,
    this.extensionData,
  });

  factory RequestPermissionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'toolCall', 'options', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return RequestPermissionRequest(
      sessionId: json['sessionId'] as String,
      toolCall: json['toolCall'] as Map<String, dynamic>,
      options: (json['options'] as List<dynamic>).cast<Map<String, dynamic>>(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'toolCall': toolCall,
    'options': options,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `session/request_permission`.
final class RequestPermissionResponse implements HasMeta {
  /// The user's decision (raw JSON with discriminator "outcome").
  final Map<String, dynamic> outcome;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const RequestPermissionResponse({
    required this.outcome,
    this.meta,
    this.extensionData,
  });

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

  Map<String, dynamic> toJson() => {
    'outcome': outcome,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
