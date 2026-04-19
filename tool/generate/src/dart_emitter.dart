/// Renders Dart source code from [SchemaDefinition] types.
library;

import 'schema_model.dart';

/// Configuration for a single output file.
class FileConfig {
  /// Output file name (e.g. "annotations.dart").
  final String fileName;

  /// Schema type names to include in this file.
  final List<String> typeNames;

  /// Imports needed by this file (other schema files).
  final List<String> imports;

  /// Whether types in this file should be annotated @experimental.
  final bool experimental;

  /// Custom preamble comments (e.g. "// -- File System --").
  final List<SectionComment> sectionComments;

  FileConfig({
    required this.fileName,
    required this.typeNames,
    this.imports = const [],
    this.experimental = false,
    this.sectionComments = const [],
  });
}

/// A section comment inserted before a specific type.
class SectionComment {
  final String beforeType;
  final String comment;

  SectionComment({required this.beforeType, required this.comment});
}

/// Emits a complete Dart file for the given types.
String emitFile({
  required FileConfig config,
  required SchemaDefinition schema,
  required String schemaSourcePath,
}) {
  final buf = StringBuffer();

  // Generated header.
  buf.writeln('// GENERATED CODE — DO NOT EDIT.');
  buf.writeln('//');
  buf.writeln('// Source: $schemaSourcePath');
  buf.writeln('// Run `dart run tool/generate/generate.dart` to regenerate.');
  buf.writeln();

  // Imports — sorted alphabetically per Dart convention.
  final imports = <String>[];
  for (final imp in config.imports) {
    imports.add("import 'package:acp/src/schema/$imp';");
  }
  imports.add("import 'package:acp/src/schema/has_meta.dart';");
  if (config.experimental) {
    imports.add("import 'package:meta/meta.dart';");
  }
  imports.sort();
  for (final imp in imports) {
    buf.writeln(imp);
  }
  buf.writeln();

  // Emit each type.
  for (var i = 0; i < config.typeNames.length; i++) {
    final name = config.typeNames[i];
    final typeDef = schema.types[name];
    if (typeDef == null) continue;

    // Section comments.
    for (final sc in config.sectionComments) {
      if (sc.beforeType == name) {
        if (i > 0) buf.writeln();
        buf.writeln(sc.comment);
      }
    }

    if (i > 0) buf.writeln();

    // Doc comment first, then `@experimental`, then the declaration.
    // `dart doc` only attaches a `///` comment to the immediately following
    // declaration — putting the annotation in between drops the doc.
    final desc = switch (typeDef) {
      StructType() => typeDef.description,
      SealedType() => typeDef.description,
      EnumType() => typeDef.description,
    };
    if (desc != null) {
      _emitDocComment(buf, desc, '');
    }
    if (config.experimental) {
      buf.writeln('@experimental');
    }

    switch (typeDef) {
      case StructType():
        _emitStruct(buf, typeDef, emitDoc: false);
      case SealedType():
        _emitSealed(buf, typeDef, config.experimental, emitDoc: false);
      case EnumType():
        _emitEnum(buf, typeDef, emitDoc: false);
    }
  }

  return buf.toString();
}

// ---------------------------------------------------------------------------
// Struct emission
// ---------------------------------------------------------------------------

