/// Parses JSON Schema `$defs` into [SchemaDefinition].
library;

import 'dart:convert';
import 'dart:io';

import 'schema_model.dart';

/// Name overrides: schema name → Dart class name.
const _nameOverrides = <String, String>{'Implementation': 'ImplementationInfo'};

/// Variant class name overrides: "ParentSchemaName.RawDartName" → final Dart name.
/// The key uses the PascalCase of the discriminator value (since schema variants
/// have no `title` field). This ensures generated variant class names match the
/// hand-written code.
const _variantNameOverrides = <String, String>{
  // ContentBlock variants (disc → PascalCase: Text, Image, Audio, Resource):
  'ContentBlock.Text': 'TextContent',
  'ContentBlock.Image': 'ImageContent',
  'ContentBlock.Audio': 'AudioContent',
  'ContentBlock.Resource': 'EmbeddedResource',
  // ResourceLink stays the same (disc=resource_link → ResourceLink).

  // SessionUpdate variants (disc → PascalCase):
  'SessionUpdate.ToolCall': 'ToolCallSessionUpdate',
  'SessionUpdate.ToolCallUpdate': 'ToolCallDeltaSessionUpdate',
  'SessionUpdate.Plan': 'PlanUpdate',
  'SessionUpdate.AvailableCommandsUpdate': 'AvailableCommandsSessionUpdate',
  'SessionUpdate.CurrentModeUpdate': 'CurrentModeSessionUpdate',
  'SessionUpdate.ConfigOptionUpdate': 'ConfigOptionSessionUpdate',
};

/// Types to skip entirely (internal routing types, not user-facing).
const _skipTypes = <String>{
  'AgentNotification',
  'AgentRequest',
  'AgentResponse',
  'ClientNotification',
  'ClientRequest',
  'ClientResponse',
};

/// Types that are simple aliases (scalar wrappers) — skip code generation.
const _aliasTypes = <String>{
  'ProtocolVersion',
  'SessionId',
  'RequestId',
  'ToolCallId',
  'PermissionOptionId',
  'SessionConfigGroupId',
  'SessionConfigId',
  'SessionConfigValueId',
  'SessionModeId',
  'SessionConfigOptionCategory',
};

/// Parses the schema JSON file and returns a [SchemaDefinition].
SchemaDefinition parseSchemaFile(String path) {
  final content = File(path).readAsStringSync();
  final json = jsonDecode(content) as Map<String, dynamic>;
  return parseSchema(json);
}

/// Parses a schema JSON object into a [SchemaDefinition].
SchemaDefinition parseSchema(Map<String, dynamic> json) {
  final defs = json[r'$defs'] as Map<String, dynamic>? ?? {};
  final types = <String, TypeDef>{};

  for (final entry in defs.entries) {
    final name = entry.key;
    final def = entry.value as Map<String, dynamic>;

    // Skip ignored and alias types.
    if (_skipTypes.contains(name)) continue;
    if (_aliasTypes.contains(name)) continue;
    if (def['x-docs-ignore'] == true) continue;

    final typeDef = _parseDef(name, def, defs);
    if (typeDef != null) {
      types[name] = typeDef;
    }
  }

  return SchemaDefinition(types);
}

String _dartName(String schemaName) {
  return _nameOverrides[schemaName] ?? schemaName;
}

