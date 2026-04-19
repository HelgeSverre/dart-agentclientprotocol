/// ACP schema code generator.
///
/// Reads the upstream JSON Schema files and generates Dart model classes
/// that match the patterns in `lib/src/schema/`.
///
/// Run with: `dart run tool/generate/generate.dart`
library;

import 'dart:io';

import 'src/dart_emitter.dart';
import 'src/json_schema_parser.dart';
import 'src/schema_model.dart';

/// Output directory for generated schema files.
const _outDir = 'lib/src/schema';

/// Upstream schema paths.
const _stableSchemaPath = 'tool/upstream/schema/schema.json';
const _unstableSchemaPath = 'tool/upstream/schema/schema.unstable.json';

// ---------------------------------------------------------------------------
// File grouping configuration
// ---------------------------------------------------------------------------

/// Maps output files to the schema types they contain, matching the existing
/// hand-written file structure.
List<FileConfig> _fileConfigs(
  SchemaDefinition stable,
  SchemaDefinition unstable,
) {
  return [
    FileConfig(fileName: 'annotations.dart', typeNames: ['Annotations']),
    FileConfig(fileName: 'auth_method.dart', typeNames: ['AuthMethodAgent']),
    FileConfig(
      fileName: 'capabilities.dart',
      typeNames: [
        'FileSystemCapabilities',
        'ClientCapabilities',
        'PromptCapabilities',
        'McpCapabilities',
        'SessionCapabilities',
        'AgentCapabilities',
      ],
    ),
    FileConfig(
      fileName: 'content_block.dart',
      typeNames: ['ContentBlock'],
      imports: ['annotations.dart'],
    ),
    FileConfig(
      fileName: 'content_chunk.dart',
      typeNames: ['ContentChunk'],
      imports: ['content_block.dart'],
    ),
    FileConfig(
      fileName: 'implementation_info.dart',
      typeNames: ['Implementation'],
    ),
    FileConfig(
      fileName: 'initialize.dart',
      typeNames: [
        'InitializeRequest',
        'InitializeResponse',
        'AuthenticateRequest',
        'AuthenticateResponse',
      ],
      imports: ['capabilities.dart', 'implementation_info.dart'],
    ),
    FileConfig(
      fileName: 'session.dart',
      typeNames: [
        'NewSessionRequest',
        'NewSessionResponse',
        'LoadSessionRequest',
        'LoadSessionResponse',
        'PromptRequest',
        'StopReason',
        'PromptResponse',
        'CancelNotification',
        'SetSessionModeRequest',
        'SetSessionModeResponse',
        'SetSessionConfigOptionRequest',
        'SetSessionConfigOptionResponse',
        'SessionNotification',
        'SessionInfo',
        'ListSessionsRequest',
        'ListSessionsResponse',
      ],
      imports: ['content_block.dart'],
    ),
    FileConfig(fileName: 'session_update.dart', typeNames: ['SessionUpdate']),
    FileConfig(
      fileName: 'client_methods.dart',
      typeNames: [
        'ReadTextFileRequest',
        'ReadTextFileResponse',
        'WriteTextFileRequest',
        'WriteTextFileResponse',
        'CreateTerminalRequest',
        'CreateTerminalResponse',
        'TerminalOutputRequest',
        'TerminalOutputResponse',
        'ReleaseTerminalRequest',
        'ReleaseTerminalResponse',
        'KillTerminalRequest',
        'KillTerminalResponse',
        'WaitForTerminalExitRequest',
        'WaitForTerminalExitResponse',
        'RequestPermissionRequest',
        'RequestPermissionResponse',
      ],
      sectionComments: [
        SectionComment(
          beforeType: 'ReadTextFileRequest',
          comment: '// -- File System --',
        ),
        SectionComment(
          beforeType: 'CreateTerminalRequest',
          comment: '// -- Terminal --',
        ),
        SectionComment(
          beforeType: 'RequestPermissionRequest',
          comment: '// -- Permission --',
        ),
      ],
    ),
    FileConfig(
      fileName: 'unstable_methods.dart',
      typeNames:
          unstable.types.keys
              .where((name) => !stable.types.containsKey(name))
              .toList(),
      experimental: true,
      sectionComments: [
        SectionComment(
          beforeType: 'ListProvidersRequest',
          comment: '// -- Providers (unstable) --',
        ),
        SectionComment(
          beforeType: 'LogoutRequest',
          comment: '// -- Auth (unstable) --',
        ),
        SectionComment(
          beforeType: 'ForkSessionRequest',
          comment: '// -- Sessions (unstable) --',
        ),
        SectionComment(
          beforeType: 'DidOpenDocumentNotification',
          comment: '// -- Documents (unstable) --',
        ),
        SectionComment(
          beforeType: 'StartNesRequest',
          comment: '// -- Next Edit Suggestions (unstable) --',
        ),
        SectionComment(
          beforeType: 'CreateElicitationRequest',
          comment: '// -- Elicitation (unstable) --',
        ),
      ],
    ),
  ];
}

