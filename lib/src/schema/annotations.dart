import 'package:acp/src/schema/has_meta.dart';

/// Optional annotations for content blocks.
final class Annotations implements HasMeta {
  /// Intended audience roles.
  final List<String>? audience;

  /// Last modified timestamp.
  final String? lastModified;

  /// Priority value.
  final double? priority;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [Annotations] instance.
  const Annotations({
    this.audience,
    this.lastModified,
    this.priority,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory Annotations.fromJson(Map<String, dynamic> json) {
    final known = {'audience', 'lastModified', 'priority', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return Annotations(
      audience: (json['audience'] as List<dynamic>?)?.cast<String>(),
      lastModified: json['lastModified'] as String?,
      priority: (json['priority'] as num?)?.toDouble(),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (audience != null) 'audience': audience,
    if (lastModified != null) 'lastModified': lastModified,
    if (priority != null) 'priority': priority,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