TypeDef? _parseDef(
  String name,
  Map<String, dynamic> def,
  Map<String, dynamic> allDefs,
) {
  final description = def['description'] as String?;

  // Check for discriminated union (sealed type).
  if (def.containsKey('discriminator') && def.containsKey('oneOf')) {
    return _parseSealedType(name, def, allDefs);
  }

  // Check for enum (oneOf with all const strings).
  if (def.containsKey('oneOf') && !def.containsKey('properties')) {
    final oneOf = def['oneOf'] as List<dynamic>;
    if (_isStringEnum(oneOf)) {
      return _parseEnumType(name, def, oneOf);
    }
    // Non-enum oneOf without discriminator — skip or treat as alias.
    return null;
  }

  // Check for enum via "enum" keyword.
  if (def.containsKey('enum')) {
    final values = def['enum'] as List<dynamic>;
    return EnumType(
      schemaName: name,
      dartName: _dartName(name),
      description: description,
      values:
          values
              .map(
                (v) => EnumValue(
                  dartName: _snakeToCamel(v.toString()),
                  wireValue: v.toString(),
                ),
              )
              .toList(),
    );
  }

  // Check for anyOf — these are typically untagged unions or aliases.
  if (def.containsKey('anyOf') && !def.containsKey('properties')) {
    // Skip complex anyOf types for now.
    return null;
  }

  // Struct type (has properties).
  if (def.containsKey('properties')) {
    return _parseStructType(name, def, allDefs);
  }

  // Simple scalar type — skip.
  return null;
}

StructType _parseStructType(
  String name,
  Map<String, dynamic> def,
  Map<String, dynamic> allDefs,
) {
  final props = def['properties'] as Map<String, dynamic>? ?? {};
  final requiredList =
      (def['required'] as List<dynamic>?)?.cast<String>().toSet() ?? {};
  final description = def['description'] as String?;

  final fields = <FieldDef>[];
  var hasMeta = false;

  for (final entry in props.entries) {
    final key = entry.key;
    final propDef = entry.value as Map<String, dynamic>;

    if (key == '_meta') {
      hasMeta = true;
      continue; // _meta is handled specially as HasMeta.
    }

    final fieldType = _resolveFieldType(propDef, allDefs);
    final isRequired = requiredList.contains(key);
    var defaultValue = _resolveDefault(propDef, fieldType, allDefs);

    // Convention: required list fields without a schema default get const []
    // in the Dart constructor (matching hand-written code pattern).
    if (defaultValue == null && fieldType is ListFieldType) {
      defaultValue = 'const []';
    }

    fields.add(
      FieldDef(
        dartName: _jsonKeyToDartName(key),
        jsonKey: key,
        type: fieldType,
        isRequired: isRequired,
        defaultValue: defaultValue,
        description: propDef['description'] as String?,
      ),
    );
  }

  return StructType(
    schemaName: name,
    dartName: _dartName(name),
    description: description,
    fields: fields,
    required: requiredList..remove('_meta'),
    hasMeta: hasMeta,
  );
}

SealedType _parseSealedType(
  String name,
  Map<String, dynamic> def,
  Map<String, dynamic> allDefs,
) {
  final disc = def['discriminator'] as Map<String, dynamic>;
  final discField = disc['propertyName'] as String;
  final oneOf = def['oneOf'] as List<dynamic>;
  final description = def['description'] as String?;

  final variants = <SealedVariant>[];
  for (final variant in oneOf) {
    final v = variant as Map<String, dynamic>;
    final parsed = _parseSealedVariant(
      v,
      discField,
      allDefs,
      parentSchemaName: name,
    );
    if (parsed != null) {
      variants.add(parsed);
    }
  }

  return SealedType(
    schemaName: name,
    dartName: _dartName(name),
    description: description,
    discriminatorField: discField,
    variants: variants,
  );
}

