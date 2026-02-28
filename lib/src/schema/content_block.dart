import 'package:acp/src/schema/annotations.dart';
import 'package:acp/src/schema/has_meta.dart';

/// A content block in an ACP message.
///
/// Content blocks are discriminated by the `type` field with snake_case values.
/// Unknown types are captured as [UnknownContentBlock] for forward compatibility.
sealed class ContentBlock implements HasMeta {
  const ContentBlock();

  /// Deserializes a [ContentBlock] from JSON.
  ///
  /// Switches on the `type` discriminator field.
  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'text' => TextContent.fromJson(json),
      'image' => ImageContent.fromJson(json),
      'audio' => AudioContent.fromJson(json),
      'resource_link' => ResourceLink.fromJson(json),
      'resource' => EmbeddedResource.fromJson(json),
      _ => UnknownContentBlock.fromJson(json),
    };
  }

  /// Serializes this content block to JSON.
  Map<String, dynamic> toJson();
}

/// Plain text or markdown content.
final class TextContent extends ContentBlock {
  /// The text content.
  final String text;

  /// Optional annotations.
  final Annotations? annotations;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [TextContent].
  const TextContent({
    required this.text,
    this.annotations,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory TextContent.fromJson(Map<String, dynamic> json) {
    final known = {'type', 'text', 'annotations', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return TextContent(
      text: json['text'] as String,
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'text': text,
    if (annotations != null) 'annotations': annotations!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Base64-encoded image content.
final class ImageContent extends ContentBlock {
  /// Base64-encoded image data.
  final String data;

  /// MIME type (e.g. "image/png").
  final String mimeType;

  /// Optional URI for the image source.
  final String? uri;

  /// Optional annotations.
  final Annotations? annotations;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [ImageContent].
  const ImageContent({
    required this.data,
    required this.mimeType,
    this.uri,
    this.annotations,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ImageContent.fromJson(Map<String, dynamic> json) {
    final known = {'type', 'data', 'mimeType', 'uri', 'annotations', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ImageContent(
      data: json['data'] as String,
      mimeType: json['mimeType'] as String,
      uri: json['uri'] as String?,
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'data': data,
    'mimeType': mimeType,
    if (uri != null) 'uri': uri,
    if (annotations != null) 'annotations': annotations!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// Base64-encoded audio content.
final class AudioContent extends ContentBlock {
  /// Base64-encoded audio data.
  final String data;

  /// MIME type (e.g. "audio/wav").
  final String mimeType;

  /// Optional annotations.
  final Annotations? annotations;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [AudioContent].
  const AudioContent({
    required this.data,
    required this.mimeType,
    this.annotations,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory AudioContent.fromJson(Map<String, dynamic> json) {
    final known = {'type', 'data', 'mimeType', 'annotations', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return AudioContent(
      data: json['data'] as String,
      mimeType: json['mimeType'] as String,
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'audio',
    'data': data,
    'mimeType': mimeType,
    if (annotations != null) 'annotations': annotations!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A URI reference to a resource.
final class ResourceLink extends ContentBlock {
  /// URI of the resource.
  final String uri;

  /// Display name.
  final String name;

  /// Optional description.
  final String? description;

  /// Optional MIME type.
  final String? mimeType;

  /// Optional display title.
  final String? title;

  /// Optional file size in bytes.
  final int? size;

  /// Optional annotations.
  final Annotations? annotations;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates a [ResourceLink].
  const ResourceLink({
    required this.uri,
    required this.name,
    this.description,
    this.mimeType,
    this.title,
    this.size,
    this.annotations,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory ResourceLink.fromJson(Map<String, dynamic> json) {
    final known = {
      'type',
      'uri',
      'name',
      'description',
      'mimeType',
      'title',
      'size',
      'annotations',
      '_meta',
    };
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return ResourceLink(
      uri: json['uri'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      mimeType: json['mimeType'] as String?,
      title: json['title'] as String?,
      size: json['size'] as int?,
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'resource_link',
    'uri': uri,
    'name': name,
    if (description != null) 'description': description,
    if (mimeType != null) 'mimeType': mimeType,
    if (title != null) 'title': title,
    if (size != null) 'size': size,
    if (annotations != null) 'annotations': annotations!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// An inline embedded resource.
final class EmbeddedResource extends ContentBlock {
  /// The resource contents (text or blob, as raw JSON).
  final Map<String, dynamic> resource;

  /// Optional annotations.
  final Annotations? annotations;

  @override
  final Map<String, Object?>? meta;

  /// Unknown fields preserved for round-trip fidelity.
  final Map<String, Object?>? extensionData;

  /// Creates an [EmbeddedResource].
  const EmbeddedResource({
    required this.resource,
    this.annotations,
    this.meta,
    this.extensionData,
  });

  /// Deserializes from JSON.
  factory EmbeddedResource.fromJson(Map<String, dynamic> json) {
    final known = {'type', 'resource', 'annotations', '_meta'};
    final extension = Map<String, Object?>.fromEntries(
      json.entries.where((e) => !known.contains(e.key)),
    );
    return EmbeddedResource(
      resource: json['resource'] as Map<String, dynamic>,
      annotations:
          json['annotations'] is Map<String, dynamic>
              ? Annotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
              : null,
      meta: json['_meta'] as Map<String, Object?>?,
      extensionData: extension.isEmpty ? null : extension,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'resource',
    'resource': resource,
    if (annotations != null) 'annotations': annotations!.toJson(),
    if (meta != null) '_meta': meta,
    if (extensionData != null) ...extensionData!,
  };
}

/// A content block with an unknown type, preserved for forward compatibility.
final class UnknownContentBlock extends ContentBlock {
  /// The unknown type value.
  final String? type;

  /// The raw JSON object, preserved as-is.
  final Map<String, dynamic> rawJson;

  @override
  final Map<String, Object?>? meta;

  /// Creates an [UnknownContentBlock].
  const UnknownContentBlock({this.type, required this.rawJson, this.meta});

  /// Deserializes from JSON.
  factory UnknownContentBlock.fromJson(Map<String, dynamic> json) {
    return UnknownContentBlock(
      type: json['type'] as String?,
      rawJson: json,
      meta: json['_meta'] as Map<String, Object?>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => rawJson;
}
