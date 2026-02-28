// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/has_meta.dart';

/// Metadata about the implementation of the client or agent.
/// Describes the name and version of an MCP implementation, with an optional
/// title for UI representation.
final class ImplementationInfo implements HasMeta {
  /// Intended for programmatic or logical use, but can be used as a display
  /// name fallback if title isn’t present.
  final String name;

  /// Intended for UI and end-user contexts — optimized to be human-readable
  /// and easily understood.
  ///
  /// If not provided, the name should be used for display.
  final String? title;

  /// Version of the implementation. Can be displayed to the user or used
  /// for debugging or metrics purposes. (e.g. "1.0.0").
  final String version;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ImplementationInfo].
  const ImplementationInfo({
    required this.name,
    this.title,
    required this.version,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ImplementationInfo.fromJson(Map<String, dynamic> json) {
    final known = {'name', 'title', 'version', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ImplementationInfo(
      name: json['name'] as String,
      title: json['title'] as String?,
      version: json['version'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (title != null) 'title': title,
    'version': version,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
