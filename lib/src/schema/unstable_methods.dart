// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.unstable.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/has_meta.dart';
import 'package:meta/meta.dart';

/// Notification sent when a suggestion is accepted.
@experimental
final class AcceptNesNotification implements HasMeta {
  /// The ID of the accepted suggestion.
  final String id;

  /// The session ID for this notification.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AcceptNesNotification].
  const AcceptNesNotification({
    required this.id,
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AcceptNesNotification.fromJson(Map<String, dynamic> json) {
    final known = {'id', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AcceptNesNotification(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Authentication-related capabilities supported by the agent.
@experimental
final class AgentAuthCapabilities implements HasMeta {
  /// Whether the agent supports the logout method.
  ///
  /// By supplying `{}` it means that the agent supports the logout method.
  final LogoutCapabilities? logout;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AgentAuthCapabilities].
  const AgentAuthCapabilities({this.logout, this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory AgentAuthCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'logout', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AgentAuthCapabilities(
      logout:
          json['logout'] is Map<String, dynamic>
              ? LogoutCapabilities.fromJson(
                json['logout'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (logout != null) 'logout': logout!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Authentication capabilities supported by the client.
///
/// Advertised during initialization to inform the agent which authentication
/// method types the client can handle. This governs opt-in types that require
/// additional client-side support.
@experimental
final class AuthCapabilities implements HasMeta {
  /// Whether the client supports `terminal` authentication methods.
  ///
  /// When `true`, the agent may include `terminal` entries in its authentication methods.
  final bool terminal;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AuthCapabilities].
  const AuthCapabilities({
    this.terminal = false,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AuthCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'terminal', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthCapabilities(
      terminal: json['terminal'] as bool? ?? false,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'terminal': terminal,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Describes a single environment variable for an [`AuthMethodEnvVar`] authentication method.
@experimental
final class AuthEnvVar implements HasMeta {
  /// Human-readable label for this variable, displayed in client UI.
  final String? label;

  /// The environment variable name (e.g. `"OPENAI_API_KEY"`).
  final String name;

  /// Whether this variable is optional.
  ///
  /// Defaults to `false`.
  final bool optional;

  /// Whether this value is a secret (e.g. API key, token).
  /// Clients should use a password-style input for secret vars.
  ///
  /// Defaults to `true`.
  final bool secret;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AuthEnvVar].
  const AuthEnvVar({
    this.label,
    required this.name,
    this.optional = false,
    this.secret = true,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AuthEnvVar.fromJson(Map<String, dynamic> json) {
    final known = {'label', 'name', 'optional', 'secret', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthEnvVar(
      label: json['label'] as String?,
      name: json['name'] as String,
      optional: json['optional'] as bool? ?? false,
      secret: json['secret'] as bool? ?? true,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (label != null) 'label': label,
    'name': name,
    'optional': optional,
    'secret': secret,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Environment variable authentication method.
///
/// The user provides credentials that the client passes to the agent as environment variables.
@experimental
final class AuthMethodEnvVar implements HasMeta {
  /// Optional description providing more details about this authentication method.
  final String? description;

  /// Unique identifier for this authentication method.
  final String id;

  /// Optional link to a page where the user can obtain their credentials.
  final String? link;

  /// Human-readable name of the authentication method.
  final String name;

  /// The environment variables the client should set.
  final List<AuthEnvVar> vars;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AuthMethodEnvVar].
  const AuthMethodEnvVar({
    this.description,
    required this.id,
    this.link,
    required this.name,
    this.vars = const [],
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AuthMethodEnvVar.fromJson(Map<String, dynamic> json) {
    final known = {'description', 'id', 'link', 'name', 'vars', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthMethodEnvVar(
      description: json['description'] as String?,
      id: json['id'] as String,
      link: json['link'] as String?,
      name: json['name'] as String,
      vars:
          (json['vars'] as List<dynamic>?)
              ?.map((e) => AuthEnvVar.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (description != null) 'description': description,
    'id': id,
    if (link != null) 'link': link,
    'name': name,
    'vars': vars.map((e) => e.toJson()).toList(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Terminal-based authentication method.
///
/// The client runs an interactive terminal for the user to authenticate via a TUI.
@experimental
final class AuthMethodTerminal implements HasMeta {
  /// Additional arguments to pass when running the agent binary for terminal auth.
  final List<String> args;

  /// Optional description providing more details about this authentication method.
  final String? description;

  /// Additional environment variables to set when running the agent binary for terminal auth.
  final Map<String, dynamic>? env;

  /// Unique identifier for this authentication method.
  final String id;

  /// Human-readable name of the authentication method.
  final String name;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AuthMethodTerminal].
  const AuthMethodTerminal({
    this.args = const [],
    this.description,
    this.env,
    required this.id,
    required this.name,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AuthMethodTerminal.fromJson(Map<String, dynamic> json) {
    final known = {'args', 'description', 'env', 'id', 'name', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthMethodTerminal(
      args: (json['args'] as List<dynamic>?)?.cast<String>() ?? const [],
      description: json['description'] as String?,
      env: json['env'] as Map<String, dynamic>?,
      id: json['id'] as String,
      name: json['name'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'args': args,
    if (description != null) 'description': description,
    if (env != null) 'env': env,
    'id': id,
    'name': name,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Schema for boolean properties in an elicitation form.
@experimental
final class BooleanPropertySchema {
  /// Default value.
  final bool? defaultValue;

  /// Human-readable description.
  final String? description;

  /// Optional title for the property.
  final String? title;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [BooleanPropertySchema].
  const BooleanPropertySchema({
    this.defaultValue,
    this.description,
    this.title,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory BooleanPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {'default', 'description', 'title'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return BooleanPropertySchema(
      defaultValue: json['default'] as bool?,
      description: json['description'] as String?,
      title: json['title'] as String?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    if (title != null) 'title': title,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Notification to cancel an ongoing request.
///
/// See protocol docs: [Cancellation](https://agentclientprotocol.com/protocol/cancellation)
@experimental
final class CancelRequestNotification implements HasMeta {
  /// The ID of the request to cancel.
  final String requestId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CancelRequestNotification].
  const CancelRequestNotification({
    required this.requestId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory CancelRequestNotification.fromJson(Map<String, dynamic> json) {
    final known = {'requestId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CancelRequestNotification(
      requestId: json['requestId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// NES capabilities advertised by the client during initialization.
@experimental
final class ClientNesCapabilities implements HasMeta {
  /// Whether the client supports the `jump` suggestion kind.
  final NesJumpCapabilities? jump;

  /// Whether the client supports the `rename` suggestion kind.
  final NesRenameCapabilities? rename;

  /// Whether the client supports the `searchAndReplace` suggestion kind.
  final NesSearchAndReplaceCapabilities? searchAndReplace;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ClientNesCapabilities].
  const ClientNesCapabilities({
    this.jump,
    this.rename,
    this.searchAndReplace,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ClientNesCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'jump', 'rename', 'searchAndReplace', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ClientNesCapabilities(
      jump:
          json['jump'] is Map<String, dynamic>
              ? NesJumpCapabilities.fromJson(
                json['jump'] as Map<String, dynamic>,
              )
              : null,
      rename:
          json['rename'] is Map<String, dynamic>
              ? NesRenameCapabilities.fromJson(
                json['rename'] as Map<String, dynamic>,
              )
              : null,
      searchAndReplace:
          json['searchAndReplace'] is Map<String, dynamic>
              ? NesSearchAndReplaceCapabilities.fromJson(
                json['searchAndReplace'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (jump != null) 'jump': jump!.toJson(),
    if (rename != null) 'rename': rename!.toJson(),
    if (searchAndReplace != null)
      'searchAndReplace': searchAndReplace!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request to close an NES session.
///
/// The agent **must** cancel any ongoing work related to the NES session
/// and then free up any resources associated with the session.
@experimental
final class CloseNesRequest implements HasMeta {
  /// The ID of the NES session to close.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CloseNesRequest].
  const CloseNesRequest({
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory CloseNesRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CloseNesRequest(
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

/// Response from closing an NES session.
@experimental
final class CloseNesResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CloseNesResponse].
  const CloseNesResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory CloseNesResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CloseNesResponse(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request parameters for closing an active session.
///
/// If supported, the agent **must** cancel any ongoing work related to the session
/// (treat it as if `session/cancel` was called) and then free up any resources
/// associated with the session.
///
/// Only available if the Agent supports the `sessionCapabilities.close` capability.
@experimental
final class CloseSessionRequest implements HasMeta {
  /// The ID of the session to close.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CloseSessionRequest].
  const CloseSessionRequest({
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory CloseSessionRequest.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CloseSessionRequest(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response from closing a session.
@experimental
final class CloseSessionResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CloseSessionResponse].
  const CloseSessionResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory CloseSessionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CloseSessionResponse(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Notification sent by the agent when a URL-based elicitation is complete.
@experimental
final class CompleteElicitationNotification implements HasMeta {
  /// The ID of the elicitation that completed.
  final Map<String, dynamic> elicitationId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [CompleteElicitationNotification].
  const CompleteElicitationNotification({
    required this.elicitationId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory CompleteElicitationNotification.fromJson(Map<String, dynamic> json) {
    final known = {'elicitationId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return CompleteElicitationNotification(
      elicitationId: json['elicitationId'] as Map<String, dynamic>,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'elicitationId': elicitationId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Cost information for a session.
@experimental
final class Cost {
  /// Total cumulative cost for session.
  final double amount;

  /// ISO 4217 currency code (e.g., "USD", "EUR").
  final String currency;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [Cost].
  const Cost({
    required this.amount,
    required this.currency,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory Cost.fromJson(Map<String, dynamic> json) {
    final known = {'amount', 'currency'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Cost(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'amount': amount,
    'currency': currency,
    if (extensionData != null) ...extensionData!,
  };
}

// -- Elicitation (unstable) --

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request from the agent to elicit structured user input.
///
/// The agent sends this to the client to request information from the user,
/// either via a form or by directing them to a URL.
/// Elicitations are tied to a session (optionally a tool call) or a request.
@experimental
sealed class CreateElicitationRequest implements HasMeta {
  const CreateElicitationRequest();

  /// Deserializes a [CreateElicitationRequest] from JSON.
  ///
  /// Switches on the `mode` discriminator field.
  factory CreateElicitationRequest.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'] as String?;
    if (mode == null) {
      return UnknownCreateElicitationRequest(rawJson: json);
    }
    return switch (mode) {
      'form' => Form.fromJson(json),
      'url' => Url.fromJson(json),
      _ => UnknownCreateElicitationRequest(
        modeType: mode,
        rawJson: json,
        meta: json['_meta'] as Map<String, Object?>?,
      ),
    };
  }

  /// Serializes this createElicitationRequest to JSON.
  Map<String, dynamic> toJson();
}

/// Form-based elicitation where the client renders a form from the provided schema.
@experimental
final class Form extends CreateElicitationRequest {
  /// A JSON Schema describing the form fields to present to the user.
  final ElicitationSchema requestedSchema;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [Form].
  const Form({required this.requestedSchema, this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory Form.fromJson(Map<String, dynamic> json) {
    final known = {'requestedSchema', '_meta', 'mode'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Form(
      requestedSchema: ElicitationSchema.fromJson(
        json['requestedSchema'] as Map<String, dynamic>,
      ),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'mode': 'form',
    'requestedSchema': requestedSchema.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// URL-based elicitation where the client directs the user to a URL.
@experimental
final class Url extends CreateElicitationRequest {
  /// The unique identifier for this elicitation.
  final Map<String, dynamic> elicitationId;

  /// The URL to direct the user to.
  final String url;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [Url].
  const Url({
    required this.elicitationId,
    required this.url,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory Url.fromJson(Map<String, dynamic> json) {
    final known = {'elicitationId', 'url', '_meta', 'mode'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Url(
      elicitationId: json['elicitationId'] as Map<String, dynamic>,
      url: json['url'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'mode': 'url',
    'elicitationId': elicitationId,
    'url': url,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

@experimental
/// A createElicitationRequest with an unknown mode, preserved for forward compatibility.
final class UnknownCreateElicitationRequest extends CreateElicitationRequest {
  /// The unknown discriminator value.
  final String? modeType;

  /// The raw JSON object, preserved as-is.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [UnknownCreateElicitationRequest].
  const UnknownCreateElicitationRequest({
    this.modeType,
    required this.rawJson,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response from the client to an elicitation request.
@experimental
sealed class CreateElicitationResponse implements HasMeta {
  const CreateElicitationResponse();

  /// Deserializes a [CreateElicitationResponse] from JSON.
  ///
  /// Switches on the `action` discriminator field.
  factory CreateElicitationResponse.fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String?;
    if (action == null) {
      return UnknownCreateElicitationResponse(rawJson: json);
    }
    return switch (action) {
      'accept' => Accept.fromJson(json),
      'decline' => Decline.fromJson(json),
      'cancel' => Cancel.fromJson(json),
      _ => UnknownCreateElicitationResponse(
        actionType: action,
        rawJson: json,
        meta: json['_meta'] as Map<String, Object?>?,
      ),
    };
  }

  /// Serializes this createElicitationResponse to JSON.
  Map<String, dynamic> toJson();
}

/// The user accepted and provided content.
@experimental
final class Accept extends CreateElicitationResponse {
  /// The user-provided content, if any, as an object matching the requested schema.
  final Map<String, dynamic>? content;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [Accept].
  const Accept({this.content, this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory Accept.fromJson(Map<String, dynamic> json) {
    final known = {'content', '_meta', 'action'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Accept(
      content: json['content'] as Map<String, dynamic>?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'action': 'accept',
    if (content != null) 'content': content,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// The user declined the elicitation.
@experimental
final class Decline extends CreateElicitationResponse {
  /// The raw JSON payload.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates a [Decline].
  const Decline({required this.rawJson, this.meta});

  /// Deserializes from JSON.
  factory Decline.fromJson(Map<String, dynamic> json) {
    return Decline(rawJson: json, meta: json['_meta'] as Map<String, Object?>?);
  }

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// The elicitation was cancelled.
@experimental
final class Cancel extends CreateElicitationResponse {
  /// The raw JSON payload.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates a [Cancel].
  const Cancel({required this.rawJson, this.meta});

  /// Deserializes from JSON.
  factory Cancel.fromJson(Map<String, dynamic> json) {
    return Cancel(rawJson: json, meta: json['_meta'] as Map<String, Object?>?);
  }

  @override
  Map<String, dynamic> toJson() => rawJson;
}

@experimental
/// A createElicitationResponse with an unknown action, preserved for forward compatibility.
final class UnknownCreateElicitationResponse extends CreateElicitationResponse {
  /// The unknown discriminator value.
  final String? actionType;

  /// The raw JSON object, preserved as-is.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [UnknownCreateElicitationResponse].
  const UnknownCreateElicitationResponse({
    this.actionType,
    required this.rawJson,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// Notification sent when a file is edited.
@experimental
final class DidChangeDocumentNotification implements HasMeta {
  /// The content changes.
  final List<TextDocumentContentChangeEvent> contentChanges;

  /// The session ID for this notification.
  final String sessionId;

  /// The URI of the changed document.
  final String uri;

  /// The new version number of the document.
  final int version;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [DidChangeDocumentNotification].
  const DidChangeDocumentNotification({
    this.contentChanges = const [],
    required this.sessionId,
    required this.uri,
    required this.version,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory DidChangeDocumentNotification.fromJson(Map<String, dynamic> json) {
    final known = {'contentChanges', 'sessionId', 'uri', 'version', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return DidChangeDocumentNotification(
      contentChanges:
          (json['contentChanges'] as List<dynamic>?)
              ?.map(
                (e) => TextDocumentContentChangeEvent.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      sessionId: json['sessionId'] as String,
      uri: json['uri'] as String,
      version: json['version'] as int,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'contentChanges': contentChanges.map((e) => e.toJson()).toList(),
    'sessionId': sessionId,
    'uri': uri,
    'version': version,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Notification sent when a file is closed.
@experimental
final class DidCloseDocumentNotification implements HasMeta {
  /// The session ID for this notification.
  final String sessionId;

  /// The URI of the closed document.
  final String uri;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [DidCloseDocumentNotification].
  const DidCloseDocumentNotification({
    required this.sessionId,
    required this.uri,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory DidCloseDocumentNotification.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'uri', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return DidCloseDocumentNotification(
      sessionId: json['sessionId'] as String,
      uri: json['uri'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'uri': uri,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Notification sent when a file becomes the active editor tab.
@experimental
final class DidFocusDocumentNotification implements HasMeta {
  /// The current cursor position.
  final Position position;

  /// The session ID for this notification.
  final String sessionId;

  /// The URI of the focused document.
  final String uri;

  /// The version number of the document.
  final int version;

  /// The portion of the file currently visible in the editor viewport.
  final Range visibleRange;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [DidFocusDocumentNotification].
  const DidFocusDocumentNotification({
    required this.position,
    required this.sessionId,
    required this.uri,
    required this.version,
    required this.visibleRange,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory DidFocusDocumentNotification.fromJson(Map<String, dynamic> json) {
    final known = {
      'position',
      'sessionId',
      'uri',
      'version',
      'visibleRange',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return DidFocusDocumentNotification(
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      sessionId: json['sessionId'] as String,
      uri: json['uri'] as String,
      version: json['version'] as int,
      visibleRange: Range.fromJson(
        json['visibleRange'] as Map<String, dynamic>,
      ),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'position': position.toJson(),
    'sessionId': sessionId,
    'uri': uri,
    'version': version,
    'visibleRange': visibleRange.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

// -- Documents (unstable) --

/// Notification sent when a file is opened in the editor.
@experimental
final class DidOpenDocumentNotification implements HasMeta {
  /// The language identifier of the document (e.g., "rust", "python").
  final String languageId;

  /// The session ID for this notification.
  final String sessionId;

  /// The full text content of the document.
  final String text;

  /// The URI of the opened document.
  final String uri;

  /// The version number of the document.
  final int version;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [DidOpenDocumentNotification].
  const DidOpenDocumentNotification({
    required this.languageId,
    required this.sessionId,
    required this.text,
    required this.uri,
    required this.version,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory DidOpenDocumentNotification.fromJson(Map<String, dynamic> json) {
    final known = {
      'languageId',
      'sessionId',
      'text',
      'uri',
      'version',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return DidOpenDocumentNotification(
      languageId: json['languageId'] as String,
      sessionId: json['sessionId'] as String,
      text: json['text'] as String,
      uri: json['uri'] as String,
      version: json['version'] as int,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'languageId': languageId,
    'sessionId': sessionId,
    'text': text,
    'uri': uri,
    'version': version,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Notification sent when a file is saved.
@experimental
final class DidSaveDocumentNotification implements HasMeta {
  /// The session ID for this notification.
  final String sessionId;

  /// The URI of the saved document.
  final String uri;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [DidSaveDocumentNotification].
  const DidSaveDocumentNotification({
    required this.sessionId,
    required this.uri,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory DidSaveDocumentNotification.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'uri', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return DidSaveDocumentNotification(
      sessionId: json['sessionId'] as String,
      uri: json['uri'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'uri': uri,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request parameters for `providers/disable`.
@experimental
final class DisableProvidersRequest implements HasMeta {
  /// Provider id to disable.
  final String id;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [DisableProvidersRequest].
  const DisableProvidersRequest({
    required this.id,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory DisableProvidersRequest.fromJson(Map<String, dynamic> json) {
    final known = {'id', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return DisableProvidersRequest(
      id: json['id'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response to `providers/disable`.
@experimental
final class DisableProvidersResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [DisableProvidersResponse].
  const DisableProvidersResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory DisableProvidersResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return DisableProvidersResponse(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// The user accepted the elicitation and provided content.
@experimental
final class ElicitationAcceptAction {
  /// The user-provided content, if any, as an object matching the requested schema.
  final Map<String, dynamic>? content;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ElicitationAcceptAction].
  const ElicitationAcceptAction({this.content, this.extensionData});

  /// Deserializes from JSON.
  factory ElicitationAcceptAction.fromJson(Map<String, dynamic> json) {
    final known = {'content'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ElicitationAcceptAction(
      content: json['content'] as Map<String, dynamic>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (content != null) 'content': content,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Elicitation capabilities supported by the client.
@experimental
final class ElicitationCapabilities implements HasMeta {
  /// Whether the client supports form-based elicitation.
  final ElicitationFormCapabilities? form;

  /// Whether the client supports URL-based elicitation.
  final ElicitationUrlCapabilities? url;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ElicitationCapabilities].
  const ElicitationCapabilities({
    this.form,
    this.url,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ElicitationCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'form', 'url', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ElicitationCapabilities(
      form:
          json['form'] is Map<String, dynamic>
              ? ElicitationFormCapabilities.fromJson(
                json['form'] as Map<String, dynamic>,
              )
              : null,
      url:
          json['url'] is Map<String, dynamic>
              ? ElicitationUrlCapabilities.fromJson(
                json['url'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (form != null) 'form': form!.toJson(),
    if (url != null) 'url': url!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Form-based elicitation capabilities.
@experimental
final class ElicitationFormCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ElicitationFormCapabilities].
  const ElicitationFormCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory ElicitationFormCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ElicitationFormCapabilities(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Form-based elicitation mode where the client renders a form from the provided schema.
@experimental
final class ElicitationFormMode {
  /// A JSON Schema describing the form fields to present to the user.
  final ElicitationSchema requestedSchema;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ElicitationFormMode].
  const ElicitationFormMode({
    required this.requestedSchema,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ElicitationFormMode.fromJson(Map<String, dynamic> json) {
    final known = {'requestedSchema'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ElicitationFormMode(
      requestedSchema: ElicitationSchema.fromJson(
        json['requestedSchema'] as Map<String, dynamic>,
      ),
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'requestedSchema': requestedSchema.toJson(),
    if (extensionData != null) ...extensionData!,
  };
}

/// Property schema for elicitation form fields.
///
/// Each variant corresponds to a JSON Schema `"type"` value.
/// Single-select enums use the `String` variant with `enum` or `oneOf` set.
/// Multi-select enums use the `Array` variant.
@experimental
sealed class ElicitationPropertySchema implements HasMeta {
  const ElicitationPropertySchema();

  /// Deserializes a [ElicitationPropertySchema] from JSON.
  ///
  /// Switches on the `type` discriminator field.
  factory ElicitationPropertySchema.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      return UnknownElicitationPropertySchema(rawJson: json);
    }
    return switch (type) {
      'string' => StringElicitationPropertySchema.fromJson(json),
      'number' => NumberElicitationPropertySchema.fromJson(json),
      'integer' => IntegerElicitationPropertySchema.fromJson(json),
      'boolean' => BooleanElicitationPropertySchema.fromJson(json),
      'array' => ArrayElicitationPropertySchema.fromJson(json),
      _ => UnknownElicitationPropertySchema(
        type: type,
        rawJson: json,
        meta: json['_meta'] as Map<String, Object?>?,
      ),
    };
  }

  /// Serializes this elicitationPropertySchema to JSON.
  Map<String, dynamic> toJson();
}

/// String property (or single-select enum when `enum`/`oneOf` is set).
@experimental
final class StringElicitationPropertySchema extends ElicitationPropertySchema {
  /// Default value.
  final String? defaultValue;

  /// Human-readable description.
  final String? description;

  /// Enum values for untitled single-select enums.
  final List<String>? enumValues;

  /// String format.
  final StringFormat? format;

  /// Maximum string length.
  final int? maxLength;

  /// Minimum string length.
  final int? minLength;

  /// Titled enum options for titled single-select enums.
  final List<EnumOption>? oneOf;

  /// Pattern the string must match.
  final String? pattern;

  /// Optional title for the property.
  final String? title;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [StringElicitationPropertySchema].
  const StringElicitationPropertySchema({
    this.defaultValue,
    this.description,
    this.enumValues,
    this.format,
    this.maxLength,
    this.minLength,
    this.oneOf,
    this.pattern,
    this.title,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory StringElicitationPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {
      'default',
      'description',
      'enum',
      'format',
      'maxLength',
      'minLength',
      'oneOf',
      'pattern',
      'title',
      '_meta',
      'type',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return StringElicitationPropertySchema(
      defaultValue: json['default'] as String?,
      description: json['description'] as String?,
      enumValues: (json['enum'] as List<dynamic>?)?.cast<String>(),
      format:
          json['format'] == null
              ? null
              : StringFormat.fromString(json['format'] as String),
      maxLength: json['maxLength'] as int?,
      minLength: json['minLength'] as int?,
      oneOf:
          (json['oneOf'] as List<dynamic>?)
              ?.map((e) => EnumOption.fromJson(e as Map<String, dynamic>))
              .toList(),
      pattern: json['pattern'] as String?,
      title: json['title'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'string',
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    if (enumValues != null) 'enum': enumValues,
    if (format != null) 'format': format!.value,
    if (maxLength != null) 'maxLength': maxLength,
    if (minLength != null) 'minLength': minLength,
    if (oneOf != null) 'oneOf': oneOf!.map((e) => e.toJson()).toList(),
    if (pattern != null) 'pattern': pattern,
    if (title != null) 'title': title,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Number (floating-point) property.
@experimental
final class NumberElicitationPropertySchema extends ElicitationPropertySchema {
  /// Default value.
  final double? defaultValue;

  /// Human-readable description.
  final String? description;

  /// Maximum value (inclusive).
  final double? maximum;

  /// Minimum value (inclusive).
  final double? minimum;

  /// Optional title for the property.
  final String? title;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NumberElicitationPropertySchema].
  const NumberElicitationPropertySchema({
    this.defaultValue,
    this.description,
    this.maximum,
    this.minimum,
    this.title,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NumberElicitationPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {
      'default',
      'description',
      'maximum',
      'minimum',
      'title',
      '_meta',
      'type',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NumberElicitationPropertySchema(
      defaultValue: (json['default'] as num?)?.toDouble(),
      description: json['description'] as String?,
      maximum: (json['maximum'] as num?)?.toDouble(),
      minimum: (json['minimum'] as num?)?.toDouble(),
      title: json['title'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'number',
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    if (maximum != null) 'maximum': maximum,
    if (minimum != null) 'minimum': minimum,
    if (title != null) 'title': title,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Integer property.
@experimental
final class IntegerElicitationPropertySchema extends ElicitationPropertySchema {
  /// Default value.
  final int? defaultValue;

  /// Human-readable description.
  final String? description;

  /// Maximum value (inclusive).
  final int? maximum;

  /// Minimum value (inclusive).
  final int? minimum;

  /// Optional title for the property.
  final String? title;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [IntegerElicitationPropertySchema].
  const IntegerElicitationPropertySchema({
    this.defaultValue,
    this.description,
    this.maximum,
    this.minimum,
    this.title,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory IntegerElicitationPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {
      'default',
      'description',
      'maximum',
      'minimum',
      'title',
      '_meta',
      'type',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return IntegerElicitationPropertySchema(
      defaultValue: json['default'] as int?,
      description: json['description'] as String?,
      maximum: json['maximum'] as int?,
      minimum: json['minimum'] as int?,
      title: json['title'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'integer',
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    if (maximum != null) 'maximum': maximum,
    if (minimum != null) 'minimum': minimum,
    if (title != null) 'title': title,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Boolean property.
@experimental
final class BooleanElicitationPropertySchema extends ElicitationPropertySchema {
  /// Default value.
  final bool? defaultValue;

  /// Human-readable description.
  final String? description;

  /// Optional title for the property.
  final String? title;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [BooleanElicitationPropertySchema].
  const BooleanElicitationPropertySchema({
    this.defaultValue,
    this.description,
    this.title,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory BooleanElicitationPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {'default', 'description', 'title', '_meta', 'type'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return BooleanElicitationPropertySchema(
      defaultValue: json['default'] as bool?,
      description: json['description'] as String?,
      title: json['title'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'boolean',
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    if (title != null) 'title': title,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Multi-select array property.
@experimental
final class ArrayElicitationPropertySchema extends ElicitationPropertySchema {
  /// Default selected values.
  final List<String>? defaultValue;

  /// Human-readable description.
  final String? description;

  /// The items definition describing allowed values.
  final Map<String, dynamic> items;

  /// Maximum number of items to select.
  final int? maxItems;

  /// Minimum number of items to select.
  final int? minItems;

  /// Optional title for the property.
  final String? title;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ArrayElicitationPropertySchema].
  const ArrayElicitationPropertySchema({
    this.defaultValue,
    this.description,
    required this.items,
    this.maxItems,
    this.minItems,
    this.title,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ArrayElicitationPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {
      'default',
      'description',
      'items',
      'maxItems',
      'minItems',
      'title',
      '_meta',
      'type',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ArrayElicitationPropertySchema(
      defaultValue: (json['default'] as List<dynamic>?)?.cast<String>(),
      description: json['description'] as String?,
      items: json['items'] as Map<String, dynamic>,
      maxItems: json['maxItems'] as int?,
      minItems: json['minItems'] as int?,
      title: json['title'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'array',
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    'items': items,
    if (maxItems != null) 'maxItems': maxItems,
    if (minItems != null) 'minItems': minItems,
    if (title != null) 'title': title,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

@experimental
/// A elicitationPropertySchema with an unknown type, preserved for forward compatibility.
final class UnknownElicitationPropertySchema extends ElicitationPropertySchema {
  /// The unknown discriminator value.
  final String? type;

  /// The raw JSON object, preserved as-is.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [UnknownElicitationPropertySchema].
  const UnknownElicitationPropertySchema({
    this.type,
    required this.rawJson,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request-scoped elicitation, tied to a specific JSON-RPC request outside of a session
/// (e.g., during auth/configuration phases before any session is started).
@experimental
final class ElicitationRequestScope {
  /// The request this elicitation is tied to.
  final String requestId;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ElicitationRequestScope].
  const ElicitationRequestScope({required this.requestId, this.extensionData});

  /// Deserializes from JSON.
  factory ElicitationRequestScope.fromJson(Map<String, dynamic> json) {
    final known = {'requestId'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ElicitationRequestScope(
      requestId: json['requestId'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    if (extensionData != null) ...extensionData!,
  };
}

/// Type-safe elicitation schema for requesting structured user input.
///
/// This represents a JSON Schema object with primitive-typed properties,
/// as required by the elicitation specification.
@experimental
final class ElicitationSchema {
  /// Optional description of what this schema represents.
  final String? description;

  /// Property definitions (must be primitive types).
  final Map<String, dynamic>? properties;

  /// List of required property names.
  final List<String>? required;

  /// Optional title for the schema.
  final String? title;

  /// Type discriminator. Always `"object"`.
  final ElicitationSchemaType? type;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ElicitationSchema].
  const ElicitationSchema({
    this.description,
    this.properties,
    this.required,
    this.title,
    this.type = ElicitationSchemaType.object,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ElicitationSchema.fromJson(Map<String, dynamic> json) {
    final known = {'description', 'properties', 'required', 'title', 'type'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ElicitationSchema(
      description: json['description'] as String?,
      properties: json['properties'] as Map<String, dynamic>?,
      required: (json['required'] as List<dynamic>?)?.cast<String>(),
      title: json['title'] as String?,
      type:
          json['type'] == null
              ? null
              : ElicitationSchemaType.fromString(json['type'] as String),
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (description != null) 'description': description,
    if (properties != null) 'properties': properties,
    if (required != null) 'required': required,
    if (title != null) 'title': title,
    if (type != null) 'type': type!.value,
    if (extensionData != null) ...extensionData!,
  };
}

/// Type discriminator for elicitation schemas.
@experimental
enum ElicitationSchemaType {
  /// Object schema type.
  object('object');

  /// The wire-format string value.
  final String value;

  const ElicitationSchemaType(this.value);

  /// Parses a [ElicitationSchemaType] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static ElicitationSchemaType? fromString(String value) {
    for (final v in values) {
      if (v.value == value) return v;
    }
    return null;
  }
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Session-scoped elicitation, optionally tied to a specific tool call.
///
/// When `tool_call_id` is set, the elicitation is tied to a specific tool call.
/// This is useful when an agent receives an elicitation from an MCP server
/// during a tool call and needs to redirect it to the user.
@experimental
final class ElicitationSessionScope {
  /// The session this elicitation is tied to.
  final String sessionId;

  /// Optional tool call within the session.
  final String? toolCallId;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ElicitationSessionScope].
  const ElicitationSessionScope({
    required this.sessionId,
    this.toolCallId,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ElicitationSessionScope.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', 'toolCallId'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ElicitationSessionScope(
      sessionId: json['sessionId'] as String,
      toolCallId: json['toolCallId'] as String?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    if (toolCallId != null) 'toolCallId': toolCallId,
    if (extensionData != null) ...extensionData!,
  };
}

/// Items definition for untitled multi-select enum properties.
@experimental
enum ElicitationStringType {
  /// String schema type.
  string('string');

  /// The wire-format string value.
  final String value;

  const ElicitationStringType(this.value);

  /// Parses a [ElicitationStringType] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static ElicitationStringType? fromString(String value) {
    for (final v in values) {
      if (v.value == value) return v;
    }
    return null;
  }
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// URL-based elicitation capabilities.
@experimental
final class ElicitationUrlCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ElicitationUrlCapabilities].
  const ElicitationUrlCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory ElicitationUrlCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ElicitationUrlCapabilities(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// URL-based elicitation mode where the client directs the user to a URL.
@experimental
final class ElicitationUrlMode {
  /// The unique identifier for this elicitation.
  final Map<String, dynamic> elicitationId;

  /// The URL to direct the user to.
  final String url;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ElicitationUrlMode].
  const ElicitationUrlMode({
    required this.elicitationId,
    required this.url,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ElicitationUrlMode.fromJson(Map<String, dynamic> json) {
    final known = {'elicitationId', 'url'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ElicitationUrlMode(
      elicitationId: json['elicitationId'] as Map<String, dynamic>,
      url: json['url'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'elicitationId': elicitationId,
    'url': url,
    if (extensionData != null) ...extensionData!,
  };
}

/// A titled enum option with a const value and human-readable title.
@experimental
final class EnumOption {
  /// The constant value for this option.
  final String constValue;

  /// Human-readable title for this option.
  final String title;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [EnumOption].
  const EnumOption({
    required this.constValue,
    required this.title,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory EnumOption.fromJson(Map<String, dynamic> json) {
    final known = {'const', 'title'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return EnumOption(
      constValue: json['const'] as String,
      title: json['title'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'const': constValue,
    'title': title,
    if (extensionData != null) ...extensionData!,
  };
}

// -- Sessions (unstable) --

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
@experimental
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response from forking an existing session.
@experimental
final class ForkSessionResponse implements HasMeta {
  /// Initial session configuration options if supported by the Agent.
  final List<Map<String, dynamic>>? configOptions;

  /// **UNSTABLE**
  ///
  /// This capability is not part of the spec yet, and may be removed or changed at any point.
  ///
  /// Initial model state if supported by the Agent
  final SessionModelState? models;

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
      models:
          json['models'] is Map<String, dynamic>
              ? SessionModelState.fromJson(
                json['models'] as Map<String, dynamic>,
              )
              : null,
      modes: json['modes'] as Map<String, dynamic>?,
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (configOptions != null) 'configOptions': configOptions,
    if (models != null) 'models': models!.toJson(),
    if (modes != null) 'modes': modes,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Schema for integer properties in an elicitation form.
@experimental
final class IntegerPropertySchema {
  /// Default value.
  final int? defaultValue;

  /// Human-readable description.
  final String? description;

  /// Maximum value (inclusive).
  final int? maximum;

  /// Minimum value (inclusive).
  final int? minimum;

  /// Optional title for the property.
  final String? title;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [IntegerPropertySchema].
  const IntegerPropertySchema({
    this.defaultValue,
    this.description,
    this.maximum,
    this.minimum,
    this.title,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory IntegerPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {'default', 'description', 'maximum', 'minimum', 'title'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return IntegerPropertySchema(
      defaultValue: json['default'] as int?,
      description: json['description'] as String?,
      maximum: json['maximum'] as int?,
      minimum: json['minimum'] as int?,
      title: json['title'] as String?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    if (maximum != null) 'maximum': maximum,
    if (minimum != null) 'minimum': minimum,
    if (title != null) 'title': title,
    if (extensionData != null) ...extensionData!,
  };
}

// -- Providers (unstable) --

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request parameters for `providers/list`.
@experimental
final class ListProvidersRequest implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ListProvidersRequest].
  const ListProvidersRequest({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory ListProvidersRequest.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ListProvidersRequest(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response to `providers/list`.
@experimental
final class ListProvidersResponse implements HasMeta {
  /// Configurable providers with current routing info suitable for UI display.
  final List<ProviderInfo> providers;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ListProvidersResponse].
  const ListProvidersResponse({
    this.providers = const [],
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ListProvidersResponse.fromJson(Map<String, dynamic> json) {
    final known = {'providers', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ListProvidersResponse(
      providers:
          (json['providers'] as List<dynamic>?)
              ?.map((e) => ProviderInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'providers': providers.map((e) => e.toJson()).toList(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Logout capabilities supported by the agent.
///
/// By supplying `{}` it means that the agent supports the logout method.
@experimental
final class LogoutCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [LogoutCapabilities].
  const LogoutCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory LogoutCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return LogoutCapabilities(
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

// -- Auth (unstable) --

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request parameters for the logout method.
///
/// Terminates the current authenticated session.
@experimental
final class LogoutRequest implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [LogoutRequest].
  const LogoutRequest({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory LogoutRequest.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return LogoutRequest(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response to the `logout` method.
@experimental
final class LogoutResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [LogoutResponse].
  const LogoutResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return LogoutResponse(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Information about a selectable model.
@experimental
final class ModelInfo implements HasMeta {
  /// Optional description of the model.
  final String? description;

  /// Unique identifier for the model.
  final Map<String, dynamic> modelId;

  /// Human-readable name of the model.
  final String name;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ModelInfo].
  const ModelInfo({
    this.description,
    required this.modelId,
    required this.name,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    final known = {'description', 'modelId', 'name', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ModelInfo(
      description: json['description'] as String?,
      modelId: json['modelId'] as Map<String, dynamic>,
      name: json['name'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (description != null) 'description': description,
    'modelId': modelId,
    'name': name,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Schema for multi-select (array) properties in an elicitation form.
@experimental
final class MultiSelectPropertySchema {
  /// Default selected values.
  final List<String>? defaultValue;

  /// Human-readable description.
  final String? description;

  /// The items definition describing allowed values.
  final Map<String, dynamic> items;

  /// Maximum number of items to select.
  final int? maxItems;

  /// Minimum number of items to select.
  final int? minItems;

  /// Optional title for the property.
  final String? title;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [MultiSelectPropertySchema].
  const MultiSelectPropertySchema({
    this.defaultValue,
    this.description,
    required this.items,
    this.maxItems,
    this.minItems,
    this.title,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory MultiSelectPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {
      'default',
      'description',
      'items',
      'maxItems',
      'minItems',
      'title',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return MultiSelectPropertySchema(
      defaultValue: (json['default'] as List<dynamic>?)?.cast<String>(),
      description: json['description'] as String?,
      items: json['items'] as Map<String, dynamic>,
      maxItems: json['maxItems'] as int?,
      minItems: json['minItems'] as int?,
      title: json['title'] as String?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    'items': items,
    if (maxItems != null) 'maxItems': maxItems,
    if (minItems != null) 'minItems': minItems,
    if (title != null) 'title': title,
    if (extensionData != null) ...extensionData!,
  };
}

/// NES capabilities advertised by the agent during initialization.
@experimental
final class NesCapabilities implements HasMeta {
  /// Context the agent wants attached to each suggestion request.
  final NesContextCapabilities? context;

  /// Events the agent wants to receive.
  final NesEventCapabilities? events;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesCapabilities].
  const NesCapabilities({
    this.context,
    this.events,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'context', 'events', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesCapabilities(
      context:
          json['context'] is Map<String, dynamic>
              ? NesContextCapabilities.fromJson(
                json['context'] as Map<String, dynamic>,
              )
              : null,
      events:
          json['events'] is Map<String, dynamic>
              ? NesEventCapabilities.fromJson(
                json['events'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (context != null) 'context': context!.toJson(),
    if (events != null) 'events': events!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Context capabilities the agent wants attached to each suggestion request.
@experimental
final class NesContextCapabilities implements HasMeta {
  /// Whether the agent wants diagnostics context.
  final NesDiagnosticsCapabilities? diagnostics;

  /// Whether the agent wants edit history context.
  final NesEditHistoryCapabilities? editHistory;

  /// Whether the agent wants open files context.
  final NesOpenFilesCapabilities? openFiles;

  /// Whether the agent wants recent files context.
  final NesRecentFilesCapabilities? recentFiles;

  /// Whether the agent wants related snippets context.
  final NesRelatedSnippetsCapabilities? relatedSnippets;

  /// Whether the agent wants user actions context.
  final NesUserActionsCapabilities? userActions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesContextCapabilities].
  const NesContextCapabilities({
    this.diagnostics,
    this.editHistory,
    this.openFiles,
    this.recentFiles,
    this.relatedSnippets,
    this.userActions,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesContextCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {
      'diagnostics',
      'editHistory',
      'openFiles',
      'recentFiles',
      'relatedSnippets',
      'userActions',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesContextCapabilities(
      diagnostics:
          json['diagnostics'] is Map<String, dynamic>
              ? NesDiagnosticsCapabilities.fromJson(
                json['diagnostics'] as Map<String, dynamic>,
              )
              : null,
      editHistory:
          json['editHistory'] is Map<String, dynamic>
              ? NesEditHistoryCapabilities.fromJson(
                json['editHistory'] as Map<String, dynamic>,
              )
              : null,
      openFiles:
          json['openFiles'] is Map<String, dynamic>
              ? NesOpenFilesCapabilities.fromJson(
                json['openFiles'] as Map<String, dynamic>,
              )
              : null,
      recentFiles:
          json['recentFiles'] is Map<String, dynamic>
              ? NesRecentFilesCapabilities.fromJson(
                json['recentFiles'] as Map<String, dynamic>,
              )
              : null,
      relatedSnippets:
          json['relatedSnippets'] is Map<String, dynamic>
              ? NesRelatedSnippetsCapabilities.fromJson(
                json['relatedSnippets'] as Map<String, dynamic>,
              )
              : null,
      userActions:
          json['userActions'] is Map<String, dynamic>
              ? NesUserActionsCapabilities.fromJson(
                json['userActions'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (diagnostics != null) 'diagnostics': diagnostics!.toJson(),
    if (editHistory != null) 'editHistory': editHistory!.toJson(),
    if (openFiles != null) 'openFiles': openFiles!.toJson(),
    if (recentFiles != null) 'recentFiles': recentFiles!.toJson(),
    if (relatedSnippets != null) 'relatedSnippets': relatedSnippets!.toJson(),
    if (userActions != null) 'userActions': userActions!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A diagnostic (error, warning, etc.).
@experimental
final class NesDiagnostic {
  /// The diagnostic message.
  final String message;

  /// The range of the diagnostic.
  final Range range;

  /// The severity of the diagnostic.
  final NesDiagnosticSeverity? severity;

  /// The URI of the file containing the diagnostic.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesDiagnostic].
  const NesDiagnostic({
    required this.message,
    required this.range,
    required this.severity,
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesDiagnostic.fromJson(Map<String, dynamic> json) {
    final known = {'message', 'range', 'severity', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesDiagnostic(
      message: json['message'] as String,
      range: Range.fromJson(json['range'] as Map<String, dynamic>),
      severity:
          json['severity'] == null
              ? null
              : NesDiagnosticSeverity.fromString(json['severity'] as String),
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'message': message,
    'range': range.toJson(),
    if (severity != null) 'severity': severity!.value,
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}

/// Severity of a diagnostic.
@experimental
enum NesDiagnosticSeverity {
  /// An error.
  error('error'),

  /// A warning.
  warning('warning'),

  /// An informational message.
  information('information'),

  /// A hint.
  hint('hint');

  /// The wire-format string value.
  final String value;

  const NesDiagnosticSeverity(this.value);

  /// Parses a [NesDiagnosticSeverity] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static NesDiagnosticSeverity? fromString(String value) {
    for (final v in values) {
      if (v.value == value) return v;
    }
    return null;
  }
}

/// Capabilities for diagnostics context.
@experimental
final class NesDiagnosticsCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesDiagnosticsCapabilities].
  const NesDiagnosticsCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesDiagnosticsCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesDiagnosticsCapabilities(
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

/// Capabilities for `document/didChange` events.
@experimental
final class NesDocumentDidChangeCapabilities implements HasMeta {
  /// The sync kind the agent wants: `"full"` or `"incremental"`.
  final TextDocumentSyncKind? syncKind;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesDocumentDidChangeCapabilities].
  const NesDocumentDidChangeCapabilities({
    required this.syncKind,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesDocumentDidChangeCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'syncKind', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesDocumentDidChangeCapabilities(
      syncKind:
          json['syncKind'] == null
              ? null
              : TextDocumentSyncKind.fromString(json['syncKind'] as String),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (syncKind != null) 'syncKind': syncKind!.value,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Marker for `document/didClose` capability support.
@experimental
final class NesDocumentDidCloseCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesDocumentDidCloseCapabilities].
  const NesDocumentDidCloseCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesDocumentDidCloseCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesDocumentDidCloseCapabilities(
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

/// Marker for `document/didFocus` capability support.
@experimental
final class NesDocumentDidFocusCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesDocumentDidFocusCapabilities].
  const NesDocumentDidFocusCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesDocumentDidFocusCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesDocumentDidFocusCapabilities(
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

/// Marker for `document/didOpen` capability support.
@experimental
final class NesDocumentDidOpenCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesDocumentDidOpenCapabilities].
  const NesDocumentDidOpenCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesDocumentDidOpenCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesDocumentDidOpenCapabilities(
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

/// Marker for `document/didSave` capability support.
@experimental
final class NesDocumentDidSaveCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesDocumentDidSaveCapabilities].
  const NesDocumentDidSaveCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesDocumentDidSaveCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesDocumentDidSaveCapabilities(
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

/// Document event capabilities the agent wants to receive.
@experimental
final class NesDocumentEventCapabilities implements HasMeta {
  /// Whether the agent wants `document/didChange` events, and the sync kind.
  final NesDocumentDidChangeCapabilities? didChange;

  /// Whether the agent wants `document/didClose` events.
  final NesDocumentDidCloseCapabilities? didClose;

  /// Whether the agent wants `document/didFocus` events.
  final NesDocumentDidFocusCapabilities? didFocus;

  /// Whether the agent wants `document/didOpen` events.
  final NesDocumentDidOpenCapabilities? didOpen;

  /// Whether the agent wants `document/didSave` events.
  final NesDocumentDidSaveCapabilities? didSave;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesDocumentEventCapabilities].
  const NesDocumentEventCapabilities({
    this.didChange,
    this.didClose,
    this.didFocus,
    this.didOpen,
    this.didSave,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesDocumentEventCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {
      'didChange',
      'didClose',
      'didFocus',
      'didOpen',
      'didSave',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesDocumentEventCapabilities(
      didChange:
          json['didChange'] is Map<String, dynamic>
              ? NesDocumentDidChangeCapabilities.fromJson(
                json['didChange'] as Map<String, dynamic>,
              )
              : null,
      didClose:
          json['didClose'] is Map<String, dynamic>
              ? NesDocumentDidCloseCapabilities.fromJson(
                json['didClose'] as Map<String, dynamic>,
              )
              : null,
      didFocus:
          json['didFocus'] is Map<String, dynamic>
              ? NesDocumentDidFocusCapabilities.fromJson(
                json['didFocus'] as Map<String, dynamic>,
              )
              : null,
      didOpen:
          json['didOpen'] is Map<String, dynamic>
              ? NesDocumentDidOpenCapabilities.fromJson(
                json['didOpen'] as Map<String, dynamic>,
              )
              : null,
      didSave:
          json['didSave'] is Map<String, dynamic>
              ? NesDocumentDidSaveCapabilities.fromJson(
                json['didSave'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (didChange != null) 'didChange': didChange!.toJson(),
    if (didClose != null) 'didClose': didClose!.toJson(),
    if (didFocus != null) 'didFocus': didFocus!.toJson(),
    if (didOpen != null) 'didOpen': didOpen!.toJson(),
    if (didSave != null) 'didSave': didSave!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Capabilities for edit history context.
@experimental
final class NesEditHistoryCapabilities implements HasMeta {
  /// Maximum number of edit history entries the agent can use.
  final int? maxCount;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesEditHistoryCapabilities].
  const NesEditHistoryCapabilities({
    this.maxCount,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesEditHistoryCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'maxCount', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesEditHistoryCapabilities(
      maxCount: json['maxCount'] as int?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (maxCount != null) 'maxCount': maxCount,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// An entry in the edit history.
@experimental
final class NesEditHistoryEntry {
  /// A diff representing the edit.
  final String diff;

  /// The URI of the edited file.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesEditHistoryEntry].
  const NesEditHistoryEntry({
    required this.diff,
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesEditHistoryEntry.fromJson(Map<String, dynamic> json) {
    final known = {'diff', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesEditHistoryEntry(
      diff: json['diff'] as String,
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'diff': diff,
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}

/// A text edit suggestion.
@experimental
final class NesEditSuggestion {
  /// Optional suggested cursor position after applying edits.
  final Position? cursorPosition;

  /// The text edits to apply.
  final List<NesTextEdit> edits;

  /// Unique identifier for accept/reject tracking.
  final String id;

  /// The URI of the file to edit.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesEditSuggestion].
  const NesEditSuggestion({
    this.cursorPosition,
    this.edits = const [],
    required this.id,
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesEditSuggestion.fromJson(Map<String, dynamic> json) {
    final known = {'cursorPosition', 'edits', 'id', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesEditSuggestion(
      cursorPosition:
          json['cursorPosition'] is Map<String, dynamic>
              ? Position.fromJson(
                json['cursorPosition'] as Map<String, dynamic>,
              )
              : null,
      edits:
          (json['edits'] as List<dynamic>?)
              ?.map((e) => NesTextEdit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      id: json['id'] as String,
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (cursorPosition != null) 'cursorPosition': cursorPosition!.toJson(),
    'edits': edits.map((e) => e.toJson()).toList(),
    'id': id,
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}

/// Event capabilities the agent can consume.
@experimental
final class NesEventCapabilities implements HasMeta {
  /// Document event capabilities.
  final NesDocumentEventCapabilities? document;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesEventCapabilities].
  const NesEventCapabilities({this.document, this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesEventCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'document', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesEventCapabilities(
      document:
          json['document'] is Map<String, dynamic>
              ? NesDocumentEventCapabilities.fromJson(
                json['document'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (document != null) 'document': document!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A code excerpt from a file.
@experimental
final class NesExcerpt {
  /// The end line of the excerpt (zero-based).
  final int endLine;

  /// The start line of the excerpt (zero-based).
  final int startLine;

  /// The text content of the excerpt.
  final String text;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesExcerpt].
  const NesExcerpt({
    required this.endLine,
    required this.startLine,
    required this.text,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesExcerpt.fromJson(Map<String, dynamic> json) {
    final known = {'endLine', 'startLine', 'text'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesExcerpt(
      endLine: json['endLine'] as int,
      startLine: json['startLine'] as int,
      text: json['text'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'endLine': endLine,
    'startLine': startLine,
    'text': text,
    if (extensionData != null) ...extensionData!,
  };
}

/// Marker for jump suggestion support.
@experimental
final class NesJumpCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesJumpCapabilities].
  const NesJumpCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesJumpCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesJumpCapabilities(
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

/// A jump-to-location suggestion.
@experimental
final class NesJumpSuggestion {
  /// Unique identifier for accept/reject tracking.
  final String id;

  /// The target position within the file.
  final Position position;

  /// The file to navigate to.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesJumpSuggestion].
  const NesJumpSuggestion({
    required this.id,
    required this.position,
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesJumpSuggestion.fromJson(Map<String, dynamic> json) {
    final known = {'id', 'position', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesJumpSuggestion(
      id: json['id'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'position': position.toJson(),
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}

/// An open file in the editor.
@experimental
final class NesOpenFile {
  /// The language identifier.
  final String languageId;

  /// Timestamp in milliseconds since epoch of when the file was last focused.
  final int? lastFocusedMs;

  /// The URI of the file.
  final String uri;

  /// The visible range in the editor, if any.
  final Range? visibleRange;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesOpenFile].
  const NesOpenFile({
    required this.languageId,
    this.lastFocusedMs,
    required this.uri,
    this.visibleRange,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesOpenFile.fromJson(Map<String, dynamic> json) {
    final known = {'languageId', 'lastFocusedMs', 'uri', 'visibleRange'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesOpenFile(
      languageId: json['languageId'] as String,
      lastFocusedMs: json['lastFocusedMs'] as int?,
      uri: json['uri'] as String,
      visibleRange:
          json['visibleRange'] is Map<String, dynamic>
              ? Range.fromJson(json['visibleRange'] as Map<String, dynamic>)
              : null,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'languageId': languageId,
    if (lastFocusedMs != null) 'lastFocusedMs': lastFocusedMs,
    'uri': uri,
    if (visibleRange != null) 'visibleRange': visibleRange!.toJson(),
    if (extensionData != null) ...extensionData!,
  };
}

/// Capabilities for open files context.
@experimental
final class NesOpenFilesCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesOpenFilesCapabilities].
  const NesOpenFilesCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesOpenFilesCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesOpenFilesCapabilities(
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

/// A recently accessed file.
@experimental
final class NesRecentFile {
  /// The language identifier.
  final String languageId;

  /// The full text content of the file.
  final String text;

  /// The URI of the file.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesRecentFile].
  const NesRecentFile({
    required this.languageId,
    required this.text,
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesRecentFile.fromJson(Map<String, dynamic> json) {
    final known = {'languageId', 'text', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesRecentFile(
      languageId: json['languageId'] as String,
      text: json['text'] as String,
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'languageId': languageId,
    'text': text,
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}

/// Capabilities for recent files context.
@experimental
final class NesRecentFilesCapabilities implements HasMeta {
  /// Maximum number of recent files the agent can use.
  final int? maxCount;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesRecentFilesCapabilities].
  const NesRecentFilesCapabilities({
    this.maxCount,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesRecentFilesCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'maxCount', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesRecentFilesCapabilities(
      maxCount: json['maxCount'] as int?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (maxCount != null) 'maxCount': maxCount,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// The reason a suggestion was rejected.
@experimental
enum NesRejectReason {
  /// The user explicitly dismissed the suggestion.
  rejected('rejected'),

  /// The suggestion was shown but the user continued editing without interacting.
  ignored('ignored'),

  /// The suggestion was superseded by a newer suggestion.
  replaced('replaced'),

  /// The request was cancelled before the agent returned a response.
  cancelled('cancelled');

  /// The wire-format string value.
  final String value;

  const NesRejectReason(this.value);

  /// Parses a [NesRejectReason] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static NesRejectReason? fromString(String value) {
    for (final v in values) {
      if (v.value == value) return v;
    }
    return null;
  }
}

/// A related code snippet from a file.
@experimental
final class NesRelatedSnippet {
  /// The code excerpts.
  final List<NesExcerpt> excerpts;

  /// The URI of the file containing the snippets.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesRelatedSnippet].
  const NesRelatedSnippet({
    this.excerpts = const [],
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesRelatedSnippet.fromJson(Map<String, dynamic> json) {
    final known = {'excerpts', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesRelatedSnippet(
      excerpts:
          (json['excerpts'] as List<dynamic>?)
              ?.map((e) => NesExcerpt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'excerpts': excerpts.map((e) => e.toJson()).toList(),
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}

/// Capabilities for related snippets context.
@experimental
final class NesRelatedSnippetsCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesRelatedSnippetsCapabilities].
  const NesRelatedSnippetsCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesRelatedSnippetsCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesRelatedSnippetsCapabilities(
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

/// Marker for rename suggestion support.
@experimental
final class NesRenameCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesRenameCapabilities].
  const NesRenameCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesRenameCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesRenameCapabilities(
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

/// A rename symbol suggestion.
@experimental
final class NesRenameSuggestion {
  /// Unique identifier for accept/reject tracking.
  final String id;

  /// The new name for the symbol.
  final String newName;

  /// The position of the symbol to rename.
  final Position position;

  /// The file URI containing the symbol.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesRenameSuggestion].
  const NesRenameSuggestion({
    required this.id,
    required this.newName,
    required this.position,
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesRenameSuggestion.fromJson(Map<String, dynamic> json) {
    final known = {'id', 'newName', 'position', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesRenameSuggestion(
      id: json['id'] as String,
      newName: json['newName'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'newName': newName,
    'position': position.toJson(),
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}

/// Repository metadata for an NES session.
@experimental
final class NesRepository {
  /// The repository name.
  final String name;

  /// The repository owner.
  final String owner;

  /// The remote URL of the repository.
  final String remoteUrl;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesRepository].
  const NesRepository({
    required this.name,
    required this.owner,
    required this.remoteUrl,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesRepository.fromJson(Map<String, dynamic> json) {
    final known = {'name', 'owner', 'remoteUrl'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesRepository(
      name: json['name'] as String,
      owner: json['owner'] as String,
      remoteUrl: json['remoteUrl'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    'owner': owner,
    'remoteUrl': remoteUrl,
    if (extensionData != null) ...extensionData!,
  };
}

/// Marker for search and replace suggestion support.
@experimental
final class NesSearchAndReplaceCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesSearchAndReplaceCapabilities].
  const NesSearchAndReplaceCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory NesSearchAndReplaceCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesSearchAndReplaceCapabilities(
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

/// A search-and-replace suggestion.
@experimental
final class NesSearchAndReplaceSuggestion {
  /// Unique identifier for accept/reject tracking.
  final String id;

  /// Whether `search` is a regular expression. Defaults to `false`.
  final bool? isRegex;

  /// The replacement text.
  final String replace;

  /// The text or pattern to find.
  final String search;

  /// The file URI to search within.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesSearchAndReplaceSuggestion].
  const NesSearchAndReplaceSuggestion({
    required this.id,
    this.isRegex,
    required this.replace,
    required this.search,
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesSearchAndReplaceSuggestion.fromJson(Map<String, dynamic> json) {
    final known = {'id', 'isRegex', 'replace', 'search', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesSearchAndReplaceSuggestion(
      id: json['id'] as String,
      isRegex: json['isRegex'] as bool?,
      replace: json['replace'] as String,
      search: json['search'] as String,
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (isRegex != null) 'isRegex': isRegex,
    'replace': replace,
    'search': search,
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}

/// Context attached to a suggestion request.
@experimental
final class NesSuggestContext implements HasMeta {
  /// Current diagnostics (errors, warnings).
  final List<NesDiagnostic>? diagnostics;

  /// Recent edit history.
  final List<NesEditHistoryEntry>? editHistory;

  /// Currently open files in the editor.
  final List<NesOpenFile>? openFiles;

  /// Recently accessed files.
  final List<NesRecentFile>? recentFiles;

  /// Related code snippets.
  final List<NesRelatedSnippet>? relatedSnippets;

  /// Recent user actions (typing, navigation, etc.).
  final List<NesUserAction>? userActions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesSuggestContext].
  const NesSuggestContext({
    this.diagnostics,
    this.editHistory,
    this.openFiles,
    this.recentFiles,
    this.relatedSnippets,
    this.userActions,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesSuggestContext.fromJson(Map<String, dynamic> json) {
    final known = {
      'diagnostics',
      'editHistory',
      'openFiles',
      'recentFiles',
      'relatedSnippets',
      'userActions',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesSuggestContext(
      diagnostics:
          (json['diagnostics'] as List<dynamic>?)
              ?.map((e) => NesDiagnostic.fromJson(e as Map<String, dynamic>))
              .toList(),
      editHistory:
          (json['editHistory'] as List<dynamic>?)
              ?.map(
                (e) => NesEditHistoryEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      openFiles:
          (json['openFiles'] as List<dynamic>?)
              ?.map((e) => NesOpenFile.fromJson(e as Map<String, dynamic>))
              .toList(),
      recentFiles:
          (json['recentFiles'] as List<dynamic>?)
              ?.map((e) => NesRecentFile.fromJson(e as Map<String, dynamic>))
              .toList(),
      relatedSnippets:
          (json['relatedSnippets'] as List<dynamic>?)
              ?.map(
                (e) => NesRelatedSnippet.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      userActions:
          (json['userActions'] as List<dynamic>?)
              ?.map((e) => NesUserAction.fromJson(e as Map<String, dynamic>))
              .toList(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (diagnostics != null)
      'diagnostics': diagnostics!.map((e) => e.toJson()).toList(),
    if (editHistory != null)
      'editHistory': editHistory!.map((e) => e.toJson()).toList(),
    if (openFiles != null)
      'openFiles': openFiles!.map((e) => e.toJson()).toList(),
    if (recentFiles != null)
      'recentFiles': recentFiles!.map((e) => e.toJson()).toList(),
    if (relatedSnippets != null)
      'relatedSnippets': relatedSnippets!.map((e) => e.toJson()).toList(),
    if (userActions != null)
      'userActions': userActions!.map((e) => e.toJson()).toList(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A suggestion returned by the agent.
@experimental
sealed class NesSuggestion implements HasMeta {
  const NesSuggestion();

  /// Deserializes a [NesSuggestion] from JSON.
  ///
  /// Switches on the `kind` discriminator field.
  factory NesSuggestion.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    if (kind == null) {
      return UnknownNesSuggestion(rawJson: json);
    }
    return switch (kind) {
      'edit' => Edit.fromJson(json),
      'jump' => Jump.fromJson(json),
      'rename' => Rename.fromJson(json),
      'searchAndReplace' => SearchAndReplace.fromJson(json),
      _ => UnknownNesSuggestion(
        kindType: kind,
        rawJson: json,
        meta: json['_meta'] as Map<String, Object?>?,
      ),
    };
  }

  /// Serializes this nesSuggestion to JSON.
  Map<String, dynamic> toJson();
}

/// A text edit suggestion.
@experimental
final class Edit extends NesSuggestion {
  /// Optional suggested cursor position after applying edits.
  final Position? cursorPosition;

  /// The text edits to apply.
  final List<NesTextEdit> edits;

  /// Unique identifier for accept/reject tracking.
  final String id;

  /// The URI of the file to edit.
  final String uri;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [Edit].
  const Edit({
    this.cursorPosition,
    required this.edits,
    required this.id,
    required this.uri,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory Edit.fromJson(Map<String, dynamic> json) {
    final known = {'cursorPosition', 'edits', 'id', 'uri', '_meta', 'kind'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Edit(
      cursorPosition:
          json['cursorPosition'] is Map<String, dynamic>
              ? Position.fromJson(
                json['cursorPosition'] as Map<String, dynamic>,
              )
              : null,
      edits:
          (json['edits'] as List<dynamic>)
              .map((e) => NesTextEdit.fromJson(e as Map<String, dynamic>))
              .toList(),
      id: json['id'] as String,
      uri: json['uri'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'edit',
    if (cursorPosition != null) 'cursorPosition': cursorPosition!.toJson(),
    'edits': edits.map((e) => e.toJson()).toList(),
    'id': id,
    'uri': uri,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A jump-to-location suggestion.
@experimental
final class Jump extends NesSuggestion {
  /// Unique identifier for accept/reject tracking.
  final String id;

  /// The target position within the file.
  final Position position;

  /// The file to navigate to.
  final String uri;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [Jump].
  const Jump({
    required this.id,
    required this.position,
    required this.uri,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory Jump.fromJson(Map<String, dynamic> json) {
    final known = {'id', 'position', 'uri', '_meta', 'kind'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Jump(
      id: json['id'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      uri: json['uri'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'jump',
    'id': id,
    'position': position.toJson(),
    'uri': uri,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A rename symbol suggestion.
@experimental
final class Rename extends NesSuggestion {
  /// Unique identifier for accept/reject tracking.
  final String id;

  /// The new name for the symbol.
  final String newName;

  /// The position of the symbol to rename.
  final Position position;

  /// The file URI containing the symbol.
  final String uri;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [Rename].
  const Rename({
    required this.id,
    required this.newName,
    required this.position,
    required this.uri,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory Rename.fromJson(Map<String, dynamic> json) {
    final known = {'id', 'newName', 'position', 'uri', '_meta', 'kind'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Rename(
      id: json['id'] as String,
      newName: json['newName'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      uri: json['uri'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'rename',
    'id': id,
    'newName': newName,
    'position': position.toJson(),
    'uri': uri,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A search-and-replace suggestion.
@experimental
final class SearchAndReplace extends NesSuggestion {
  /// Unique identifier for accept/reject tracking.
  final String id;

  /// Whether `search` is a regular expression. Defaults to `false`.
  final bool? isRegex;

  /// The replacement text.
  final String replace;

  /// The text or pattern to find.
  final String search;

  /// The file URI to search within.
  final String uri;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SearchAndReplace].
  const SearchAndReplace({
    required this.id,
    this.isRegex,
    required this.replace,
    required this.search,
    required this.uri,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SearchAndReplace.fromJson(Map<String, dynamic> json) {
    final known = {
      'id',
      'isRegex',
      'replace',
      'search',
      'uri',
      '_meta',
      'kind',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SearchAndReplace(
      id: json['id'] as String,
      isRegex: json['isRegex'] as bool?,
      replace: json['replace'] as String,
      search: json['search'] as String,
      uri: json['uri'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'searchAndReplace',
    'id': id,
    if (isRegex != null) 'isRegex': isRegex,
    'replace': replace,
    'search': search,
    'uri': uri,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

@experimental
/// A nesSuggestion with an unknown kind, preserved for forward compatibility.
final class UnknownNesSuggestion extends NesSuggestion {
  /// The unknown discriminator value.
  final String? kindType;

  /// The raw JSON object, preserved as-is.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [UnknownNesSuggestion].
  const UnknownNesSuggestion({this.kindType, required this.rawJson, this.meta});

  @override
  Map<String, dynamic> toJson() => rawJson;
}

/// A text edit within a suggestion.
@experimental
final class NesTextEdit {
  /// The replacement text.
  final String newText;

  /// The range to replace.
  final Range range;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesTextEdit].
  const NesTextEdit({
    required this.newText,
    required this.range,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesTextEdit.fromJson(Map<String, dynamic> json) {
    final known = {'newText', 'range'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesTextEdit(
      newText: json['newText'] as String,
      range: Range.fromJson(json['range'] as Map<String, dynamic>),
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'newText': newText,
    'range': range.toJson(),
    if (extensionData != null) ...extensionData!,
  };
}

/// What triggered the suggestion request.
@experimental
enum NesTriggerKind {
  /// Triggered by user typing or cursor movement.
  automatic('automatic'),

  /// Triggered by a diagnostic appearing at or near the cursor.
  diagnostic('diagnostic'),

  /// Triggered by an explicit user action (keyboard shortcut).
  manual('manual');

  /// The wire-format string value.
  final String value;

  const NesTriggerKind(this.value);

  /// Parses a [NesTriggerKind] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static NesTriggerKind? fromString(String value) {
    for (final v in values) {
      if (v.value == value) return v;
    }
    return null;
  }
}

/// A user action (typing, cursor movement, etc.).
@experimental
final class NesUserAction {
  /// The kind of action (e.g., "insertChar", "cursorMovement").
  final String action;

  /// The position where the action occurred.
  final Position position;

  /// Timestamp in milliseconds since epoch.
  final int timestampMs;

  /// The URI of the file where the action occurred.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesUserAction].
  const NesUserAction({
    required this.action,
    required this.position,
    required this.timestampMs,
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesUserAction.fromJson(Map<String, dynamic> json) {
    final known = {'action', 'position', 'timestampMs', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesUserAction(
      action: json['action'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      timestampMs: json['timestampMs'] as int,
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'action': action,
    'position': position.toJson(),
    'timestampMs': timestampMs,
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}

/// Capabilities for user actions context.
@experimental
final class NesUserActionsCapabilities implements HasMeta {
  /// Maximum number of user actions the agent can use.
  final int? maxCount;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NesUserActionsCapabilities].
  const NesUserActionsCapabilities({
    this.maxCount,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NesUserActionsCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'maxCount', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NesUserActionsCapabilities(
      maxCount: json['maxCount'] as int?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (maxCount != null) 'maxCount': maxCount,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Schema for number (floating-point) properties in an elicitation form.
@experimental
final class NumberPropertySchema {
  /// Default value.
  final double? defaultValue;

  /// Human-readable description.
  final String? description;

  /// Maximum value (inclusive).
  final double? maximum;

  /// Minimum value (inclusive).
  final double? minimum;

  /// Optional title for the property.
  final String? title;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [NumberPropertySchema].
  const NumberPropertySchema({
    this.defaultValue,
    this.description,
    this.maximum,
    this.minimum,
    this.title,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory NumberPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {'default', 'description', 'maximum', 'minimum', 'title'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return NumberPropertySchema(
      defaultValue: (json['default'] as num?)?.toDouble(),
      description: json['description'] as String?,
      maximum: (json['maximum'] as num?)?.toDouble(),
      minimum: (json['minimum'] as num?)?.toDouble(),
      title: json['title'] as String?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    if (maximum != null) 'maximum': maximum,
    if (minimum != null) 'minimum': minimum,
    if (title != null) 'title': title,
    if (extensionData != null) ...extensionData!,
  };
}

/// A zero-based position in a text document.
///
/// The meaning of `character` depends on the negotiated position encoding.
@experimental
final class Position {
  /// Zero-based character offset (encoding-dependent).
  final int character;

  /// Zero-based line number.
  final int line;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [Position].
  const Position({
    required this.character,
    required this.line,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory Position.fromJson(Map<String, dynamic> json) {
    final known = {'character', 'line'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Position(
      character: json['character'] as int,
      line: json['line'] as int,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'character': character,
    'line': line,
    if (extensionData != null) ...extensionData!,
  };
}

/// The encoding used for character offsets in positions.
///
/// Follows the same conventions as LSP 3.17. The default is UTF-16.
@experimental
enum PositionEncodingKind {
  /// Character offsets count UTF-16 code units. This is the default.
  utf16('utf-16'),

  /// Character offsets count Unicode code points.
  utf32('utf-32'),

  /// Character offsets count UTF-8 code units (bytes).
  utf8('utf-8');

  /// The wire-format string value.
  final String value;

  const PositionEncodingKind(this.value);

  /// Parses a [PositionEncodingKind] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static PositionEncodingKind? fromString(String value) {
    for (final v in values) {
      if (v.value == value) return v;
    }
    return null;
  }
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Current effective non-secret routing configuration for a provider.
@experimental
final class ProviderCurrentConfig {
  /// Protocol currently used by this provider.
  final Map<String, dynamic> apiType;

  /// Base URL currently used by this provider.
  final String baseUrl;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ProviderCurrentConfig].
  const ProviderCurrentConfig({
    required this.apiType,
    required this.baseUrl,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ProviderCurrentConfig.fromJson(Map<String, dynamic> json) {
    final known = {'apiType', 'baseUrl'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ProviderCurrentConfig(
      apiType: json['apiType'] as Map<String, dynamic>,
      baseUrl: json['baseUrl'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'apiType': apiType,
    'baseUrl': baseUrl,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Information about a configurable LLM provider.
@experimental
final class ProviderInfo implements HasMeta {
  /// Current effective non-secret routing config.
  /// Null means provider is disabled.
  final ProviderCurrentConfig? current;

  /// Provider identifier, for example "main" or "openai".
  final String id;

  /// Whether this provider is mandatory and cannot be disabled via `providers/disable`.
  /// If true, clients must not call `providers/disable` for this id.
  final bool required;

  /// Supported protocol types for this provider.
  final List<Map<String, dynamic>> supported;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ProviderInfo].
  const ProviderInfo({
    required this.current,
    required this.id,
    required this.required,
    this.supported = const [],
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    final known = {'current', 'id', 'required', 'supported', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ProviderInfo(
      current: ProviderCurrentConfig.fromJson(
        json['current'] as Map<String, dynamic>,
      ),
      id: json['id'] as String,
      required: json['required'] as bool,
      supported:
          (json['supported'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          const [],
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (current != null) 'current': current!.toJson(),
    'id': id,
    'required': required,
    'supported': supported,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Provider configuration capabilities supported by the agent.
///
/// By supplying `{}` it means that the agent supports provider configuration methods.
@experimental
final class ProvidersCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ProvidersCapabilities].
  const ProvidersCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory ProvidersCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ProvidersCapabilities(
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

/// A range in a text document, expressed as start and end positions.
@experimental
final class Range {
  /// The end position (exclusive).
  final Position end;

  /// The start position (inclusive).
  final Position start;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [Range].
  const Range({required this.end, required this.start, this.extensionData});

  /// Deserializes from JSON.
  factory Range.fromJson(Map<String, dynamic> json) {
    final known = {'end', 'start'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Range(
      end: Position.fromJson(json['end'] as Map<String, dynamic>),
      start: Position.fromJson(json['start'] as Map<String, dynamic>),
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'end': end.toJson(),
    'start': start.toJson(),
    if (extensionData != null) ...extensionData!,
  };
}

/// Notification sent when a suggestion is rejected.
@experimental
final class RejectNesNotification implements HasMeta {
  /// The ID of the rejected suggestion.
  final String id;

  /// The reason for rejection.
  final NesRejectReason? reason;

  /// The session ID for this notification.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [RejectNesNotification].
  const RejectNesNotification({
    required this.id,
    this.reason,
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory RejectNesNotification.fromJson(Map<String, dynamic> json) {
    final known = {'id', 'reason', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return RejectNesNotification(
      id: json['id'] as String,
      reason:
          json['reason'] == null
              ? null
              : NesRejectReason.fromString(json['reason'] as String),
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (reason != null) 'reason': reason!.value,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request parameters for resuming an existing session.
///
/// Resumes an existing session without returning previous messages (unlike `session/load`).
/// This is useful for agents that can resume sessions but don't implement full session loading.
///
/// Only available if the Agent supports the `sessionCapabilities.resume` capability.
@experimental
final class ResumeSessionRequest implements HasMeta {
  /// **UNSTABLE**
  ///
  /// This capability is not part of the spec yet, and may be removed or changed at any point.
  ///
  /// Additional workspace roots to activate for this session. Each path must be absolute.
  ///
  /// When omitted or empty, no additional roots are activated. When non-empty,
  /// this is the complete resulting additional-root list for the resumed
  /// session.
  final List<String> additionalDirectories;

  /// The working directory for this session.
  final String cwd;

  /// List of MCP servers to connect to for this session.
  final List<Map<String, dynamic>> mcpServers;

  /// The ID of the session to resume.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ResumeSessionRequest].
  const ResumeSessionRequest({
    this.additionalDirectories = const [],
    required this.cwd,
    this.mcpServers = const [],
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ResumeSessionRequest.fromJson(Map<String, dynamic> json) {
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
    return ResumeSessionRequest(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response from resuming an existing session.
@experimental
final class ResumeSessionResponse implements HasMeta {
  /// Initial session configuration options if supported by the Agent.
  final List<Map<String, dynamic>>? configOptions;

  /// **UNSTABLE**
  ///
  /// This capability is not part of the spec yet, and may be removed or changed at any point.
  ///
  /// Initial model state if supported by the Agent
  final SessionModelState? models;

  /// Initial mode state if supported by the Agent
  ///
  /// See protocol docs: [Session Modes](https://agentclientprotocol.com/protocol/session-modes)
  final Map<String, dynamic>? modes;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ResumeSessionResponse].
  const ResumeSessionResponse({
    this.configOptions,
    this.models,
    this.modes,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ResumeSessionResponse.fromJson(Map<String, dynamic> json) {
    final known = {'configOptions', 'models', 'modes', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ResumeSessionResponse(
      configOptions:
          (json['configOptions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>(),
      models:
          json['models'] is Map<String, dynamic>
              ? SessionModelState.fromJson(
                json['models'] as Map<String, dynamic>,
              )
              : null,
      modes: json['modes'] as Map<String, dynamic>?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (configOptions != null) 'configOptions': configOptions,
    if (models != null) 'models': models!.toJson(),
    if (modes != null) 'modes': modes,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Capabilities for additional session directories support.
///
/// By supplying `{}` it means that the agent supports the `additionalDirectories` field on
/// supported session lifecycle requests and `session/list`.
@experimental
final class SessionAdditionalDirectoriesCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionAdditionalDirectoriesCapabilities].
  const SessionAdditionalDirectoriesCapabilities({
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SessionAdditionalDirectoriesCapabilities.fromJson(
    Map<String, dynamic> json,
  ) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionAdditionalDirectoriesCapabilities(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Capabilities for the `session/close` method.
///
/// By supplying `{}` it means that the agent supports closing of sessions.
@experimental
final class SessionCloseCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionCloseCapabilities].
  const SessionCloseCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory SessionCloseCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionCloseCapabilities(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// A boolean on/off toggle session configuration option payload.
@experimental
final class SessionConfigBoolean {
  /// The current value of the boolean option.
  final bool currentValue;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionConfigBoolean].
  const SessionConfigBoolean({required this.currentValue, this.extensionData});

  /// Deserializes from JSON.
  factory SessionConfigBoolean.fromJson(Map<String, dynamic> json) {
    final known = {'currentValue'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionConfigBoolean(
      currentValue: json['currentValue'] as bool,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'currentValue': currentValue,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Capabilities for the `session/fork` method.
///
/// By supplying `{}` it means that the agent supports forking of sessions.
@experimental
final class SessionForkCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionForkCapabilities].
  const SessionForkCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory SessionForkCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionForkCapabilities(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// The set of models and the one currently active.
@experimental
final class SessionModelState implements HasMeta {
  /// The set of models that the Agent can use
  final List<ModelInfo> availableModels;

  /// The current model the Agent is in.
  final Map<String, dynamic> currentModelId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionModelState].
  const SessionModelState({
    this.availableModels = const [],
    required this.currentModelId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SessionModelState.fromJson(Map<String, dynamic> json) {
    final known = {'availableModels', 'currentModelId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionModelState(
      availableModels:
          (json['availableModels'] as List<dynamic>?)
              ?.map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentModelId: json['currentModelId'] as Map<String, dynamic>,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'availableModels': availableModels.map((e) => e.toJson()).toList(),
    'currentModelId': currentModelId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Capabilities for the `session/resume` method.
///
/// By supplying `{}` it means that the agent supports resuming of sessions.
@experimental
final class SessionResumeCapabilities implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SessionResumeCapabilities].
  const SessionResumeCapabilities({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory SessionResumeCapabilities.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SessionResumeCapabilities(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request parameters for `providers/set`.
///
/// Replaces the full configuration for one provider id.
@experimental
final class SetProvidersRequest implements HasMeta {
  /// Protocol type for this provider.
  final Map<String, dynamic> apiType;

  /// Base URL for requests sent through this provider.
  final String baseUrl;

  /// Full headers map for this provider.
  /// May include authorization, routing, or other integration-specific headers.
  final Map<String, dynamic>? headers;

  /// Provider id to configure.
  final String id;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetProvidersRequest].
  const SetProvidersRequest({
    required this.apiType,
    required this.baseUrl,
    this.headers,
    required this.id,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SetProvidersRequest.fromJson(Map<String, dynamic> json) {
    final known = {'apiType', 'baseUrl', 'headers', 'id', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetProvidersRequest(
      apiType: json['apiType'] as Map<String, dynamic>,
      baseUrl: json['baseUrl'] as String,
      headers: json['headers'] as Map<String, dynamic>?,
      id: json['id'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'apiType': apiType,
    'baseUrl': baseUrl,
    if (headers != null) 'headers': headers,
    'id': id,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response to `providers/set`.
@experimental
final class SetProvidersResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetProvidersResponse].
  const SetProvidersResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory SetProvidersResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetProvidersResponse(
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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request parameters for setting a session model.
@experimental
final class SetSessionModelRequest implements HasMeta {
  /// The ID of the model to set.
  final Map<String, dynamic> modelId;

  /// The ID of the session to set the model for.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionModelRequest].
  const SetSessionModelRequest({
    required this.modelId,
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SetSessionModelRequest.fromJson(Map<String, dynamic> json) {
    final known = {'modelId', 'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetSessionModelRequest(
      modelId: json['modelId'] as Map<String, dynamic>,
      sessionId: json['sessionId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'sessionId': sessionId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response to `session/set_model` method.
@experimental
final class SetSessionModelResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SetSessionModelResponse].
  const SetSessionModelResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory SetSessionModelResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SetSessionModelResponse(
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

// -- Next Edit Suggestions (unstable) --

/// Request to start an NES session.
@experimental
final class StartNesRequest implements HasMeta {
  /// Repository metadata, if the workspace is a git repository.
  final NesRepository? repository;

  /// The workspace folders.
  final List<WorkspaceFolder>? workspaceFolders;

  /// The root URI of the workspace.
  final String? workspaceUri;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [StartNesRequest].
  const StartNesRequest({
    this.repository,
    this.workspaceFolders,
    this.workspaceUri,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory StartNesRequest.fromJson(Map<String, dynamic> json) {
    final known = {'repository', 'workspaceFolders', 'workspaceUri', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return StartNesRequest(
      repository:
          json['repository'] is Map<String, dynamic>
              ? NesRepository.fromJson(
                json['repository'] as Map<String, dynamic>,
              )
              : null,
      workspaceFolders:
          (json['workspaceFolders'] as List<dynamic>?)
              ?.map((e) => WorkspaceFolder.fromJson(e as Map<String, dynamic>))
              .toList(),
      workspaceUri: json['workspaceUri'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (repository != null) 'repository': repository!.toJson(),
    if (workspaceFolders != null)
      'workspaceFolders': workspaceFolders!.map((e) => e.toJson()).toList(),
    if (workspaceUri != null) 'workspaceUri': workspaceUri,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `nes/start`.
@experimental
final class StartNesResponse implements HasMeta {
  /// The session ID for the newly started NES session.
  final String sessionId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [StartNesResponse].
  const StartNesResponse({
    required this.sessionId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory StartNesResponse.fromJson(Map<String, dynamic> json) {
    final known = {'sessionId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return StartNesResponse(
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

/// String format types for string properties in elicitation schemas.
@experimental
enum StringFormat {
  /// Email address format.
  email('email'),

  /// URI format.
  uri('uri'),

  /// Date format (YYYY-MM-DD).
  date('date'),

  /// Date-time format (ISO 8601).
  dateTime('date-time');

  /// The wire-format string value.
  final String value;

  const StringFormat(this.value);

  /// Parses a [StringFormat] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static StringFormat? fromString(String value) {
    for (final v in values) {
      if (v.value == value) return v;
    }
    return null;
  }
}

/// Schema for string properties in an elicitation form.
///
/// When `enum` or `oneOf` is set, this represents a single-select enum
/// with `"type": "string"`.
@experimental
final class StringPropertySchema {
  /// Default value.
  final String? defaultValue;

  /// Human-readable description.
  final String? description;

  /// Enum values for untitled single-select enums.
  final List<String>? enumValues;

  /// String format.
  final StringFormat? format;

  /// Maximum string length.
  final int? maxLength;

  /// Minimum string length.
  final int? minLength;

  /// Titled enum options for titled single-select enums.
  final List<EnumOption>? oneOf;

  /// Pattern the string must match.
  final String? pattern;

  /// Optional title for the property.
  final String? title;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [StringPropertySchema].
  const StringPropertySchema({
    this.defaultValue,
    this.description,
    this.enumValues,
    this.format,
    this.maxLength,
    this.minLength,
    this.oneOf,
    this.pattern,
    this.title,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory StringPropertySchema.fromJson(Map<String, dynamic> json) {
    final known = {
      'default',
      'description',
      'enum',
      'format',
      'maxLength',
      'minLength',
      'oneOf',
      'pattern',
      'title',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return StringPropertySchema(
      defaultValue: json['default'] as String?,
      description: json['description'] as String?,
      enumValues: (json['enum'] as List<dynamic>?)?.cast<String>(),
      format:
          json['format'] == null
              ? null
              : StringFormat.fromString(json['format'] as String),
      maxLength: json['maxLength'] as int?,
      minLength: json['minLength'] as int?,
      oneOf:
          (json['oneOf'] as List<dynamic>?)
              ?.map((e) => EnumOption.fromJson(e as Map<String, dynamic>))
              .toList(),
      pattern: json['pattern'] as String?,
      title: json['title'] as String?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    if (enumValues != null) 'enum': enumValues,
    if (format != null) 'format': format!.value,
    if (maxLength != null) 'maxLength': maxLength,
    if (minLength != null) 'minLength': minLength,
    if (oneOf != null) 'oneOf': oneOf!.map((e) => e.toJson()).toList(),
    if (pattern != null) 'pattern': pattern,
    if (title != null) 'title': title,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request for a code suggestion.
@experimental
final class SuggestNesRequest implements HasMeta {
  /// Context for the suggestion, included based on agent capabilities.
  final NesSuggestContext? context;

  /// The current cursor position.
  final Position position;

  /// The current text selection range, if any.
  final Range? selection;

  /// The session ID for this request.
  final String sessionId;

  /// What triggered this suggestion request.
  final NesTriggerKind? triggerKind;

  /// The URI of the document to suggest for.
  final String uri;

  /// The version number of the document.
  final int version;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SuggestNesRequest].
  const SuggestNesRequest({
    this.context,
    required this.position,
    this.selection,
    required this.sessionId,
    required this.triggerKind,
    required this.uri,
    required this.version,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SuggestNesRequest.fromJson(Map<String, dynamic> json) {
    final known = {
      'context',
      'position',
      'selection',
      'sessionId',
      'triggerKind',
      'uri',
      'version',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SuggestNesRequest(
      context:
          json['context'] is Map<String, dynamic>
              ? NesSuggestContext.fromJson(
                json['context'] as Map<String, dynamic>,
              )
              : null,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      selection:
          json['selection'] is Map<String, dynamic>
              ? Range.fromJson(json['selection'] as Map<String, dynamic>)
              : null,
      sessionId: json['sessionId'] as String,
      triggerKind:
          json['triggerKind'] == null
              ? null
              : NesTriggerKind.fromString(json['triggerKind'] as String),
      uri: json['uri'] as String,
      version: json['version'] as int,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (context != null) 'context': context!.toJson(),
    'position': position.toJson(),
    if (selection != null) 'selection': selection!.toJson(),
    'sessionId': sessionId,
    if (triggerKind != null) 'triggerKind': triggerKind!.value,
    'uri': uri,
    'version': version,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to `nes/suggest`.
@experimental
final class SuggestNesResponse implements HasMeta {
  /// The list of suggestions.
  final List<NesSuggestion> suggestions;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [SuggestNesResponse].
  const SuggestNesResponse({
    this.suggestions = const [],
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory SuggestNesResponse.fromJson(Map<String, dynamic> json) {
    final known = {'suggestions', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return SuggestNesResponse(
      suggestions:
          (json['suggestions'] as List<dynamic>?)
              ?.map((e) => NesSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'suggestions': suggestions.map((e) => e.toJson()).toList(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A content change event for a document.
///
/// When `range` is `None`, `text` is the full content of the document.
/// When `range` is `Some`, `text` replaces the given range.
@experimental
final class TextDocumentContentChangeEvent {
  /// The range of the document that changed. If `None`, the entire content is replaced.
  final Range? range;

  /// The new text for the range, or the full document content if `range` is `None`.
  final String text;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [TextDocumentContentChangeEvent].
  const TextDocumentContentChangeEvent({
    this.range,
    required this.text,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory TextDocumentContentChangeEvent.fromJson(Map<String, dynamic> json) {
    final known = {'range', 'text'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return TextDocumentContentChangeEvent(
      range:
          json['range'] is Map<String, dynamic>
              ? Range.fromJson(json['range'] as Map<String, dynamic>)
              : null,
      text: json['text'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (range != null) 'range': range!.toJson(),
    'text': text,
    if (extensionData != null) ...extensionData!,
  };
}

/// How the agent wants document changes delivered.
@experimental
enum TextDocumentSyncKind {
  /// Client sends the entire file content on each change.
  full('full'),

  /// Client sends only the changed ranges.
  incremental('incremental');

  /// The wire-format string value.
  final String value;

  const TextDocumentSyncKind(this.value);

  /// Parses a [TextDocumentSyncKind] from its wire-format string.
  ///
  /// Returns `null` for unknown values.
  static TextDocumentSyncKind? fromString(String value) {
    for (final v in values) {
      if (v.value == value) return v;
    }
    return null;
  }
}

/// Items definition for titled multi-select enum properties.
@experimental
final class TitledMultiSelectItems {
  /// Titled enum options.
  final List<EnumOption> anyOf;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [TitledMultiSelectItems].
  const TitledMultiSelectItems({this.anyOf = const [], this.extensionData});

  /// Deserializes from JSON.
  factory TitledMultiSelectItems.fromJson(Map<String, dynamic> json) {
    final known = {'anyOf'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return TitledMultiSelectItems(
      anyOf:
          (json['anyOf'] as List<dynamic>?)
              ?.map((e) => EnumOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'anyOf': anyOf.map((e) => e.toJson()).toList(),
    if (extensionData != null) ...extensionData!,
  };
}

/// Items definition for untitled multi-select enum properties.
@experimental
final class UntitledMultiSelectItems {
  /// Allowed enum values.
  final List<String> enumValues;

  /// Item type discriminator. Must be `"string"`.
  final ElicitationStringType? type;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [UntitledMultiSelectItems].
  const UntitledMultiSelectItems({
    this.enumValues = const [],
    required this.type,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory UntitledMultiSelectItems.fromJson(Map<String, dynamic> json) {
    final known = {'enum', 'type'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return UntitledMultiSelectItems(
      enumValues: (json['enum'] as List<dynamic>?)?.cast<String>() ?? const [],
      type:
          json['type'] == null
              ? null
              : ElicitationStringType.fromString(json['type'] as String),
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'enum': enumValues,
    if (type != null) 'type': type!.value,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Token usage information for a prompt turn.
@experimental
final class Usage {
  /// Total cache read tokens.
  final int? cachedReadTokens;

  /// Total cache write tokens.
  final int? cachedWriteTokens;

  /// Total input tokens across all turns.
  final int inputTokens;

  /// Total output tokens across all turns.
  final int outputTokens;

  /// Total thought/reasoning tokens
  final int? thoughtTokens;

  /// Sum of all token types across session.
  final int totalTokens;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [Usage].
  const Usage({
    this.cachedReadTokens,
    this.cachedWriteTokens,
    required this.inputTokens,
    required this.outputTokens,
    this.thoughtTokens,
    required this.totalTokens,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory Usage.fromJson(Map<String, dynamic> json) {
    final known = {
      'cachedReadTokens',
      'cachedWriteTokens',
      'inputTokens',
      'outputTokens',
      'thoughtTokens',
      'totalTokens',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Usage(
      cachedReadTokens: json['cachedReadTokens'] as int?,
      cachedWriteTokens: json['cachedWriteTokens'] as int?,
      inputTokens: json['inputTokens'] as int,
      outputTokens: json['outputTokens'] as int,
      thoughtTokens: json['thoughtTokens'] as int?,
      totalTokens: json['totalTokens'] as int,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (cachedReadTokens != null) 'cachedReadTokens': cachedReadTokens,
    if (cachedWriteTokens != null) 'cachedWriteTokens': cachedWriteTokens,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    if (thoughtTokens != null) 'thoughtTokens': thoughtTokens,
    'totalTokens': totalTokens,
    if (extensionData != null) ...extensionData!,
  };
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Context window and cost update for a session.
@experimental
final class UsageUpdate implements HasMeta {
  /// Cumulative session cost (optional).
  final Cost? cost;

  /// Total context window size in tokens.
  final int size;

  /// Tokens currently in context.
  final int used;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [UsageUpdate].
  const UsageUpdate({
    this.cost,
    required this.size,
    required this.used,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory UsageUpdate.fromJson(Map<String, dynamic> json) {
    final known = {'cost', 'size', 'used', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return UsageUpdate(
      cost:
          json['cost'] is Map<String, dynamic>
              ? Cost.fromJson(json['cost'] as Map<String, dynamic>)
              : null,
      size: json['size'] as int,
      used: json['used'] as int,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (cost != null) 'cost': cost!.toJson(),
    'size': size,
    'used': used,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A workspace folder.
@experimental
final class WorkspaceFolder {
  /// The display name of the folder.
  final String name;

  /// The URI of the folder.
  final String uri;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [WorkspaceFolder].
  const WorkspaceFolder({
    required this.name,
    required this.uri,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory WorkspaceFolder.fromJson(Map<String, dynamic> json) {
    final known = {'name', 'uri'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return WorkspaceFolder(
      name: json['name'] as String,
      uri: json['uri'] as String,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    'uri': uri,
    if (extensionData != null) ...extensionData!,
  };
}
