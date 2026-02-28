// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/auth_method.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/has_meta.dart';
import 'package:acp/src/schema/implementation_info.dart';

/// Request parameters for the initialize method.
///
/// Sent by the client to establish connection and negotiate capabilities.
///
/// See protocol docs: [Initialization](https://agentclientprotocol.com/protocol/initialization)
final class InitializeRequest implements HasMeta {
  /// Capabilities supported by the client.
  final ClientCapabilities clientCapabilities;

  /// Information about the Client name and version sent to the Agent.
  ///
  /// Note: in future versions of the protocol, this will be required.
  final ImplementationInfo? clientInfo;

  /// The latest protocol version supported by the client.
  final int protocolVersion;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [InitializeRequest].
  const InitializeRequest({
    this.clientCapabilities = const ClientCapabilities(),
    this.clientInfo,
    required this.protocolVersion,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory InitializeRequest.fromJson(Map<String, dynamic> json) {
    final known = {
      'clientCapabilities',
      'clientInfo',
      'protocolVersion',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return InitializeRequest(
      clientCapabilities:
          json['clientCapabilities'] is Map<String, dynamic>
              ? ClientCapabilities.fromJson(
                json['clientCapabilities'] as Map<String, dynamic>,
              )
              : const ClientCapabilities(),
      clientInfo:
          json['clientInfo'] is Map<String, dynamic>
              ? ImplementationInfo.fromJson(
                json['clientInfo'] as Map<String, dynamic>,
              )
              : null,
      protocolVersion: json['protocolVersion'] as int,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'clientCapabilities': clientCapabilities.toJson(),
    if (clientInfo != null) 'clientInfo': clientInfo!.toJson(),
    'protocolVersion': protocolVersion,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to the `initialize` method.
///
/// Contains the negotiated protocol version and agent capabilities.
///
/// See protocol docs: [Initialization](https://agentclientprotocol.com/protocol/initialization)
final class InitializeResponse implements HasMeta {
  /// Capabilities supported by the agent.
  final AgentCapabilities agentCapabilities;

  /// Information about the Agent name and version sent to the Client.
  ///
  /// Note: in future versions of the protocol, this will be required.
  final ImplementationInfo? agentInfo;

  /// Authentication methods supported by the agent.
  final List<AuthMethod> authMethods;

  /// The protocol version the client specified if supported by the agent,
  /// or the latest protocol version supported by the agent.
  ///
  /// The client should disconnect, if it doesn't support this version.
  final int protocolVersion;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [InitializeResponse].
  const InitializeResponse({
    this.agentCapabilities = const AgentCapabilities(),
    this.agentInfo,
    this.authMethods = const [],
    required this.protocolVersion,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory InitializeResponse.fromJson(Map<String, dynamic> json) {
    final known = {
      'agentCapabilities',
      'agentInfo',
      'authMethods',
      'protocolVersion',
      '_meta',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return InitializeResponse(
      agentCapabilities:
          json['agentCapabilities'] is Map<String, dynamic>
              ? AgentCapabilities.fromJson(
                json['agentCapabilities'] as Map<String, dynamic>,
              )
              : const AgentCapabilities(),
      agentInfo:
          json['agentInfo'] is Map<String, dynamic>
              ? ImplementationInfo.fromJson(
                json['agentInfo'] as Map<String, dynamic>,
              )
              : null,
      authMethods:
          (json['authMethods'] as List<dynamic>?)
              ?.map((e) => AuthMethod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      protocolVersion: json['protocolVersion'] as int,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'agentCapabilities': agentCapabilities.toJson(),
    if (agentInfo != null) 'agentInfo': agentInfo!.toJson(),
    'authMethods': authMethods.map((e) => e.toJson()).toList(),
    'protocolVersion': protocolVersion,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request parameters for the authenticate method.
///
/// Specifies which authentication method to use.
final class AuthenticateRequest implements HasMeta {
  /// The ID of the authentication method to use.
  /// Must be one of the methods advertised in the initialize response.
  final String methodId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AuthenticateRequest].
  const AuthenticateRequest({
    required this.methodId,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AuthenticateRequest.fromJson(Map<String, dynamic> json) {
    final known = {'methodId', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthenticateRequest(
      methodId: json['methodId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'methodId': methodId,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to the `authenticate` method.
final class AuthenticateResponse implements HasMeta {
  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AuthenticateResponse].
  const AuthenticateResponse({this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory AuthenticateResponse.fromJson(Map<String, dynamic> json) {
    final known = {'_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthenticateResponse(
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
