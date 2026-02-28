/// Shared interface for types that carry an optional `_meta` bag.
abstract interface class HasMeta {
  /// Protocol-level metadata, serialized as `_meta` in JSON.
  Map<String, Object?>? get meta;
}