void _emitStruct(StringBuffer buf, StructType type, {bool emitDoc = true}) {
  // Doc comment (skipped when caller already emitted it before annotations).
  if (emitDoc && type.description != null) {
    _emitDocComment(buf, type.description!, '');
  }

  final implementsClause = type.hasMeta ? ' implements HasMeta' : '';
  buf.writeln('final class ${type.dartName}$implementsClause {');

  // Field declarations.
  for (final field in type.fields) {
    if (field.jsonKey == '_meta') continue; // Handled as HasMeta.
    _emitFieldDoc(buf, field);
    buf.writeln('  final ${_fieldDartType(field)} ${field.dartName};');
    buf.writeln();
  }

  // Meta field.
  if (type.hasMeta) {
    buf.writeln('  @override');
    buf.writeln('  final Map<String, Object?>? meta;');
    buf.writeln();
  }

  // Extension data.
  buf.writeln('  /// Unknown fields preserved for round-trip fidelity.');
  buf.writeln('  final Map<String, Object?>? extensionData;');
  buf.writeln();

  // Constructor.
  _emitDocComment(
    buf,
    'Creates ${_article(type.dartName)} [${type.dartName}].',
    '  ',
  );
  buf.write('  const ${type.dartName}({');
  final ctorParams = <String>[];
  for (final field in type.fields) {
    final param = _ctorParam(field);
    ctorParams.add(param);
  }
  if (type.hasMeta) ctorParams.add('this.meta');
  ctorParams.add('this.extensionData');
  buf.writeln();
  for (final p in ctorParams) {
    buf.writeln('    $p,');
  }
  buf.writeln('  });');
  buf.writeln();

  // fromJson factory.
  _emitDocComment(buf, 'Deserializes from JSON.', '  ');
  buf.writeln(
    '  factory ${type.dartName}.fromJson(Map<String, dynamic> json) {',
  );
  _emitKnownFieldsSet(buf, type.fields, type.hasMeta);
  _emitExtensionDataExtraction(buf);
  buf.writeln('    return ${type.dartName}(');
  for (final field in type.fields) {
    buf.writeln('      ${field.dartName}: ${_fromJsonExpr(field)},');
  }
  if (type.hasMeta) {
    buf.writeln("      meta: json['_meta'] as Map<String, Object?>?,");
  }
  buf.writeln('      extensionData: ext.isEmpty ? null : ext,');
  buf.writeln('    );');
  buf.writeln('  }');
  buf.writeln();

  // toJson method.
  _emitDocComment(buf, 'Serializes to JSON.', '  ');
  buf.writeln('  Map<String, dynamic> toJson() => {');
  for (final field in type.fields) {
    _emitToJsonField(buf, field);
  }
  if (type.hasMeta) {
    buf.writeln("    if (meta != null) '_meta': meta,");
  }
  buf.writeln('    if (extensionData != null) ...extensionData!,');
  buf.writeln('  };');
  buf.writeln('}');
}

// ---------------------------------------------------------------------------
// Sealed type emission
// ---------------------------------------------------------------------------

void _emitSealed(
  StringBuffer buf,
  SealedType type,
  bool experimental, {
  bool emitDoc = true,
}) {
  if (emitDoc && type.description != null) {
    _emitDocComment(buf, type.description!, '');
  }

  buf.writeln('sealed class ${type.dartName} implements HasMeta {');
  buf.writeln('  const ${type.dartName}();');
  buf.writeln();

  // fromJson factory with switch.
  _emitDocComment(
    buf,
    'Deserializes a [${type.dartName}] from JSON.\n\n'
        "Switches on the `${type.discriminatorField}` discriminator field.",
    '  ',
  );
  buf.writeln(
    '  factory ${type.dartName}.fromJson(Map<String, dynamic> json) {',
  );
  buf.writeln(
    "    final ${_discriminatorVarName(type.discriminatorField)}"
    " = json['${type.discriminatorField}'] as String?;",
  );

  // Handle null discriminator.
  buf.writeln(
    '    if (${_discriminatorVarName(type.discriminatorField)} == null) {',
  );
  buf.writeln('      return Unknown${type.dartName}(rawJson: json);');
  buf.writeln('    }');

  buf.writeln(
    '    return switch (${_discriminatorVarName(type.discriminatorField)}) {',
  );
  for (final variant in type.variants) {
    buf.writeln(
      "      '${variant.discriminatorValue}'"
      ' => ${variant.dartName}.fromJson(json),',
    );
  }
  buf.writeln('      _ => Unknown${type.dartName}(');
  buf.writeln(
    '        ${_unknownDiscFieldName(type.discriminatorField)}: '
    '${_discriminatorVarName(type.discriminatorField)},',
  );
  buf.writeln('        rawJson: json,');
  buf.writeln("        meta: json['_meta'] as Map<String, Object?>?,");
  buf.writeln('      ),');
  buf.writeln('    };');
  buf.writeln('  }');
  buf.writeln();

  // Abstract toJson.
  _emitDocComment(
    buf,
    'Serializes this ${_lowerFirst(type.dartName)} to JSON.',
    '  ',
  );
  buf.writeln('  Map<String, dynamic> toJson();');
  buf.writeln('}');

  // Emit variant classes. Doc comment first, then @experimental, then class.
  for (final variant in type.variants) {
    buf.writeln();
    if (variant.description != null) {
      _emitDocComment(buf, variant.description!, '');
    }
    if (experimental) buf.writeln('@experimental');
    _emitSealedVariant(buf, type, variant, emitDoc: false);
  }

  // Emit Unknown fallback.
  buf.writeln();
  if (experimental) buf.writeln('@experimental');
  _emitUnknownVariant(buf, type);
}

