import 'package:acp/src/schema/has_meta.dart';
import 'package:meta/meta.dart';

// -- session/list (unstable) --

/// Request parameters for the `session/list` method.
///
/// This is an unstable/experimental ACP method. Requires
/// `useUnstableProtocol: true` on the connection.
@experimental
final class ListSessionsRequest implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ListSessionsRequest].
  const ListSessionsRequest({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory ListSessionsRequest.fromJson(Map<String, dynamic> json) {
    final known = <String>{'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ListSessionsRequest(
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

/// Response to the `session/list` method.
@experimental
final class ListSessionsResponse implements HasMeta {
  /// The list of session summaries (raw JSON).
  final List<Map<String, dynamic>> sessions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ListSessionsResponse].
  const ListSessionsResponse({
    required this.sessions,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ListSessionsResponse.fromJson(Map<String, dynamic> json) {
    final known = {'sessions', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ListSessionsResponse(
      sessions:
          (json['sessions'] as List<dynamic>).cast<Map<String, dynamic>>(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessions': sessions,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

// -- session/fork (unstable) --

/// Request parameters for the `session/fork` method.
///
/// This is an unstable/experimental ACP method. Requires
/// `useUnstableProtocol: true` on the connection.
@experimental
final class ForkSessionRequest implements HasMeta {
  /// The session ID to fork.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ForkSessionRequest].
  const ForkSessionRequest({
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ForkSessionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ForkSessionRequest(
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

/// Response to the `session/fork` method.
@experimental
final class ForkSessionResponse implements HasMeta {
  /// The new forked session ID.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ForkSessionResponse].
  const ForkSessionResponse({
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ForkSessionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ForkSessionResponse(
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
