import 'package:acp/src/schema/auth_method.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/has_meta.dart';
import 'package:acp/src/schema/implementation_info.dart';

/// Request parameters for the `initialize` method.
///
/// Sent by the client to establish the connection and negotiate capabilities.
final class InitializeRequest implements HasMeta {
  /// The latest protocol version supported by the client.
  ///
  /// Protocol version is a u16 integer. Current latest is `1`.
  final int protocolVersion;

  /// Capabilities supported by the client.
  final ClientCapabilities clientCapabilities;

  /// Information about the client implementation.
  final ImplementationInfo? clientInfo;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const InitializeRequest({
    required this.protocolVersion,
    this.clientCapabilities = const ClientCapabilities(),
    this.clientInfo,
    this.meta,
    this.extensionData,
  });

  factory InitializeRequest.fromJson(Map<String, dynamic> json) {
    final known = {
      'protocolVersion',
      'clientCapabilities',
      'clientInfo',
      '_meta',
    };
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return InitializeRequest(
      protocolVersion: json['protocolVersion'] as int,
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
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  Map<String, dynamic> toJson() => {
    'protocolVersion': protocolVersion,
    'clientCapabilities': clientCapabilities.toJson(),
    if (clientInfo != null) 'clientInfo': clientInfo!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Response to the `initialize` method.
///
/// Contains the negotiated protocol version and agent capabilities.
final class InitializeResponse implements HasMeta {
  /// The protocol version agreed upon.
  final int protocolVersion;

  /// Capabilities supported by the agent.
  final AgentCapabilities agentCapabilities;

  /// Authentication methods supported by the agent.
  final List<AuthMethod> authMethods;

  /// Information about the agent implementation.
  final ImplementationInfo? agentInfo;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const InitializeResponse({
    required this.protocolVersion,
    this.agentCapabilities = const AgentCapabilities(),
    this.authMethods = const [],
    this.agentInfo,
    this.meta,
    this.extensionData,
  });

  factory InitializeResponse.fromJson(Map<String, dynamic> json) {
    final known = {
      'protocolVersion',
      'agentCapabilities',
      'authMethods',
      'agentInfo',
      '_meta',
    };
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return InitializeResponse(
      protocolVersion: json['protocolVersion'] as int,
      agentCapabilities:
          json['agentCapabilities'] is Map<String, dynamic>
              ? AgentCapabilities.fromJson(
                json['agentCapabilities'] as Map<String, dynamic>,
              )
              : const AgentCapabilities(),
      authMethods:
          (json['authMethods'] as List<dynamic>?)
              ?.map((e) => AuthMethod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      agentInfo:
          json['agentInfo'] is Map<String, dynamic>
              ? ImplementationInfo.fromJson(
                json['agentInfo'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  Map<String, dynamic> toJson() => {
    'protocolVersion': protocolVersion,
    'agentCapabilities': agentCapabilities.toJson(),
    'authMethods': authMethods.map((e) => e.toJson()).toList(),
    if (agentInfo != null) 'agentInfo': agentInfo!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Request parameters for the `authenticate` method.
final class AuthenticateRequest implements HasMeta {
  /// The ID of the authentication method to use.
  final String methodId;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const AuthenticateRequest({
    required this.methodId,
    this.meta,
    this.extensionData,
  });

  factory AuthenticateRequest.fromJson(Map<String, dynamic> json) {
    final known = {'methodId', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthenticateRequest(
      methodId: json['methodId'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

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

  const AuthenticateResponse({this.meta, this.extensionData});

  factory AuthenticateResponse.fromJson(Map<String, dynamic> json) {
    final known = <String>{'_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthenticateResponse(
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  Map<String, dynamic> toJson() => {
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