void _emitSealedVariant(
  StringBuffer buf,
  SealedType parent,
  SealedVariant variant, {
  bool emitDoc = true,
}) {
  if (emitDoc && variant.description != null) {
    _emitDocComment(buf, variant.description!, '');
  }

  buf.writeln('final class ${variant.dartName} extends ${parent.dartName} {');

  if (variant.fields.isEmpty && !variant.hasMeta) {
    // Simple variant with just rawJson.
    buf.writeln('  /// The raw JSON payload.');
    buf.writeln('  final Map<String, dynamic> rawJson;');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  final Map<String, Object?>? meta;');
    buf.writeln();
    _emitDocComment(
      buf,
      'Creates ${_article(variant.dartName)} [${variant.dartName}].',
      '  ',
    );
    buf.writeln(
      '  const ${variant.dartName}({required this.rawJson, this.meta});',
    );
    buf.writeln();
    _emitDocComment(buf, 'Deserializes from JSON.', '  ');
    buf.writeln(
      '  factory ${variant.dartName}.fromJson(Map<String, dynamic> json) {',
    );
    buf.writeln('    return ${variant.dartName}(');
    buf.writeln('      rawJson: json,');
    buf.writeln("      meta: json['_meta'] as Map<String, Object?>?,");
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  Map<String, dynamic> toJson() => rawJson;');
  } else {
    // Typed variant with fields.
    for (final field in variant.fields) {
      _emitFieldDoc(buf, field);
      buf.writeln('  final ${_fieldDartType(field)} ${field.dartName};');
      buf.writeln();
    }

    buf.writeln('  @override');
    buf.writeln('  final Map<String, Object?>? meta;');
    buf.writeln();

    // Extension data for typed variants.
    buf.writeln('  /// Unknown fields preserved for round-trip fidelity.');
    buf.writeln('  final Map<String, Object?>? extensionData;');
    buf.writeln();

    _emitDocComment(
      buf,
      'Creates ${_article(variant.dartName)} [${variant.dartName}].',
      '  ',
    );
    buf.write('  const ${variant.dartName}({');
    final ctorParams = <String>[];
    for (final field in variant.fields) {
      ctorParams.add(_ctorParam(field));
    }
    ctorParams.add('this.meta');
    ctorParams.add('this.extensionData');
    buf.writeln();
    for (final p in ctorParams) {
      buf.writeln('    $p,');
    }
    buf.writeln('  });');
    buf.writeln();

    // fromJson.
    _emitDocComment(buf, 'Deserializes from JSON.', '  ');
    buf.writeln(
      '  factory ${variant.dartName}.fromJson(Map<String, dynamic> json) {',
    );
    _emitKnownFieldsSet(
      buf,
      variant.fields,
      true,
      extraKeys: {parent.discriminatorField},
    );
    _emitExtensionDataExtraction(buf);
    buf.writeln('    return ${variant.dartName}(');
    for (final field in variant.fields) {
      buf.writeln('      ${field.dartName}: ${_fromJsonExpr(field)},');
    }
    buf.writeln("      meta: json['_meta'] as Map<String, Object?>?,");
    buf.writeln('      extensionData: ext.isEmpty ? null : ext,');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();

    // toJson.
    buf.writeln('  @override');
    buf.writeln('  Map<String, dynamic> toJson() => {');
    buf.writeln(
      "    '${parent.discriminatorField}': '${variant.discriminatorValue}',",
    );
    for (final field in variant.fields) {
      _emitToJsonField(buf, field);
    }
    buf.writeln("    if (meta != null) '_meta': meta,");
    buf.writeln('    if (extensionData != null) ...extensionData!,');
    buf.writeln('  };');
  }
  buf.writeln('}');
}