SealedVariant? _parseSealedVariant(
  Map<String, dynamic> variantDef,
  String discField,
  Map<String, dynamic> allDefs, {
  required String parentSchemaName,
}) {
  // Extract discriminator value.
  final props = variantDef['properties'] as Map<String, dynamic>?;
  if (props == null) return null;
  final discProp = props[discField] as Map<String, dynamic>?;
  if (discProp == null) return null;
  final discValue = discProp['const'] as String?;
  if (discValue == null) return null;

  // Find $ref if present (via allOf).
  String? refTypeName;
  if (variantDef.containsKey('allOf')) {
    final allOf = variantDef['allOf'] as List<dynamic>;
    for (final item in allOf) {
      final m = item as Map<String, dynamic>;
      if (m.containsKey(r'$ref')) {
        final ref = m[r'$ref'] as String;
        refTypeName = ref.split('/').last;
        break;
      }
    }
  }

  // Resolve fields from the referenced type.
  final fields = <FieldDef>[];
  var required = <String>{};
  var hasMeta = false;

  if (refTypeName != null && allDefs.containsKey(refTypeName)) {
    final refDef = allDefs[refTypeName] as Map<String, dynamic>;
    final refProps = refDef['properties'] as Map<String, dynamic>? ?? {};
    final refRequired =
        (refDef['required'] as List<dynamic>?)?.cast<String>().toSet() ?? {};

    for (final entry in refProps.entries) {
      final key = entry.key;
      final propDef = entry.value as Map<String, dynamic>;
      if (key == '_meta') {
        hasMeta = true;
        continue;
      }
      final fieldType = _resolveFieldType(propDef, allDefs);
      fields.add(
        FieldDef(
          dartName: _jsonKeyToDartName(key),
          jsonKey: key,
          type: fieldType,
          isRequired: refRequired.contains(key),
          defaultValue: _resolveDefault(propDef, fieldType, allDefs),
          description: propDef['description'] as String?,
        ),
      );
    }
    required = refRequired..remove('_meta');
  }

  // Determine Dart class name for the variant.
  final rawDartName =
      variantDef['title'] as String? ?? _snakeToPascal(discValue);
  final overrideKey = '$parentSchemaName.$rawDartName';
  final dartName = _variantNameOverrides[overrideKey] ?? _dartName(rawDartName);

  return SealedVariant(
    discriminatorValue: discValue,
    dartName: dartName,
    refType: refTypeName != null ? _dartName(refTypeName) : null,
    fields: fields,
    required: required,
    description: variantDef['description'] as String?,
    hasMeta: hasMeta,
  );
}

EnumType _parseEnumType(
  String name,
  Map<String, dynamic> def,
  List<dynamic> oneOf,
) {
  final description = def['description'] as String?;
  final values = <EnumValue>[];

  for (final item in oneOf) {
    final m = item as Map<String, dynamic>;
    final wireValue = m['const'] as String;
    values.add(
      EnumValue(
        dartName: _snakeToCamel(wireValue),
        wireValue: wireValue,
        description: m['description'] as String?,
      ),
    );
  }

  return EnumType(
    schemaName: name,
    dartName: _dartName(name),
    description: description,
    values: values,
  );
}

bool _isStringEnum(List<dynamic> oneOf) {
  return oneOf.every((item) {
    final m = item as Map<String, dynamic>;
    return m.containsKey('const') && m['type'] == 'string';
  });
}

FieldType _resolveFieldType(
  Map<String, dynamic> propDef,
  Map<String, dynamic> allDefs,
) {
  // Direct $ref.
  if (propDef.containsKey(r'$ref')) {
    final ref = propDef[r'$ref'] as String;
    final refName = ref.split('/').last;
    return _refToFieldType(refName, allDefs);
  }

  // allOf with single $ref (wrapper pattern).
  if (propDef.containsKey('allOf')) {
    final allOf = propDef['allOf'] as List<dynamic>;
    for (final item in allOf) {
      final m = item as Map<String, dynamic>;
      if (m.containsKey(r'$ref')) {
        final ref = m[r'$ref'] as String;
        final refName = ref.split('/').last;
        return _refToFieldType(refName, allDefs);
      }
    }
  }

  // anyOf — typically a nullable type: [{$ref: ...}, {type: "null"}].
  if (propDef.containsKey('anyOf')) {
    final anyOf = propDef['anyOf'] as List<dynamic>;
    final nonNull =
        anyOf.where((item) {
          final m = item as Map<String, dynamic>;
          return m['type'] != 'null';
        }).toList();

    if (nonNull.length == 1) {
      final inner = _resolveFieldType(
        nonNull.first as Map<String, dynamic>,
        allDefs,
      );
      return NullableFieldType(inner);
    }
    // Complex anyOf — use Map<String, dynamic>.
    return const MapFieldType();
  }

  final type = propDef['type'];

  // Array type: ["string", "null"] or ["object", "null"] etc.
  if (type is List) {
    final types = type.cast<String>();
    final isNullable = types.contains('null');
    final nonNullTypes = types.where((t) => t != 'null').toList();

    if (nonNullTypes.length == 1) {
      final inner = _primitiveType(nonNullTypes.first, propDef, allDefs);
      return isNullable ? NullableFieldType(inner) : inner;
    }
    return isNullable
        ? const NullableFieldType(MapFieldType())
        : const MapFieldType();
  }

  if (type is String) {
    return _primitiveType(type, propDef, allDefs);
  }

  // No type specified — use dynamic.
  return const MapFieldType();
}

