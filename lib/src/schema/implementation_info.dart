import 'package:acp/src/schema/has_meta.dart';

/// Metadata about a client or agent implementation.
///
/// Describes the name, version, and optional display title of an ACP
/// client or agent.
final class ImplementationInfo implements HasMeta {
  /// Programmatic name of the implementation.
  final String name;

  /// Human-readable display title. Falls back to [name] if not provided.
  final String? title;

  /// Version string (e.g. "1.0.0").
  final String version;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const ImplementationInfo({
    required this.name,
    this.title,
    required this.version,
    this.meta,
    this.extensionData,
  });

  factory ImplementationInfo.fromJson(Map<String, dynamic> json) {
    final known = {'name', 'version', 'title', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ImplementationInfo(
      name: json['name'] as String,
      title: json['title'] as String?,
      version: json['version'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (title != null) 'title': title,
    'version': version,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
