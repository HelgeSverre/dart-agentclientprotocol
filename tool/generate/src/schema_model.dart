/// In-memory representation of parsed schema types.
library;

/// The full parsed schema definition.
class SchemaDefinition {
  /// All type definitions keyed by their schema name.
  final Map<String, TypeDef> types;

  SchemaDefinition(this.types);
}

/// A single type definition.
sealed class TypeDef {
  /// The original schema name (e.g. "TextContent").
  final String schemaName;

  /// The Dart class name to use.
  final String dartName;

  /// Description from the schema.
  final String? description;

  TypeDef({required this.schemaName, required this.dartName, this.description});
}

/// A struct type with named fields.
class StructType extends TypeDef {
  final List<FieldDef> fields;
  final Set<String> required;

  /// Whether this type has a `_meta` property in the schema.
  final bool hasMeta;

  StructType({
    required super.schemaName,
    required super.dartName,
    super.description,
    required this.fields,
    required this.required,
    this.hasMeta = true,
  });
}

/// A sealed (discriminated union) type.
class SealedType extends TypeDef {
  /// The JSON key used as discriminator (e.g. "type", "sessionUpdate").
  final String discriminatorField;

  /// The variants of this union.
  final List<SealedVariant> variants;

  SealedType({
    required super.schemaName,
    required super.dartName,
    super.description,
    required this.discriminatorField,
    required this.variants,
  });
}

/// A variant of a sealed type.
class SealedVariant {
  /// The discriminator value (e.g. "text", "agent_message_chunk").
  final String discriminatorValue;

  /// The Dart class name for this variant.
  final String dartName;

  /// The schema name of the referenced type (from $ref), if any.
  final String? refType;

  /// Fields specific to this variant (from the referenced type).
  final List<FieldDef> fields;

  /// Required field names.
  final Set<String> required;

  /// Description from the schema.
  final String? description;

  /// Whether this variant has a `_meta` property.
  final bool hasMeta;

  SealedVariant({
    required this.discriminatorValue,
    required this.dartName,
    this.refType,
    required this.fields,
    required this.required,
    this.description,
    this.hasMeta = true,
  });
}

/// An enum type with string values.
class EnumType extends TypeDef {
  /// Enum values: Dart enum value name → wire-format string.
  final List<EnumValue> values;

  EnumType({
    required super.schemaName,
    required super.dartName,
    super.description,
    required this.values,
  });
}

/// A single enum value.
class EnumValue {
  /// The Dart enum value name (e.g. "endTurn").
  final String dartName;

  /// The wire-format string (e.g. "end_turn").
  final String wireValue;

  /// Description from the schema.
  final String? description;

  EnumValue({
    required this.dartName,
    required this.wireValue,
    this.description,
  });
}

/// A field definition within a struct.
class FieldDef {
  /// The Dart field name (camelCase).
  final String dartName;

  /// The JSON key name.
  final String jsonKey;

  /// The Dart type.
  final FieldType type;

  /// Whether this field is required.
  final bool isRequired;

  /// Default value expression (Dart literal).
  final String? defaultValue;

  /// Description from the schema.
  final String? description;

  FieldDef({
    required this.dartName,
    required this.jsonKey,
    required this.type,
    required this.isRequired,
    this.defaultValue,
    this.description,
  });
}

/// Represents a Dart type for a field.
sealed class FieldType {
  const FieldType();

  /// Returns the Dart type string.
  String get dartType;

  /// Whether this type is nullable.
  bool get isNullable => false;
}

class StringFieldType extends FieldType {
  const StringFieldType();

  @override
  String get dartType => 'String';
}

class IntFieldType extends FieldType {
  const IntFieldType();

  @override
  String get dartType => 'int';
}

class BoolFieldType extends FieldType {
  const BoolFieldType();

  @override
  String get dartType => 'bool';
}

class DoubleFieldType extends FieldType {
  const DoubleFieldType();

  @override
  String get dartType => 'double';
}

class NullableFieldType extends FieldType {
  final FieldType inner;

  const NullableFieldType(this.inner);

  @override
  String get dartType => '${inner.dartType}?';

  @override
  bool get isNullable => true;
}

class ListFieldType extends FieldType {
  final FieldType element;

  const ListFieldType(this.element);

  @override
  String get dartType => 'List<${element.dartType}>';
}

class MapFieldType extends FieldType {
  const MapFieldType();

  @override
  String get dartType => 'Map<String, dynamic>';
}

class RefFieldType extends FieldType {
  /// The Dart class name being referenced.
  final String dartClassName;

  const RefFieldType(this.dartClassName);

  @override
  String get dartType => dartClassName;
}

class DynamicFieldType extends FieldType {
  const DynamicFieldType();

  @override
  String get dartType => 'Object?';
}