FieldType _primitiveType(
  String type,
  Map<String, dynamic> propDef,
  Map<String, dynamic> allDefs,
) {
  switch (type) {
    case 'string':
      return const StringFieldType();
    case 'integer':
      return const IntFieldType();
    case 'boolean':
      return const BoolFieldType();
    case 'number':
      return const DoubleFieldType();
    case 'array':
      final items = propDef['items'] as Map<String, dynamic>?;
      if (items != null) {
        final elementType = _resolveFieldType(items, allDefs);
        return ListFieldType(elementType);
      }
      return const ListFieldType(DynamicFieldType());
    case 'object':
      return const MapFieldType();
    default:
      return const MapFieldType();
  }
}

FieldType _refToFieldType(String refName, Map<String, dynamic> allDefs) {
  // Check if the referenced type is a simple alias.
  if (_aliasTypes.contains(refName)) {
    final refDef = allDefs[refName] as Map<String, dynamic>?;
    if (refDef != null) {
      final type = refDef['type'];
      if (type == 'string') return const StringFieldType();
      if (type == 'integer') return const IntFieldType();
    }
    return const StringFieldType(); // Default for ID aliases.
  }

  // Check if it's an enum-like type.
  final refDef = allDefs[refName] as Map<String, dynamic>?;
  if (refDef != null) {
    // Simple string enum via "enum" keyword (e.g. Role).
    if (refDef.containsKey('enum') && refDef['type'] == 'string') {
      return const StringFieldType();
    }

    // ErrorCode, anyOf with consts — use base type.
    if (!refDef.containsKey('properties') &&
        !refDef.containsKey('discriminator') &&
        refDef.containsKey('anyOf') &&
        !refDef.containsKey('oneOf')) {
      // Complex union type — use Map.
      return const MapFieldType();
    }
  }

  return RefFieldType(_dartName(refName));
}

String? _resolveDefault(
  Map<String, dynamic> propDef,
  FieldType fieldType,
  Map<String, dynamic> allDefs,
) {
  final defaultVal = propDef['default'];
  if (defaultVal == null) return null;

  if (defaultVal is bool) return defaultVal.toString();
  if (defaultVal is int) return defaultVal.toString();
  if (defaultVal is double) return defaultVal.toString();
  if (defaultVal is String) return "'$defaultVal'";

  if (defaultVal is List && defaultVal.isEmpty) return 'const []';
  if (defaultVal is Map) {
    // Default object for a $ref type → use const constructor.
    final ref = _findRef(propDef);
    if (ref != null) {
      final dartName = _dartName(ref);
      return 'const $dartName()';
    }
    return null;
  }

  return null;
}

String? _findRef(Map<String, dynamic> propDef) {
  if (propDef.containsKey(r'$ref')) {
    return (propDef[r'$ref'] as String).split('/').last;
  }
  if (propDef.containsKey('allOf')) {
    final allOf = propDef['allOf'] as List<dynamic>;
    for (final item in allOf) {
      final m = item as Map<String, dynamic>;
      if (m.containsKey(r'$ref')) {
        return (m[r'$ref'] as String).split('/').last;
      }
    }
  }
  return null;
}

/// Converts a JSON key like "sessionId" to a Dart field name.
/// Most keys are already camelCase, but some edge cases exist.
String _jsonKeyToDartName(String key) {
  // Already camelCase in the schema.
  return key;
}

