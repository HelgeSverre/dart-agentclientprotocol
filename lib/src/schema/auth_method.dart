// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/has_meta.dart';

/// Describes an available authentication method.
final class AuthMethod implements HasMeta {
  /// Optional description providing more details about this authentication method.
  final String? description;

  /// Unique identifier for this authentication method.
  final String id;

  /// Human-readable name of the authentication method.
  final String name;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AuthMethod].
  const AuthMethod({
    this.description,
    required this.id,
    required this.name,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AuthMethod.fromJson(Map<String, dynamic> json) {
    final known = {'description', 'id', 'name', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AuthMethod(
      description: json['description'] as String?,
      id: json['id'] as String,
      name: json['name'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (description != null) 'description': description,
    'id': id,
    'name': name,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