void _emitUnknownVariant(StringBuffer buf, SealedType type) {
  final discFieldName = _unknownDiscFieldName(type.discriminatorField);

  _emitDocComment(
    buf,
    'A ${_lowerFirst(type.dartName)} with an unknown ${type.discriminatorField}, preserved for forward compatibility.',
    '',
  );
  buf.writeln('final class Unknown${type.dartName} extends ${type.dartName} {');
  buf.writeln('  /// The unknown discriminator value.');
  buf.writeln('  final String? $discFieldName;');
  buf.writeln();
  buf.writeln('  /// The raw JSON object, preserved as-is.');
  buf.writeln('  final Map<String, dynamic> rawJson;');
  buf.writeln();
  buf.writeln('  @override');
  buf.writeln('  final Map<String, Object?>? meta;');
  buf.writeln();
  _emitDocComment(buf, 'Creates an [Unknown${type.dartName}].', '  ');
  buf.writeln('  const Unknown${type.dartName}({');
  buf.writeln('    this.$discFieldName,');
  buf.writeln('    required this.rawJson,');
  buf.writeln('    this.meta,');
  buf.writeln('  });');
  buf.writeln();
  buf.writeln('  @override');
  buf.writeln('  Map<String, dynamic> toJson() => rawJson;');
  buf.writeln('}');
}

// ---------------------------------------------------------------------------
// Enum emission
// ---------------------------------------------------------------------------

void _emitEnum(StringBuffer buf, EnumType type, {bool emitDoc = true}) {
  if (emitDoc && type.description != null) {
    _emitDocComment(buf, type.description!, '');
  }

  buf.writeln('enum ${type.dartName} {');
  for (var i = 0; i < type.values.length; i++) {
    final v = type.values[i];
    if (v.description != null) {
      _emitDocComment(buf, v.description!, '  ');
    }
    final sep = i < type.values.length - 1 ? ',' : ';';
    buf.writeln("  ${v.dartName}('${v.wireValue}')$sep");
    if (i < type.values.length - 1) buf.writeln();
  }
  buf.writeln();
  buf.writeln('  /// The wire-format string value.');
  buf.writeln('  final String value;');
  buf.writeln();
  buf.writeln('  const ${type.dartName}(this.value);');
  buf.writeln();
  _emitDocComment(
    buf,
    'Parses a [${type.dartName}] from its wire-format string.\n\n'
        'Returns `null` for unknown values.',
    '  ',
  );
  buf.writeln('  static ${type.dartName}? fromString(String value) {');
  buf.writeln('    for (final v in values) {');
  buf.writeln('      if (v.value == value) return v;');
  buf.writeln('    }');
  buf.writeln('    return null;');
  buf.writeln('  }');
  buf.writeln('}');
}

// ---------------------------------------------------------------------------
// Helper methods
// ---------------------------------------------------------------------------

String _fieldDartType(FieldDef field) {
  final type = field.type;
  // If not required and no default, make nullable.
  if (!field.isRequired && field.defaultValue == null && !type.isNullable) {
    return '${type.dartType}?';
  }
  return type.dartType;
}

String _ctorParam(FieldDef field) {
  if (field.isRequired && field.defaultValue == null) {
    return 'required this.${field.dartName}';
  }
  if (field.defaultValue != null) {
    return 'this.${field.dartName} = ${field.defaultValue}';
  }
  return 'this.${field.dartName}';
}

void _emitKnownFieldsSet(
  StringBuffer buf,
  List<FieldDef> fields,
  bool hasMeta, {
  Set<String>? extraKeys,
}) {
  final keys = <String>{};
  for (final f in fields) {
    keys.add(f.jsonKey);
  }
  if (hasMeta) keys.add('_meta');
  if (extraKeys != null) keys.addAll(extraKeys);

  if (keys.isEmpty) {
    buf.writeln("    final known = <String>{'_meta'};");
  } else {
    final keyLiterals = keys.map((k) => "'$k'").join(', ');
    buf.writeln('    final known = {$keyLiterals};');
  }
}

void _emitExtensionDataExtraction(StringBuffer buf) {
  buf.writeln('    final ext = Map<String, Object?>.fromEntries(');
  buf.writeln('      json.entries.where((e) => !known.contains(e.key)),');
  buf.writeln('    );');
}

String _fromJsonExpr(FieldDef field) {
  final type = field.type;
  final key = "'${field.jsonKey}'";

  return _fromJsonForType(type, 'json[$key]', field);
}