/// Replaces [RefFieldType] references to types not in [availableTypes] with
/// [MapFieldType], and replaces refs to enum types with [StringFieldType].
///
/// [availableTypes] is the set of Dart class names that are accessible from
/// the file being generated (types in this file + imported files).
/// [enumTypeNames] is the set of Dart names that are enum types.
TypeDef resolveRefsForFile(
  TypeDef def,
  Set<String> availableTypes,
  Set<String> enumTypeNames,
) {
  switch (def) {
    case StructType():
      return StructType(
        schemaName: def.schemaName,
        dartName: def.dartName,
        description: def.description,
        fields:
            def.fields
                .map((f) => _resolveField(f, availableTypes, enumTypeNames))
                .toList(),
        required: def.required,
        hasMeta: def.hasMeta,
      );
    case SealedType():
      return SealedType(
        schemaName: def.schemaName,
        dartName: def.dartName,
        description: def.description,
        discriminatorField: def.discriminatorField,
        variants:
            def.variants
                .map(
                  (v) => SealedVariant(
                    discriminatorValue: v.discriminatorValue,
                    dartName: v.dartName,
                    refType: v.refType,
                    fields:
                        v.fields
                            .map(
                              (f) => _resolveField(
                                f,
                                availableTypes,
                                enumTypeNames,
                              ),
                            )
                            .toList(),
                    required: v.required,
                    description: v.description,
                    hasMeta: v.hasMeta,
                  ),
                )
                .toList(),
      );
    case EnumType():
      return def;
  }
}

FieldDef _resolveField(
  FieldDef field,
  Set<String> available,
  Set<String> enums,
) {
  return FieldDef(
    dartName: field.dartName,
    jsonKey: field.jsonKey,
    type: _resolveFieldTypeRef(field.type, available, enums),
    isRequired: field.isRequired,
    defaultValue: _resolveDefaultRef(field.defaultValue, available),
    description: field.description,
  );
}

FieldType _resolveFieldTypeRef(
  FieldType type,
  Set<String> available,
  Set<String> enums,
) {
  switch (type) {
    case RefFieldType():
      // Enum types → use String (matching hand-written code pattern).
      if (enums.contains(type.dartClassName)) {
        return const StringFieldType();
      }
      // Types not available in this file → use Map<String, dynamic>.
      if (!available.contains(type.dartClassName)) {
        return const MapFieldType();
      }
      return type;
    case NullableFieldType():
      return NullableFieldType(
        _resolveFieldTypeRef(type.inner, available, enums),
      );
    case ListFieldType():
      return ListFieldType(
        _resolveFieldTypeRef(type.element, available, enums),
      );
    default:
      return type;
  }
}

String? _resolveDefaultRef(String? defaultValue, Set<String> available) {
  if (defaultValue == null) return null;
  // Check if default references a non-available type like "const FooType()".
  if (defaultValue.startsWith('const ') && defaultValue.endsWith('()')) {
    final typeName = defaultValue.substring(6, defaultValue.length - 2);
    if (!available.contains(typeName)) {
      return null;
    }
  }
  return defaultValue;
}

/// Collects the Dart type names provided by a file config.
Set<String> typeNamesForFile(
  List<String> schemaNames,
  SchemaDefinition schema,
) {
  final names = <String>{};
  for (final name in schemaNames) {
    final typeDef = schema.types[name];
    if (typeDef == null) continue;
    names.add(typeDef.dartName);
    if (typeDef is SealedType) {
      for (final v in typeDef.variants) {
        names.add(v.dartName);
      }
      names.add('Unknown${typeDef.dartName}');
    }
  }
  return names;
}

/// Collects all enum type Dart names from a schema.
Set<String> enumTypeNames(SchemaDefinition schema) {
  return schema.types.values
      .whereType<EnumType>()
      .map((e) => e.dartName)
      .toSet();
}

/// Converts "snake_case" to "camelCase".
String _snakeToCamel(String s) {
  final parts = s.split('_');
  if (parts.isEmpty) return s;
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
          .join();
}

/// Converts "snake_case" to "PascalCase".
String _snakeToPascal(String s) {
  return s
      .split('_')
      .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
      .join();
}
