import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/has_meta.dart';

/// A streamed item of content, used in session update variants.
final class ContentChunk implements HasMeta {
  /// The content block.
  final ContentBlock content;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  const ContentChunk({required this.content, this.meta, this.extensionData});

  factory ContentChunk.fromJson(Map<String, dynamic> json) {
    final known = {'content', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ContentChunk(
      content: ContentBlock.fromJson(json['content'] as Map<String, dynamic>),
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}