String _fromJsonForType(FieldType type, String accessor, FieldDef field) {
  // A required-but-nullable field (anyOf [..., null] in a `required` list)
  // must be deserialised as nullable too — independent of `field.isRequired`.
  final isExplicitlyNullable = type is NullableFieldType;
  final inner = type is NullableFieldType ? type.inner : type;
  // The field's deserialised value is nullable when either the schema
  // marks it nullable, or the field is optional with no default.
  final isNullable =
      isExplicitlyNullable || (!field.isRequired && field.defaultValue == null);

  switch (inner) {
    case StringFieldType():
      return isNullable ? '$accessor as String?' : '$accessor as String';
    case IntFieldType():
      if (isNullable) return '$accessor as int?';
      if (field.defaultValue != null) {
        return '$accessor as int? ?? ${field.defaultValue}';
      }
      return '$accessor as int';
    case BoolFieldType():
      if (field.defaultValue != null) {
        return '$accessor as bool? ?? ${field.defaultValue}';
      }
      return isNullable ? '$accessor as bool?' : '$accessor as bool';
    case DoubleFieldType():
      if (isNullable) return '($accessor as num?)?.toDouble()';
      if (field.defaultValue != null) {
        return '($accessor as num?)?.toDouble() ?? ${field.defaultValue}';
      }
      return '($accessor as num).toDouble()';
    case ListFieldType():
      return _fromJsonList(inner, accessor, field);
    case MapFieldType():
      return isNullable
          ? '$accessor as Map<String, dynamic>?'
          : '$accessor as Map<String, dynamic>';
    case RefFieldType():
      return _fromJsonRef(inner, accessor, field);
    case EnumFieldType():
      // Enums are always nullable: an unknown wire value (peer on a newer
      // protocol version) decodes as `null` rather than throwing.
      return '$accessor == null'
          ' ? null'
          ' : ${inner.dartClassName}.fromString($accessor as String)';
    case NullableFieldType():
      // Already unwrapped above; unreachable.
      return _fromJsonForType(inner.inner, accessor, field);
    case DynamicFieldType():
      return accessor;
  }
}

String _fromJsonList(ListFieldType type, String accessor, FieldDef field) {
  final elem = type.element;
  final isOptional = !field.isRequired && field.defaultValue == null;

  if (elem is StringFieldType) {
    if (isOptional) return '($accessor as List<dynamic>?)?.cast<String>()';
    if (field.defaultValue == 'const []') {
      return "($accessor as List<dynamic>?)?.cast<String>() ?? const []";
    }
    return '($accessor as List<dynamic>).cast<String>()';
  }

  if (elem is MapFieldType) {
    if (isOptional) {
      return '($accessor as List<dynamic>?)?.cast<Map<String, dynamic>>()';
    }
    if (field.defaultValue == 'const []') {
      return "($accessor as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const []";
    }
    return '($accessor as List<dynamic>).cast<Map<String, dynamic>>()';
  }

  if (elem is RefFieldType) {
    final fromJson =
        '(e) => ${elem.dartClassName}.fromJson(e as Map<String, dynamic>)';
    if (isOptional) {
      return '($accessor as List<dynamic>?)?.map($fromJson).toList()';
    }
    if (field.defaultValue == 'const []') {
      return '($accessor as List<dynamic>?)?.map($fromJson).toList() ?? const []';
    }
    return '($accessor as List<dynamic>).map($fromJson).toList()';
  }

  if (elem is EnumFieldType) {
    // Element type is `EnumName?` so unknown values decode as null entries.
    final parse = '(e) => ${elem.dartClassName}.fromString(e as String)';
    if (isOptional) {
      return '($accessor as List<dynamic>?)?.map($parse).toList()';
    }
    if (field.defaultValue == 'const []') {
      return '($accessor as List<dynamic>?)?.map($parse).toList() ?? const []';
    }
    return '($accessor as List<dynamic>).map($parse).toList()';
  }

  // Fallback.
  if (isOptional) return '($accessor as List<dynamic>?)';
  return '($accessor as List<dynamic>)';
}

