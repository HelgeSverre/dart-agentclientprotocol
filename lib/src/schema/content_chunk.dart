// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/has_meta.dart';

/// A streamed item of content
final class ContentChunk implements HasMeta {
  /// A single item of content
  final ContentBlock content;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ContentChunk].
  const ContentChunk({required this.content, this.meta, this.extensionData});

  /// Deserializes from JSON.
  factory ContentChunk.fromJson(Map<String, dynamic> json) {
    final known = {'content', '_meta'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ContentChunk(
      content: ContentBlock.fromJson(json['content'] as Map<String, dynamic>),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'content': content.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
