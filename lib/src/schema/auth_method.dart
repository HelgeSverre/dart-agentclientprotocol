import 'package:acp/src/schema/has_meta.dart';

/// An authentication method advertised by the agent.
///
/// Auth methods are plain structs identified by their [id] string.
/// The type of authentication (agent-managed, environment variable, terminal)
/// is determined by the [id] convention, not by a discriminator field.
final class AuthMethod implements HasMeta {
  /// Unique identifier for this auth method.
  final String id;

  /// Human-readable name.
  final String name;

  /// Optional description.
  final String? description;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AuthMethod].
  const AuthMethod({
    required this.id,
    required this.name,
    this.description,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AuthMethod.fromJson(Map<String, dynamic> json) {
    final known = {'id', 'name', 'description', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