String _fromJsonRef(RefFieldType type, String accessor, FieldDef field) {
  final className = type.dartClassName;
  final isOptional = !field.isRequired && field.defaultValue == null;

  if (isOptional) {
    return '$accessor is Map<String, dynamic>\n'
        '            ? $className.fromJson(\n'
        '              $accessor as Map<String, dynamic>,\n'
        '            )\n'
        '            : null';
  }
  if (field.defaultValue != null &&
      field.defaultValue!.startsWith('const $className')) {
    return '$accessor is Map<String, dynamic>\n'
        '            ? $className.fromJson(\n'
        '              $accessor as Map<String, dynamic>,\n'
        '            )\n'
        '            : ${field.defaultValue}';
  }
  return '$className.fromJson($accessor as Map<String, dynamic>)';
}

void _emitToJsonField(StringBuffer buf, FieldDef field) {
  final key = "'${field.jsonKey}'";
  final type = field.type;
  final isOptional = !field.isRequired && field.defaultValue == null;

  final valueExpr = _toJsonExpr(field);

  if (isOptional || type.isNullable) {
    buf.writeln('    if (${field.dartName} != null) $key: $valueExpr,');
  } else {
    buf.writeln('    $key: $valueExpr,');
  }
}

String _toJsonExpr(FieldDef field) {
  final type =
      field.type is NullableFieldType
          ? (field.type as NullableFieldType).inner
          : field.type;
  final isOptional =
      !field.isRequired && field.defaultValue == null || field.type.isNullable;

  switch (type) {
    case RefFieldType():
      if (isOptional) {
        return '${field.dartName}!.toJson()';
      }
      return '${field.dartName}.toJson()';
    case EnumFieldType():
      // Enum fields are always nullable; extract the wire value with `?.value`.
      // The enclosing `if (field != null)` guard on emit means `!.value` is
      // safe — we only get here when the field is non-null.
      return '${field.dartName}!.value';
    case ListFieldType():
      if (type.element is RefFieldType) {
        // For nullable/optional list fields, Dart can't promote public fields,
        // so we need the ! operator after the if-null guard.
        final accessor = isOptional ? '${field.dartName}!' : field.dartName;
        return '$accessor.map((e) => e.toJson()).toList()';
      }
      if (type.element is EnumFieldType) {
        final accessor = isOptional ? '${field.dartName}!' : field.dartName;
        return '$accessor.map((e) => e.value).toList()';
      }
      return field.dartName;
    default:
      return field.dartName;
  }
}

/// Emits a doc comment for a field, using description if available or
/// a fallback derived from the field name.
void _emitFieldDoc(StringBuffer buf, FieldDef field) {
  if (field.description != null) {
    _emitDocComment(buf, field.description!, '  ');
  } else {
    // Generate a minimal doc comment from the field name to satisfy
    // public_member_api_docs.
    final readable = _dartNameToReadable(field.dartName);
    _emitDocComment(buf, 'The $readable.', '  ');
  }
}

/// Converts a camelCase Dart name to a readable phrase.
///
/// Example: `sessionCapabilities` → `session capabilities`.
String _dartNameToReadable(String name) {
  final buf = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final c = name[i];
    if (c == c.toUpperCase() && c != c.toLowerCase() && i > 0) {
      buf.write(' ');
      buf.write(c.toLowerCase());
    } else {
      buf.write(c);
    }
  }
  return buf.toString();
}

void _emitDocComment(StringBuffer buf, String text, String indent) {
  final lines = text.split('\n');
  for (final line in lines) {
    if (line.isEmpty) {
      buf.writeln('$indent///');
    } else {
      buf.writeln('$indent/// $line');
    }
  }
}

String _article(String name) {
  final vowels = {'A', 'E', 'I', 'O', 'U'};
  return vowels.contains(name[0]) ? 'an' : 'a';
}

String _lowerFirst(String s) {
  if (s.isEmpty) return s;
  return s[0].toLowerCase() + s.substring(1);
}

String _discriminatorVarName(String field) {
  // "type" → "type", "sessionUpdate" → "updateType", "outcome" → "outcome"
  if (field == 'type') return 'type';
  if (field == 'sessionUpdate') return 'updateType';
  return field;
}

String _unknownDiscFieldName(String field) {
  // For "type" → "type" (matches hand-written UnknownContentBlock.type).
  // For everything else → "${field}Type" (matches UnknownSessionUpdate.sessionUpdateType).
  if (field == 'type') return 'type';
  return '${field}Type';
}
