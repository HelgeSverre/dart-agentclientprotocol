// GENERATED CODE — DO NOT EDIT.
//
// Source: tool/upstream/schema/schema.json
// Run `dart run tool/generate/generate.dart` to regenerate.

import 'package:acp/src/schema/annotations.dart';
import 'package:acp/src/schema/has_meta.dart';

/// Content blocks represent displayable information in the Agent Client Protocol.
///
/// They provide a structured way to handle various types of user-facing content—whether
/// it's text from language models, images for analysis, or embedded resources for context.
///
/// Content blocks appear in:
/// - User prompts sent via `session/prompt`
/// - Language model output streamed through `session/update` notifications
/// - Progress updates and results from tool calls
///
/// This structure is compatible with the Model Context Protocol (MCP), enabling
/// agents to seamlessly forward content from MCP tool outputs without transformation.
///
/// See protocol docs: [Content](https://agentclientprotocol.com/protocol/content)
sealed class ContentBlock implements HasMeta {
  const ContentBlock();

  /// Deserializes a [ContentBlock] from JSON.
  ///
  /// Switches on the `type` discriminator field.
  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      return UnknownContentBlock(rawJson: json);
    }
    return switch (type) {
      'text' => TextContent.fromJson(json),
      'image' => ImageContent.fromJson(json),
      'audio' => AudioContent.fromJson(json),
      'resource_link' => ResourceLink.fromJson(json),
      'resource' => EmbeddedResource.fromJson(json),
      _ => UnknownContentBlock(
        type: type,
        rawJson: json,
        meta: json['_meta'] as Map<String, Object?>?,
      ),
    };
  }

  /// Serializes this contentBlock to JSON.
  Map<String, dynamic> toJson();
}

/// Text content. May be plain text or formatted with Markdown.
///
/// All agents MUST support text content blocks in prompts.
/// Clients SHOULD render this text as Markdown.
final class TextContent extends ContentBlock {
  /// Optional annotations for this content.
  final Annotations? annotations;

  /// The text content.
  final String text;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [TextContent].
  const TextContent({
    this.annotations,
    required this.text,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory TextContent.fromJson(Map<String, dynamic> json) {
    final known = {'annotations', 'text', '_meta', 'type'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return TextContent(
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      text: json['text'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    if (annotations != null) 'annotations': annotations!.toJson(),
    'text': text,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Images for visual context or analysis.
///
/// Requires the `image` prompt capability when included in prompts.
final class ImageContent extends ContentBlock {
  /// Optional annotations for this content.
  final Annotations? annotations;

  /// Base64-encoded image data.
  final String data;

  /// The MIME type of the image.
  final String mimeType;

  /// Optional URI for the original image source.
  final String? uri;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ImageContent].
  const ImageContent({
    this.annotations,
    required this.data,
    required this.mimeType,
    this.uri,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ImageContent.fromJson(Map<String, dynamic> json) {
    final known = {'annotations', 'data', 'mimeType', 'uri', '_meta', 'type'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ImageContent(
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      data: json['data'] as String,
      mimeType: json['mimeType'] as String,
      uri: json['uri'] as String?,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    if (annotations != null) 'annotations': annotations!.toJson(),
    'data': data,
    'mimeType': mimeType,
    if (uri != null) 'uri': uri,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Audio data for transcription or analysis.
///
/// Requires the `audio` prompt capability when included in prompts.
final class AudioContent extends ContentBlock {
  /// Optional annotations for this content.
  final Annotations? annotations;

  /// Base64-encoded audio data.
  final String data;

  /// The MIME type of the audio.
  final String mimeType;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AudioContent].
  const AudioContent({
    this.annotations,
    required this.data,
    required this.mimeType,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AudioContent.fromJson(Map<String, dynamic> json) {
    final known = {'annotations', 'data', 'mimeType', '_meta', 'type'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AudioContent(
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      data: json['data'] as String,
      mimeType: json['mimeType'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'audio',
    if (annotations != null) 'annotations': annotations!.toJson(),
    'data': data,
    'mimeType': mimeType,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// References to resources that the agent can access.
///
/// All agents MUST support resource links in prompts.
final class ResourceLink extends ContentBlock {
  /// Optional annotations for this resource link.
  final Annotations? annotations;

  /// A human-readable description of the resource.
  final String? description;

  /// The MIME type of the resource.
  final String? mimeType;

  /// The display name of the resource.
  final String name;

  /// The size of the resource in bytes.
  final int? size;

  /// An optional title for the resource.
  final String? title;

  /// The URI of the linked resource.
  final String uri;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ResourceLink].
  const ResourceLink({
    this.annotations,
    this.description,
    this.mimeType,
    required this.name,
    this.size,
    this.title,
    required this.uri,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ResourceLink.fromJson(Map<String, dynamic> json) {
    final known = {
      'annotations',
      'description',
      'mimeType',
      'name',
      'size',
      'title',
      'uri',
      '_meta',
      'type',
    };
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ResourceLink(
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      description: json['description'] as String?,
      mimeType: json['mimeType'] as String?,
      name: json['name'] as String,
      size: json['size'] as int?,
      title: json['title'] as String?,
      uri: json['uri'] as String,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'resource_link',
    if (annotations != null) 'annotations': annotations!.toJson(),
    if (description != null) 'description': description,
    if (mimeType != null) 'mimeType': mimeType,
    'name': name,
    if (size != null) 'size': size,
    if (title != null) 'title': title,
    'uri': uri,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Complete resource contents embedded directly in the message.
///
/// Preferred for including context as it avoids extra round-trips.
///
/// Requires the `embeddedContext` prompt capability when included in prompts.
final class EmbeddedResource extends ContentBlock {
  /// Optional annotations for this embedded resource.
  final Annotations? annotations;

  /// The embedded resource contents.
  final Map<String, dynamic> resource;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [EmbeddedResource].
  const EmbeddedResource({
    this.annotations,
    required this.resource,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory EmbeddedResource.fromJson(Map<String, dynamic> json) {
    final known = {'annotations', 'resource', '_meta', 'type'};
    final ext = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return EmbeddedResource(
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      resource: json['resource'] as Map<String, dynamic>,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: ext.isEmpty ? null : ext,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'resource',
    if (annotations != null) 'annotations': annotations!.toJson(),
    'resource': resource,
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A contentBlock with an unknown type, preserved for forward compatibility.
final class UnknownContentBlock extends ContentBlock {
  /// The unknown discriminator value.
  final String? type;

  /// The raw JSON object, preserved as-is.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [UnknownContentBlock].
  const UnknownContentBlock({this.type, required this.rawJson, this.meta});

  @override
  Map<String, dynamic> toJson() => rawJson;
}