void main() {
  stdout.writeln('Parsing stable schema...');
  final stable = parseSchemaFile(_stableSchemaPath);
  stdout.writeln('  Found ${stable.types.length} types');

  stdout.writeln('Parsing unstable schema...');
  final unstable = parseSchemaFile(_unstableSchemaPath);
  stdout.writeln('  Found ${unstable.types.length} types');

  // Merge: unstable types override stable ones.
  final merged = SchemaDefinition({...stable.types, ...unstable.types});
  stdout.writeln('  Merged: ${merged.types.length} types');

  final configs = _fileConfigs(stable, unstable);

  // Build a map: fileName → set of type Dart names it provides.
  final fileTypeNames = <String, Set<String>>{};
  for (final config in configs) {
    final source = config.experimental ? unstable : stable;
    fileTypeNames[config.fileName] = typeNamesForFile(config.typeNames, source);
  }

  // Collect enum type names from both schemas.
  final stableEnums = enumTypeNames(stable);
  final unstableEnums = enumTypeNames(unstable);

  final outDirectory = Directory(_outDir);
  if (!outDirectory.existsSync()) {
    outDirectory.createSync(recursive: true);
  }

  var filesWritten = 0;
  for (final config in configs) {
    final source = config.experimental ? unstable : stable;
    final schemaPath =
        config.experimental ? _unstableSchemaPath : _stableSchemaPath;
    final enums = config.experimental ? unstableEnums : stableEnums;

    // Build the set of types available in this file:
    // own types + types from imported files.
    final availableTypes = <String>{...fileTypeNames[config.fileName] ?? {}};
    for (final imp in config.imports) {
      availableTypes.addAll(fileTypeNames[imp] ?? {});
    }

    // Resolve refs per file: replace unavailable refs with Map<String, dynamic>.
    final resolvedSchema = SchemaDefinition({
      for (final entry in source.types.entries)
        entry.key: resolveRefsForFile(entry.value, availableTypes, enums),
    });

    // Verify all types exist.
    final missingTypes = <String>[];
    for (final name in config.typeNames) {
      if (!resolvedSchema.types.containsKey(name)) {
        missingTypes.add(name);
      }
    }
    if (missingTypes.isNotEmpty) {
      stderr.writeln(
        'WARNING: ${config.fileName}: missing types: $missingTypes',
      );
    }

    final output = emitFile(
      config: config,
      schema: resolvedSchema,
      schemaSourcePath: schemaPath,
    );

    final outFile = File('$_outDir/${config.fileName}');
    outFile.writeAsStringSync(output);
    stdout.writeln('  Wrote ${config.fileName}');
    filesWritten++;
  }

  stdout.writeln('Done. Generated $filesWritten files in $_outDir/');
  stdout.writeln();
  stdout.writeln('Next steps:');
  stdout.writeln('  dart analyze');
  stdout.writeln('  dart test');
  stdout.writeln('  git diff lib/src/schema/');
}
